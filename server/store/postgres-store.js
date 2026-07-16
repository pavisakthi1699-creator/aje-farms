import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import pg from 'pg';

import {
  approvedCoursesFromCatalog,
  createId,
  documentsFromCourses,
  hashOtp,
  hasApprovedLessonInCourses,
  isLearnerReadyCourse,
  normalizeApprovedCourse,
  normalizeContentDocument,
  normalizePhoneNumber,
  otpTtlMs,
  paymentFromRow,
  userFromRow,
  verifyOtpHash,
} from './utils.js';
import {
  createSessionToken,
  isSessionExpired,
  sessionExpiresAt,
} from './session-utils.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const groundingStopWords = new Set([
  'gani',
  'hii',
  'hilo',
  'hizi',
  'huko',
  'je',
  'kwa',
  'kwamba',
  'kwenye',
  'mimi',
  'nini',
  'nitumie',
  'sana',
  'wangu',
  'yangu',
  'yake',
  'yako',
]);

function requestsHighRiskDecision(message) {
  const normalized = String(message ?? '').toLowerCase();
  const asksForTreatment =
    /\b(dawa|dozi|kipimo|kutibu|matibabu|tiba|utambuzi)\b/u.test(normalized);
  const asksForVaccinationSchedule =
    /\bchanjo\b/u.test(normalized) &&
    /\b(chanja|lini|muda|nipe|ratiba|siku|umri|wiki|mwezi)\b/u.test(
      normalized,
    );
  const asksForInputRecommendation =
    /\b(mbolea|kiuatilifu|viuatilifu)\b/u.test(normalized) &&
    /\b(gani|kiasi|kipimo|dozi|lini|muda|nipe|nitumie|ratiba|tumia|weka)\b/u.test(
      normalized,
    );
  return asksForTreatment || asksForVaccinationSchedule || asksForInputRecommendation;
}

export class PostgresStore {
  constructor({ pool, catalog, schema }) {
    this.pool = pool;
    this.catalog = catalog;
    this.schema = schema;
  }

  static async create(databaseUrl, catalog, { schema = 'public' } = {}) {
    const normalizedSchema = normalizeSchemaIdentifier(schema);
    const pool = new pg.Pool({
      connectionString: databaseUrl,
      max: 10,
      options: `-c search_path=${normalizedSchema},public`,
    });
    const store = new PostgresStore({
      pool,
      catalog,
      schema: normalizedSchema,
    });
    await store.#ensureSchema();
    await store.#migrate();
    await store.#seedContentCatalog();
    await store.#seedCommunityCatalog();
    return store;
  }

  async close() {
    await this.pool.end();
  }

  async catalogSnapshot() {
    return {
      courses: await this.approvedContentCourses(),
      documents: await this.approvedContentDocuments(),
      problemCategories: this.catalog.problemCategories,
      plans: this.catalog.plans,
      communityPosts: await this.communityPosts(),
    };
  }

  async approvedContentCourses() {
    if (process.env.AJE_STORE === 'supabase') {
      return this.#publishedStructuredCourses();
    }
    const result = await this.pool.query(
      `SELECT id, status, payload, updated_at
       FROM content_courses
       WHERE status = 'approved'
       ORDER BY id ASC`,
    );
    return result.rows
      .filter((row) => isLearnerReadyCourse(row.payload))
      .map((row) => normalizeApprovedCourse(row.payload));
  }

  async #publishedStructuredCourses() {
    const result = await this.pool.query(
      `SELECT
         c.id::text AS course_id,
         c.code AS course_code,
         c.title_sw AS course_title,
         COALESCE(c.description_sw, c.summary_sw, '') AS course_description,
         COALESCE(c.delivery_type, 'text') AS delivery_type,
         m.id::text AS module_id,
         m.title_sw AS module_title,
         m.sort_order AS module_order,
         l.id::text AS lesson_id,
         l.title_sw AS lesson_title,
         l.body_sw AS lesson_body,
         l.lesson_type,
         l.duration_minutes,
         l.sort_order AS lesson_order,
         (
           SELECT sd.title
           FROM content_source_links csl
           JOIN source_segments ss ON ss.id = csl.source_segment_id
           JOIN source_documents sd ON sd.id = ss.source_document_id
           WHERE csl.content_type = 'lesson'
             AND csl.content_id = l.id
             AND csl.link_status = 'linked'
             AND ss.review_status IN ('approved', 'published')
             AND sd.processing_status IN ('approved', 'published')
           ORDER BY csl.created_at
           LIMIT 1
         ) AS source_title,
         (
           SELECT lr.external_url
           FROM lesson_resources lr
           WHERE lr.lesson_id = l.id
             AND lr.resource_type = 'video'
             AND lr.status = 'published'
           ORDER BY lr.created_at
           LIMIT 1
         ) AS video_url,
         (
           SELECT lr.storage_path
           FROM lesson_resources lr
           WHERE lr.lesson_id = l.id
             AND lr.resource_type = 'video'
             AND lr.status = 'published'
           ORDER BY lr.created_at
           LIMIT 1
         ) AS video_storage_path
       FROM courses c
       JOIN course_modules m ON m.course_id = c.id
       JOIN lessons l ON l.module_id = m.id
       WHERE c.status = 'published'
         AND m.status = 'published'
         AND l.status = 'published'
         AND c.source_link_status = 'linked'
         AND m.source_link_status = 'linked'
         AND l.source_link_status = 'linked'
         AND l.lesson_type IN ('reading', 'video')
         AND (
           (COALESCE(c.delivery_type, 'text') = 'text'
             AND l.lesson_type = 'reading'
             AND NULLIF(BTRIM(l.body_sw), '') IS NOT NULL)
           OR
           (c.delivery_type = 'video'
             AND l.lesson_type = 'video'
             AND EXISTS (
               SELECT 1
               FROM lesson_resources lr
               WHERE lr.lesson_id = l.id
                 AND lr.resource_type = 'video'
                 AND lr.status = 'published'
                 AND (lr.external_url IS NOT NULL OR lr.storage_path IS NOT NULL)
             ))
         )
         AND EXISTS (
           SELECT 1
           FROM content_source_links csl
           JOIN source_segments ss ON ss.id = csl.source_segment_id
           JOIN source_documents sd ON sd.id = ss.source_document_id
           WHERE csl.content_type = 'lesson'
             AND csl.content_id = l.id
             AND csl.link_status = 'linked'
             AND ss.review_status IN ('approved', 'published')
             AND sd.processing_status IN ('approved', 'published')
         )
         AND EXISTS (
           SELECT 1
           FROM grounding_facts gf
           JOIN source_segments ss ON ss.id = gf.source_segment_id
           JOIN source_documents sd ON sd.id = ss.source_document_id
           WHERE (gf.lesson_id = l.id OR (gf.lesson_id IS NULL AND gf.course_id = c.id))
             AND gf.status = 'published'
             AND gf.risk_level <> 'high'
             AND ss.review_status IN ('approved', 'published')
             AND sd.processing_status IN ('approved', 'published')
         )
       ORDER BY c.sort_order, c.code, m.sort_order, l.sort_order`,
    );

    const courses = new Map();
    for (const row of result.rows) {
      let course = courses.get(row.course_id);
      if (!course) {
        course = {
          id: row.course_code,
          title: row.course_title,
          description: row.course_description,
          badge:
            row.delivery_type === 'video'
              ? 'Kozi ya video'
              : 'Kozi ya maandishi',
          icon: row.delivery_type === 'video' ? 'play_circle' : 'menu_book',
          progress: 0,
          imageUrl: courseImageForCode(row.course_code),
          outcomes: [],
          lessons: [],
        };
        courses.set(row.course_id, course);
      }
      if (
        row.module_title &&
        !course.outcomes.includes(row.module_title)
      ) {
        course.outcomes.push(row.module_title);
      }
      course.lessons.push({
        id: row.lesson_id,
        title: row.lesson_title,
        type: row.lesson_type === 'video' ? 'video' : 'reading',
        meta: row.duration_minutes
          ? `Dakika ${row.duration_minutes}`
          : row.lesson_type === 'video'
            ? 'Video'
            : 'Somo',
        description: row.lesson_body ?? '',
        sourceTitle: row.source_title ?? null,
        resourceUrl:
          row.video_url ??
          (row.video_storage_path
            ? `/api/lessons/${row.lesson_id}/video`
            : null),
        resourcePath: row.video_storage_path ?? null,
        isPremium: false,
        isCompleted: false,
      });
    }
    return [...courses.values()].map(normalizeApprovedCourse);
  }

  async lessonVideoUrl(lessonId) {
    if (process.env.AJE_STORE !== 'supabase') return null;
    const result = await this.pool.query(
      `SELECT lr.external_url, lr.storage_path
       FROM lesson_resources lr
       JOIN lessons l ON l.id = lr.lesson_id
       JOIN course_modules m ON m.id = l.module_id
       JOIN courses c ON c.id = m.course_id
       WHERE l.id = $1
         AND lr.resource_type = 'video'
         AND lr.status = 'published'
         AND l.status = 'published'
         AND m.status = 'published'
         AND c.status = 'published'
         AND c.source_link_status = 'linked'
         AND m.source_link_status = 'linked'
         AND l.source_link_status = 'linked'
         AND EXISTS (
           SELECT 1
           FROM content_source_links csl
           JOIN source_segments ss ON ss.id = csl.source_segment_id
           JOIN source_documents sd ON sd.id = ss.source_document_id
           WHERE csl.content_type = 'lesson'
             AND csl.content_id = l.id
             AND csl.link_status = 'linked'
             AND ss.review_status IN ('approved', 'published')
             AND sd.processing_status IN ('approved', 'published')
         )
         AND EXISTS (
           SELECT 1
           FROM grounding_facts gf
           JOIN source_segments ss ON ss.id = gf.source_segment_id
           JOIN source_documents sd ON sd.id = ss.source_document_id
           WHERE (gf.lesson_id = l.id OR (gf.lesson_id IS NULL AND gf.course_id = c.id))
             AND gf.status = 'published'
             AND gf.risk_level <> 'high'
             AND ss.review_status IN ('approved', 'published')
             AND sd.processing_status IN ('approved', 'published')
         )
       ORDER BY lr.created_at
       LIMIT 1`,
      [lessonId],
    );
    const resource = result.rows[0];
    if (!resource) return null;
    if (resource.external_url) return safePublicHttpUrl(resource.external_url);
    if (!resource.storage_path) return null;

    const supabaseUrl = process.env.SUPABASE_URL;
    const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
    if (!supabaseUrl || !serviceRoleKey) return null;
    const response = await fetch(
      `${supabaseUrl}/storage/v1/object/sign/source-documents/${encodeStoragePath(resource.storage_path)}`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${serviceRoleKey}`,
          apikey: serviceRoleKey,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ expiresIn: 900 }),
      },
    );
    if (!response.ok) return null;
    const payload = await response.json();
    const signedPath = payload.signedURL ?? payload.signedUrl;
    return signedPath ? resolveSupabaseSignedUrl(supabaseUrl, signedPath) : null;
  }

  async groundingSources(message) {
    if (process.env.AJE_STORE !== 'supabase') return null;
    if (requestsHighRiskDecision(message)) return [];
    const result = await this.pool.query(
      `SELECT
         gf.id::text,
         c.code AS course_id,
         c.title_sw AS course_title,
         gf.lesson_id::text,
         COALESCE(l.title_sw, c.title_sw) AS title,
         gf.fact_sw AS excerpt,
         gf.question_sw,
         sd.title AS source_title,
         ss.page_start,
         ss.page_end,
         ss.time_start_seconds,
         ss.time_end_seconds
       FROM grounding_facts gf
       JOIN courses c ON c.id = gf.course_id
       LEFT JOIN lessons l ON l.id = gf.lesson_id
       JOIN source_segments ss ON ss.id = gf.source_segment_id
       JOIN source_documents sd ON sd.id = ss.source_document_id
       WHERE gf.status = 'published'
         AND gf.risk_level <> 'high'
         AND c.status = 'published'
         AND c.source_link_status = 'linked'
         AND (gf.lesson_id IS NULL OR l.status = 'published')
         AND ss.review_status IN ('approved', 'published')
         AND sd.processing_status IN ('approved', 'published')
       ORDER BY gf.updated_at DESC
       LIMIT 250`,
    );
    const terms = String(message ?? '')
      .toLowerCase()
      .split(/[^\p{L}\p{N}]+/u)
      .filter((term) => term.length >= 4 && !groundingStopWords.has(term));
    if (terms.length === 0) return [];
    const rankedSources = result.rows
      .map((row) => {
        const haystack =
          `${row.title} ${row.excerpt} ${row.question_sw ?? ''}`.toLowerCase();
        const score = terms.reduce(
          (total, term) => total + (haystack.includes(term) ? 1 : 0),
          0,
        );
        return {
          id: row.id,
          courseId: row.course_id,
          lessonId: row.lesson_id,
          courseTitle: row.course_title,
          title: row.title,
          excerpt: row.excerpt,
          sourceTitle: row.source_title,
          citation: sourceCitationFromRow(row),
          score,
        };
      })
      .filter((source) => source.score >= 2)
      .sort((left, right) => right.score - left.score);
    const bestScore = rankedSources[0]?.score;
    return rankedSources
      .filter((source) => source.score === bestScore)
      .slice(0, 5)
      .map(({ score: _score, ...source }) => source);
  }

  async contentCoursesForAdmin() {
    const result = await this.pool.query(
      `SELECT id, status, payload, updated_at
       FROM content_courses
       ORDER BY updated_at DESC`,
    );
    return result.rows.map(contentCourseFromRow);
  }

  async upsertContentCourse({ course, status = 'approved' }) {
    const normalizedCourse = normalizeApprovedCourse(course);
    const result = await this.pool.query(
      `INSERT INTO content_courses (id, status, payload, updated_at)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (id) DO UPDATE
       SET status = EXCLUDED.status,
           payload = EXCLUDED.payload,
           updated_at = EXCLUDED.updated_at
       RETURNING id, status, payload, updated_at`,
      [
        normalizedCourse.id,
        status,
        JSON.stringify(normalizedCourse),
        new Date().toISOString(),
      ],
    );
    return contentCourseFromRow(result.rows[0]);
  }

  async approvedContentDocuments() {
    if (process.env.AJE_STORE === 'supabase') {
      // Source PDFs are private evidence, not learner downloads. A future
      // entitlement-aware endpoint can expose selected documents explicitly.
      return [];
    }
    const result = await this.pool.query(
      `SELECT id, status, payload, updated_at
       FROM content_documents
       WHERE status = 'approved'
       ORDER BY id ASC`,
    );
    return result.rows.map((row) => normalizeContentDocument(row.payload));
  }

  async contentDocumentsForAdmin() {
    const result = await this.pool.query(
      `SELECT id, status, payload, updated_at
       FROM content_documents
       ORDER BY updated_at DESC`,
    );
    return result.rows.map(contentDocumentFromRow);
  }

  async upsertContentDocument({ document, status = 'approved' }) {
    const normalizedDocument = normalizeContentDocument(document);
    const result = await this.pool.query(
      `INSERT INTO content_documents (id, status, payload, updated_at)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (id) DO UPDATE
       SET status = EXCLUDED.status,
           payload = EXCLUDED.payload,
           updated_at = EXCLUDED.updated_at
       RETURNING id, status, payload, updated_at`,
      [
        normalizedDocument.id,
        status,
        JSON.stringify(normalizedDocument),
        new Date().toISOString(),
      ],
    );
    return contentDocumentFromRow(result.rows[0]);
  }

  async getUser(phoneNumber) {
    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    const result = await this.pool.query(
      `SELECT id, phone_number, role, subscription_plan, subscription_started_at,
              display_name, preferred_location, created_at, updated_at
       FROM users
       WHERE phone_number = $1`,
      [normalizedPhone],
    );
    return result.rows[0] ? userFromRow(result.rows[0]) : null;
  }

  async ensureUser(phoneNumber) {
    const existing = await this.getUser(phoneNumber);
    if (existing) return existing;

    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    const now = new Date();
    const user = {
      id: createId('user'),
      phoneNumber: normalizedPhone,
      role: 'learner',
      subscriptionPlan: null,
      subscriptionStartedAt: null,
      createdAt: now.toISOString(),
      updatedAt: now.toISOString(),
    };

    await this.pool.query(
      `INSERT INTO users (
         id, phone_number, role, subscription_plan, subscription_started_at,
         created_at, updated_at
       ) VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [
        user.id,
        user.phoneNumber,
        user.role,
        user.subscriptionPlan,
        user.subscriptionStartedAt,
        user.createdAt,
        user.updatedAt,
      ],
    );
    return user;
  }

  async activateSubscription({ phoneNumber, planTitle }) {
    const user = await this.ensureUser(phoneNumber);
    const startedAt = new Date();
    const updatedAt = startedAt.toISOString();
    await this.pool.query(
      `UPDATE users
       SET subscription_plan = $2,
           subscription_started_at = $3,
           updated_at = $4
       WHERE id = $1`,
      [user.id, planTitle, startedAt.toISOString(), updatedAt],
    );
    return {
      ...user,
      subscriptionPlan: planTitle,
      subscriptionStartedAt: startedAt.toISOString(),
      updatedAt,
    };
  }

  async cancelSubscription(phoneNumber) {
    const user = await this.getUser(phoneNumber);
    if (!user) return null;

    const updatedAt = new Date().toISOString();
    await this.pool.query(
      `UPDATE users
       SET subscription_plan = NULL,
           subscription_started_at = NULL,
           updated_at = $2
       WHERE id = $1`,
      [user.id, updatedAt],
    );
    return {
      ...user,
      subscriptionPlan: null,
      subscriptionStartedAt: null,
      updatedAt,
    };
  }

  async updateUserProfile(phoneNumber, { displayName, preferredLocation }) {
    const user = await this.ensureUser(phoneNumber);
    const nextDisplayName =
      displayName === undefined
        ? user.displayName ?? null
        : typeof displayName === 'string' && displayName.trim().length > 0
          ? displayName.trim()
          : null;
    const nextPreferredLocation =
      preferredLocation === undefined
        ? user.preferredLocation ?? null
        : typeof preferredLocation === 'string' &&
            preferredLocation.trim().length > 0
          ? preferredLocation.trim()
          : null;
    const updatedAt = new Date().toISOString();
    const result = await this.pool.query(
      `UPDATE users
       SET display_name = $2,
           preferred_location = $3,
           updated_at = $4
       WHERE id = $1
       RETURNING id, phone_number, role, subscription_plan, subscription_started_at,
                 display_name, preferred_location, created_at, updated_at`,
      [user.id, nextDisplayName, nextPreferredLocation, updatedAt],
    );
    return userFromRow(result.rows[0]);
  }

  async notificationSettings(phoneNumber) {
    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    const result = await this.pool.query(
      `SELECT phone_number, enabled, community_replies, moderation_updates,
              learning_reminders, updated_at
       FROM notification_settings
       WHERE phone_number = $1`,
      [normalizedPhone],
    );
    if (!result.rows[0]) {
      return {
        phoneNumber: normalizedPhone,
        enabled: true,
        communityReplies: true,
        moderationUpdates: true,
        learningReminders: true,
      };
    }
    return notificationSettingsFromRow(result.rows[0]);
  }

  async updateNotificationSettings({ phoneNumber, settings }) {
    const current = await this.notificationSettings(phoneNumber);
    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    const next = {
      enabled:
        typeof settings.enabled === 'boolean' ? settings.enabled : current.enabled,
      communityReplies:
        typeof settings.communityReplies === 'boolean'
          ? settings.communityReplies
          : current.communityReplies,
      moderationUpdates:
        typeof settings.moderationUpdates === 'boolean'
          ? settings.moderationUpdates
          : current.moderationUpdates,
      learningReminders:
        typeof settings.learningReminders === 'boolean'
          ? settings.learningReminders
          : current.learningReminders,
    };
    const result = await this.pool.query(
      `INSERT INTO notification_settings (
         phone_number, enabled, community_replies, moderation_updates,
         learning_reminders, updated_at
       ) VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (phone_number) DO UPDATE
       SET enabled = EXCLUDED.enabled,
           community_replies = EXCLUDED.community_replies,
           moderation_updates = EXCLUDED.moderation_updates,
           learning_reminders = EXCLUDED.learning_reminders,
           updated_at = EXCLUDED.updated_at
       RETURNING phone_number, enabled, community_replies, moderation_updates,
                 learning_reminders, updated_at`,
      [
        normalizedPhone,
        next.enabled,
        next.communityReplies,
        next.moderationUpdates,
        next.learningReminders,
        new Date().toISOString(),
      ],
    );
    return notificationSettingsFromRow(result.rows[0]);
  }

  async registerNotificationDevice({ phoneNumber, token, platform }) {
    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    const now = new Date().toISOString();
    const result = await this.pool.query(
      `INSERT INTO notification_devices (
         id, phone_number, token, platform, created_at, updated_at
       ) VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (token) DO UPDATE
       SET phone_number = EXCLUDED.phone_number,
           platform = EXCLUDED.platform,
           updated_at = EXCLUDED.updated_at
       RETURNING id, phone_number, token, platform, created_at, updated_at`,
      [createId('device'), normalizedPhone, token, platform, now, now],
    );
    return notificationDeviceFromRow(result.rows[0]);
  }

  async notificationDevices(phoneNumber) {
    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    const result = await this.pool.query(
      `SELECT id, phone_number, token, platform, created_at, updated_at
       FROM notification_devices
       WHERE phone_number = $1`,
      [normalizedPhone],
    );
    return result.rows.map(notificationDeviceFromRow);
  }

  async notificationsFor(phoneNumber) {
    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    const result = await this.pool.query(
      `SELECT id, phone_number, type, title, body, data, read_at, created_at
       FROM notifications
       WHERE phone_number = $1
       ORDER BY created_at DESC`,
      [normalizedPhone],
    );
    return result.rows.map(notificationFromRow);
  }

  async createNotification({ phoneNumber, type, title, body, data = {} }) {
    const settings = await this.notificationSettings(phoneNumber);
    if (!settings.enabled) return null;
    if (type === 'community_reply' && !settings.communityReplies) return null;
    if (type === 'moderation_update' && !settings.moderationUpdates) return null;
    const now = new Date().toISOString();
    const result = await this.pool.query(
      `INSERT INTO notifications (
         id, phone_number, type, title, body, data, read_at, created_at
       ) VALUES ($1, $2, $3, $4, $5, $6, NULL, $7)
       RETURNING id, phone_number, type, title, body, data, read_at, created_at`,
      [
        createId('notification'),
        normalizePhoneNumber(phoneNumber),
        type,
        title,
        body,
        JSON.stringify(data),
        now,
      ],
    );
    return notificationFromRow(result.rows[0]);
  }

  async markNotificationRead({ phoneNumber, notificationId }) {
    const result = await this.pool.query(
      `UPDATE notifications
       SET read_at = COALESCE(read_at, $3)
       WHERE id = $1 AND phone_number = $2
       RETURNING id, phone_number, type, title, body, data, read_at, created_at`,
      [notificationId, normalizePhoneNumber(phoneNumber), new Date().toISOString()],
    );
    return result.rows[0] ? notificationFromRow(result.rows[0]) : null;
  }

  async learningProgress(phoneNumber) {
    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    const result = await this.pool.query(
      `SELECT phone_number, course_id, lesson_id, completed_at
       FROM learning_progress
       WHERE phone_number = $1
       ORDER BY completed_at ASC`,
      [normalizedPhone],
    );
    return result.rows.map((row) => ({
      phoneNumber: row.phone_number,
      courseId: row.course_id,
      lessonId: row.lesson_id,
      completedAt: new Date(row.completed_at).toISOString(),
    }));
  }

  async markLessonCompleted({ phoneNumber, courseId, lessonId }) {
    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    if (
      !hasApprovedLessonInCourses(
        await this.approvedContentCourses(),
        courseId,
        lessonId,
      )
    ) {
      return null;
    }
    await this.ensureUser(normalizedPhone);
    const completedAt = new Date().toISOString();
    const result = await this.pool.query(
      `INSERT INTO learning_progress (
         phone_number, course_id, lesson_id, completed_at
       ) VALUES ($1, $2, $3, $4)
       ON CONFLICT (phone_number, course_id, lesson_id) DO UPDATE
       SET completed_at = learning_progress.completed_at
       RETURNING phone_number, course_id, lesson_id, completed_at`,
      [normalizedPhone, courseId, lessonId, completedAt],
    );
    const row = result.rows[0];
    return {
      phoneNumber: row.phone_number,
      courseId: row.course_id,
      lessonId: row.lesson_id,
      completedAt: new Date(row.completed_at).toISOString(),
    };
  }

  async communityPosts() {
    const posts = await this.pool.query(
      `SELECT id, author, location, time_label, content, likes, comments, tags,
              related_topic, has_image, is_expert, is_urgent,
              moderation_status, moderated_at, moderated_by, created_at
       FROM community_posts
       WHERE moderation_status <> 'hidden'
       ORDER BY created_at DESC`,
    );
    const postIds = posts.rows.map((row) => row.id);
    if (postIds.length === 0) return [];

    const replies = await this.pool.query(
      `SELECT post_id, author, body, time_label, is_expert, created_at
       FROM community_replies
       WHERE post_id = ANY($1)
       ORDER BY created_at ASC`,
      [postIds],
    );
    const repliesByPost = new Map();
    for (const reply of replies.rows) {
      const items = repliesByPost.get(reply.post_id) ?? [];
      items.push(replyFromRow(reply));
      repliesByPost.set(reply.post_id, items);
    }

    return posts.rows.map((row) => ({
      ...communityPostFromRow(row),
      replies: repliesByPost.get(row.id) ?? [],
    }));
  }

  async otpRequestDelaySeconds(phoneNumber, cooldownMs = 60 * 1000) {
    await this.#purgeExpiredOtpChallenges();
    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    const result = await this.pool.query(
      `SELECT created_at
       FROM otp_challenges
       WHERE phone_number = $1
       ORDER BY created_at DESC
       LIMIT 1`,
      [normalizedPhone],
    );
    const latestChallenge = result.rows[0];
    if (!latestChallenge) return 0;
    const nextAllowedAt = Number(latestChallenge.created_at) + cooldownMs;
    return Math.max(0, Math.ceil((nextAllowedAt - Date.now()) / 1000));
  }

  async createOtpChallenge({ phoneNumber, otp, deliveryProvider }) {
    await this.#purgeExpiredOtpChallenges();
    const now = Date.now();
    const challenge = {
      id: createId('otp'),
      phoneNumber: normalizePhoneNumber(phoneNumber),
      otpHash: hashOtp(otp),
      createdAt: now,
      expiresAt: now + otpTtlMs,
      deliveryProvider,
    };

    await this.pool.query(
      `INSERT INTO otp_challenges (
         id, phone_number, otp_hash, created_at, expires_at, delivery_provider
       ) VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        challenge.id,
        challenge.phoneNumber,
        challenge.otpHash,
        challenge.createdAt,
        challenge.expiresAt,
        challenge.deliveryProvider,
      ],
    );
    return challenge;
  }

  async consumeOtpChallenge({ challengeId, phoneNumber, otp }) {
    const result = await this.pool.query(
      `SELECT id, phone_number, otp_hash, expires_at
       FROM otp_challenges
       WHERE id = $1`,
      [challengeId],
    );
    const challenge = result.rows[0];
    if (!challenge) return { status: 'missing' };
    if (Number(challenge.expires_at) < Date.now()) {
      await this.pool.query(`DELETE FROM otp_challenges WHERE id = $1`, [
        challengeId,
      ]);
      return { status: 'expired' };
    }
    if (
      challenge.phone_number !== phoneNumber ||
      !verifyOtpHash(otp, challenge.otp_hash)
    ) {
      return { status: 'invalid' };
    }
    await this.pool.query(`DELETE FROM otp_challenges WHERE id = $1`, [
      challengeId,
    ]);
    return { status: 'verified' };
  }

  async createPaymentTransaction(transaction) {
    await this.pool.query(
      `INSERT INTO payment_transactions (
         id, plan_title, price, method, phone_number, status, message,
         receipt_number, provider, provider_reference, checkout_instructions,
         auto_confirm_at, subscription_plan, subscription_started_at
       ) VALUES (
         $1, $2, $3, $4, $5, $6, $7,
         $8, $9, $10, $11,
         $12, $13, $14
       )`,
      [
        transaction.id,
        transaction.planTitle,
        transaction.price,
        transaction.method,
        transaction.phoneNumber,
        transaction.status,
        transaction.message,
        transaction.receiptNumber,
        transaction.provider,
        transaction.providerReference,
        transaction.checkoutInstructions,
        transaction.autoConfirmAt,
        transaction.subscriptionPlan,
        transaction.subscriptionStartedAt,
      ],
    );
    return transaction;
  }

  async getPaymentTransaction(id) {
    const result = await this.pool.query(
      `SELECT id, plan_title, price, method, phone_number, status, message,
              receipt_number, provider, provider_reference, checkout_instructions,
              auto_confirm_at, subscription_plan, subscription_started_at
       FROM payment_transactions
       WHERE id = $1`,
      [id],
    );
    return result.rows[0] ? paymentFromRow(result.rows[0]) : null;
  }

  async markPaymentPaid(transactionId) {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      const existing = await client.query(
        `SELECT id, plan_title, price, method, phone_number, status, message,
                receipt_number, provider, provider_reference, checkout_instructions,
                auto_confirm_at, subscription_plan, subscription_started_at
         FROM payment_transactions
         WHERE id = $1
         FOR UPDATE`,
        [transactionId],
      );
      if (!existing.rows[0]) {
        await client.query('ROLLBACK');
        return null;
      }

      const transaction = paymentFromRow(existing.rows[0]);
      if (transaction.status === 'paid') {
        await client.query('COMMIT');
        return transaction;
      }

      const user = await this.#activateSubscriptionWithClient(client, {
        phoneNumber: transaction.phoneNumber,
        planTitle: transaction.planTitle,
      });
      const receiptNumber = `AJE-${transaction.id.slice(-6).toUpperCase()}`;
      const message = `Malipo yamethibitishwa kupitia ${transaction.method}.`;
      const updated = await client.query(
        `UPDATE payment_transactions
         SET status = 'paid',
             message = $2,
             receipt_number = $3,
             subscription_plan = $4,
             subscription_started_at = $5
         WHERE id = $1
         RETURNING id, plan_title, price, method, phone_number, status, message,
                   receipt_number, provider, provider_reference, checkout_instructions,
                   auto_confirm_at, subscription_plan, subscription_started_at`,
        [
          transactionId,
          message,
          receiptNumber,
          user.subscriptionPlan,
          user.subscriptionStartedAt,
        ],
      );
      await client.query('COMMIT');
      return paymentFromRow(updated.rows[0]);
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async markPaymentFailed(transactionId, message) {
    const result = await this.pool.query(
      `UPDATE payment_transactions
       SET status = 'failed', message = $2
       WHERE id = $1
       RETURNING id, plan_title, price, method, phone_number, status, message,
                 receipt_number, provider, provider_reference, checkout_instructions,
                 auto_confirm_at, subscription_plan, subscription_started_at`,
      [transactionId, message],
    );
    return result.rows[0] ? paymentFromRow(result.rows[0]) : null;
  }

  async createCommunityPost({ author, content, location, tags }) {
    const normalizedTags = [...new Set(tags.map((tag) => tag.trim()))].filter(
      Boolean,
    );
    const post = {
      id: createId('post'),
      author: author.trim(),
      location: location.trim(),
      time: 'Sasa hivi',
      content: content.trim(),
      likes: 0,
      comments: 0,
      tags: normalizedTags,
      replies: [],
      relatedTopic: normalizedTags[0] ?? null,
      hasImage: false,
      isExpert: false,
      isUrgent:
        normalizedTags.includes('Magonjwa') ||
        normalizedTags.includes('Wadudu'),
      moderationStatus: 'visible',
    };
    await this.#insertCommunityPost(post, new Date());
    return post;
  }

  async addCommunityReply({ postId, author, body }) {
    const reply = {
      author: author.trim(),
      body: body.trim(),
      time: 'Sasa hivi',
      isExpert: false,
    };
    await this.pool.query(
      `INSERT INTO community_replies (
         id, post_id, author, body, time_label, is_expert, created_at
       ) VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [
        createId('reply'),
        postId,
        reply.author,
        reply.body,
        reply.time,
        reply.isExpert,
        new Date().toISOString(),
      ],
    );
    await this.pool.query(
      `UPDATE community_posts
       SET comments = comments + 1
       WHERE id = $1`,
      [postId],
    );
    return reply;
  }

  async reportCommunityPost(postId) {
    await this.pool.query(
      `INSERT INTO reported_community_posts (post_id, reported_at)
       VALUES ($1, $2)
       ON CONFLICT (post_id) DO NOTHING`,
      [postId, new Date().toISOString()],
    );
  }

  async reportedCommunityPosts() {
    const reports = await this.pool.query(
      `SELECT r.post_id, r.reported_at,
              p.id, p.author, p.location, p.time_label, p.content, p.likes,
              p.comments, p.tags, p.related_topic, p.has_image, p.is_expert,
              p.is_urgent, p.moderation_status, p.moderated_at, p.moderated_by,
              p.created_at
       FROM reported_community_posts r
       JOIN community_posts p ON p.id = r.post_id
       ORDER BY r.reported_at DESC`,
    );
    return reports.rows.map((row) => ({
      post: communityPostFromRow(row),
      report: {
        postId: row.post_id,
        reportedAt: new Date(row.reported_at).toISOString(),
        status: row.moderation_status === 'hidden' ? 'hidden' : 'open',
      },
    }));
  }

  async resolveCommunityReport({ postId, action, moderatorPhoneNumber }) {
    if (action === 'hide') {
      const result = await this.pool.query(
        `UPDATE community_posts
         SET moderation_status = 'hidden',
             moderated_at = $2,
             moderated_by = $3
         WHERE id = $1
         RETURNING id, author, location, time_label, content, likes, comments,
                   tags, related_topic, has_image, is_expert, is_urgent,
                   moderation_status, moderated_at, moderated_by, created_at`,
        [postId, new Date().toISOString(), moderatorPhoneNumber],
      );
      await this.pool.query(
        `DELETE FROM reported_community_posts WHERE post_id = $1`,
        [postId],
      );
      return result.rows[0] ? communityPostFromRow(result.rows[0]) : null;
    }

    const result = await this.pool.query(
      `SELECT id, author, location, time_label, content, likes, comments, tags,
              related_topic, has_image, is_expert, is_urgent,
              moderation_status, moderated_at, moderated_by, created_at
       FROM community_posts
       WHERE id = $1`,
      [postId],
    );
    await this.pool.query(
      `DELETE FROM reported_community_posts WHERE post_id = $1`,
      [postId],
    );
    return result.rows[0] ? communityPostFromRow(result.rows[0]) : null;
  }

  async createAuthSession(phoneNumber) {
    await this.#purgeExpiredAuthSessions();
    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    const token = createSessionToken();
    const createdAt = new Date().toISOString();
    const expiresAt = sessionExpiresAt();
    await this.pool.query(
      `INSERT INTO auth_sessions (token, phone_number, created_at, expires_at)
       VALUES ($1, $2, $3, $4)`,
      [token, normalizedPhone, createdAt, expiresAt],
    );
    return { token, phoneNumber: normalizedPhone, createdAt, expiresAt };
  }

  async getAuthSession(token) {
    await this.#purgeExpiredAuthSessions();
    const result = await this.pool.query(
      `SELECT phone_number, expires_at
       FROM auth_sessions
       WHERE token = $1`,
      [token],
    );
    const row = result.rows[0];
    if (!row || isSessionExpired(row.expires_at)) return null;
    return { phoneNumber: row.phone_number };
  }

  async resetForTests() {
    await this.pool.query(`
      TRUNCATE TABLE
        reported_community_posts,
        community_replies,
        community_posts,
        auth_sessions,
        otp_challenges,
        learning_progress,
        notification_settings,
        notification_devices,
        notifications,
        content_documents,
        content_courses,
        payment_transactions,
        users
      RESTART IDENTITY
    `);
    await this.#seedContentCatalog();
    await this.#seedCommunityCatalog();
  }

  async #activateSubscriptionWithClient(client, { phoneNumber, planTitle }) {
    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    const existing = await client.query(
      `SELECT id, phone_number, role, subscription_plan, subscription_started_at,
              created_at, updated_at
       FROM users
       WHERE phone_number = $1`,
      [normalizedPhone],
    );

    const startedAt = new Date();
    const updatedAt = startedAt.toISOString();
    if (existing.rows[0]) {
      const updated = await client.query(
        `UPDATE users
         SET subscription_plan = $2,
             subscription_started_at = $3,
             updated_at = $4
         WHERE id = $1
         RETURNING id, phone_number, role, subscription_plan, subscription_started_at,
                   created_at, updated_at`,
        [existing.rows[0].id, planTitle, startedAt.toISOString(), updatedAt],
      );
      return userFromRow(updated.rows[0]);
    }

    const user = {
      id: createId('user'),
      phoneNumber: normalizedPhone,
      role: 'learner',
      subscriptionPlan: planTitle,
      subscriptionStartedAt: startedAt.toISOString(),
      createdAt: updatedAt,
      updatedAt,
    };
    await client.query(
      `INSERT INTO users (
         id, phone_number, role, subscription_plan, subscription_started_at,
         created_at, updated_at
       ) VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [
        user.id,
        user.phoneNumber,
        user.role,
        user.subscriptionPlan,
        user.subscriptionStartedAt,
        user.createdAt,
        user.updatedAt,
      ],
    );
    return user;
  }

  async #purgeExpiredOtpChallenges() {
    await this.pool.query(`DELETE FROM otp_challenges WHERE expires_at < $1`, [
      Date.now(),
    ]);
  }

  async #purgeExpiredAuthSessions() {
    await this.pool.query(`DELETE FROM auth_sessions WHERE expires_at <= NOW()`);
  }

  async #migrate() {
    const schemaPath = path.join(__dirname, 'schema.sql');
    const sql = fs.readFileSync(schemaPath, 'utf8');
    await this.pool.query(sql);
  }

  async #ensureSchema() {
    if (this.schema === 'public') return;
    await this.pool.query(`CREATE SCHEMA IF NOT EXISTS ${this.schema}`);
  }

  async #seedCommunityCatalog() {
    await this.pool.query(
      `UPDATE community_posts
       SET moderation_status = 'hidden',
           moderated_at = NOW(),
           moderated_by = 'content-readiness-migration'
       WHERE id = ANY($1)`,
      [[
        'seed-pasheni-disease',
        'seed-kuku-start',
        'seed-nyanya-market',
      ]],
    );
    for (const [index, post] of this.catalog.communityPosts.entries()) {
      await this.#insertCommunityPost(
        {
          ...post,
          comments: post.comments ?? post.replies.length,
          replies: post.replies ?? [],
        },
        new Date(Date.now() - (index + 1) * 60 * 1000),
      );
      for (const [replyIndex, reply] of (post.replies ?? []).entries()) {
        await this.pool.query(
          `INSERT INTO community_replies (
             id, post_id, author, body, time_label, is_expert, created_at
           ) VALUES ($1, $2, $3, $4, $5, $6, $7)
           ON CONFLICT (id) DO NOTHING`,
          [
            `${post.id}-reply-${replyIndex}`,
            post.id,
            reply.author,
            reply.body,
            reply.time,
            reply.isExpert ?? false,
            new Date(Date.now() - (index + 1) * 60 * 1000 + replyIndex).toISOString(),
          ],
        );
      }
    }
  }

  async #seedContentCatalog() {
    const courses = approvedCoursesFromCatalog(this.catalog);
    for (const course of courses) {
      await this.pool.query(
        `INSERT INTO content_courses (id, status, payload, updated_at)
         VALUES ($1, 'approved', $2, $3)
         ON CONFLICT (id) DO UPDATE
         SET status = EXCLUDED.status,
             payload = EXCLUDED.payload,
             updated_at = EXCLUDED.updated_at
         WHERE CASE
           WHEN jsonb_typeof(content_courses.payload -> 'contentVersion') = 'number'
             THEN (content_courses.payload ->> 'contentVersion')::integer
           ELSE 0
         END < (EXCLUDED.payload ->> 'contentVersion')::integer`,
        [course.id, JSON.stringify(course), new Date().toISOString()],
      );
    }
    await this.pool.query(
      `UPDATE content_documents
       SET status = 'draft', updated_at = NOW()
       WHERE id = ANY($1)
         AND payload ->> 'courseId' = ANY($2)`,
      [[
        'mwongozo-mfupi-wa-pasheni',
        'ratiba-ya-chanjo',
        'udhibiti-wa-wadudu',
      ], ['pasheni', 'kuku', 'nyanya']],
    );
    for (const document of documentsFromCourses(courses)) {
      await this.pool.query(
        `INSERT INTO content_documents (id, status, payload, updated_at)
         VALUES ($1, 'approved', $2, $3)
         ON CONFLICT (id) DO NOTHING`,
        [document.id, JSON.stringify(document), new Date().toISOString()],
      );
    }
  }

  async #insertCommunityPost(post, createdAt) {
    await this.pool.query(
      `INSERT INTO community_posts (
         id, author, location, time_label, content, likes, comments, tags,
         related_topic, has_image, is_expert, is_urgent, moderation_status,
         moderated_at, moderated_by, created_at
       ) VALUES (
         $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12,
         $13, $14, $15, $16
       )
       ON CONFLICT (id) DO NOTHING`,
      [
        post.id,
        post.author,
        post.location,
        post.time,
        post.content,
        post.likes ?? 0,
        post.comments ?? 0,
        JSON.stringify(post.tags ?? []),
        post.relatedTopic ?? null,
        post.hasImage ?? false,
        post.isExpert ?? false,
        post.isUrgent ?? false,
        post.moderationStatus ?? 'visible',
        post.moderatedAt ?? null,
        post.moderatedBy ?? null,
        createdAt.toISOString(),
      ],
    );
  }
}

function normalizeSchemaIdentifier(schema) {
  const normalized = String(schema ?? '').trim();
  if (!/^[a-z_][a-z0-9_]*$/.test(normalized)) {
    throw new Error(
      'AJE_DB_SCHEMA must be a lowercase PostgreSQL identifier, e.g. "aje".',
    );
  }
  return normalized;
}

function communityPostFromRow(row) {
  return {
    id: row.id,
    author: row.author,
    location: row.location,
    time: row.time_label,
    content: row.content,
    likes: row.likes,
    comments: row.comments,
    tags: row.tags,
    replies: [],
    relatedTopic: row.related_topic,
    hasImage: row.has_image,
    isExpert: row.is_expert,
    isUrgent: row.is_urgent,
    moderationStatus: row.moderation_status ?? 'visible',
    moderatedAt: row.moderated_at
      ? new Date(row.moderated_at).toISOString()
      : null,
    moderatedBy: row.moderated_by ?? null,
  };
}

function replyFromRow(row) {
  return {
    author: row.author,
    body: row.body,
    time: row.time_label,
    isExpert: row.is_expert,
  };
}

function notificationSettingsFromRow(row) {
  return {
    phoneNumber: row.phone_number,
    enabled: row.enabled,
    communityReplies: row.community_replies,
    moderationUpdates: row.moderation_updates,
    learningReminders: row.learning_reminders,
    updatedAt: new Date(row.updated_at).toISOString(),
  };
}

function notificationDeviceFromRow(row) {
  return {
    id: row.id,
    phoneNumber: row.phone_number,
    token: row.token,
    platform: row.platform,
    createdAt: new Date(row.created_at).toISOString(),
    updatedAt: new Date(row.updated_at).toISOString(),
  };
}

function notificationFromRow(row) {
  return {
    id: row.id,
    phoneNumber: row.phone_number,
    type: row.type,
    title: row.title,
    body: row.body,
    data: row.data ?? {},
    readAt: row.read_at ? new Date(row.read_at).toISOString() : null,
    createdAt: new Date(row.created_at).toISOString(),
  };
}

function contentCourseFromRow(row) {
  return {
    id: row.id,
    status: row.status,
    course: normalizeApprovedCourse(row.payload),
    updatedAt: new Date(row.updated_at).toISOString(),
  };
}

function contentDocumentFromRow(row) {
  return {
    id: row.id,
    status: row.status,
    document: normalizeContentDocument(row.payload),
    updatedAt: new Date(row.updated_at).toISOString(),
  };
}

export function courseImageForCode(code) {
  const normalized = String(code ?? '').toLowerCase();
  if (normalized.includes('kuku') || normalized.includes('kuk')) {
    return 'assets/images/courses/kuku.jpg';
  }
  if (
    normalized.includes('ush') ||
    normalized.includes('psh') ||
    normalized.includes('pasheni') ||
    normalized.includes('business') ||
    normalized.includes('biashara')
  ) {
    return 'assets/images/courses/pasheni.jpg';
  }
  return 'assets/images/courses/nyanya.jpg';
}

function sourceCitationFromRow(row) {
  if (row.page_start != null) {
    return row.page_end != null && row.page_end !== row.page_start
      ? `${row.source_title}, kurasa ${row.page_start}-${row.page_end}`
      : `${row.source_title}, ukurasa ${row.page_start}`;
  }
  if (row.time_start_seconds != null) {
    return `${row.source_title}, ${formatTimecode(row.time_start_seconds)}-${formatTimecode(row.time_end_seconds ?? row.time_start_seconds)}`;
  }
  return row.source_title;
}

function formatTimecode(seconds) {
  const total = Math.max(0, Number(seconds) || 0);
  const minutes = Math.floor(total / 60);
  const remainder = total % 60;
  return `${minutes}:${String(remainder).padStart(2, '0')}`;
}

function encodeStoragePath(path) {
  return String(path)
    .split('/')
    .map((part) => encodeURIComponent(part))
    .join('/');
}

function safePublicHttpUrl(value) {
  try {
    const url = new URL(String(value));
    return url.protocol === 'https:' || url.protocol === 'http:'
      ? url.toString()
      : null;
  } catch {
    return null;
  }
}

export function resolveSupabaseSignedUrl(supabaseUrl, signedPath) {
  const absolute = safePublicHttpUrl(signedPath);
  if (absolute) return absolute;

  try {
    const base = new URL(String(supabaseUrl));
    const path = String(signedPath).startsWith('/storage/v1/')
      ? String(signedPath)
      : String(signedPath).startsWith('/object/')
        ? `/storage/v1${signedPath}`
        : `/storage/v1/${String(signedPath).replace(/^\/+/, '')}`;
    return new URL(path, base).toString();
  } catch {
    return null;
  }
}

export async function importJsonStoreToPostgres(pool, rawState) {
  for (const record of rawState.contentCourses ?? []) {
    const course = normalizeApprovedCourse(record.course);
    await pool.query(
      `INSERT INTO content_courses (id, status, payload, updated_at)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (id) DO UPDATE
       SET status = EXCLUDED.status,
           payload = EXCLUDED.payload,
           updated_at = EXCLUDED.updated_at`,
      [
        course.id,
        record.status === 'draft' ? 'draft' : 'approved',
        JSON.stringify(course),
        record.updatedAt ?? new Date().toISOString(),
      ],
    );
  }

  for (const record of rawState.contentDocuments ?? []) {
    const document = normalizeContentDocument(record.document);
    await pool.query(
      `INSERT INTO content_documents (id, status, payload, updated_at)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (id) DO UPDATE
       SET status = EXCLUDED.status,
           payload = EXCLUDED.payload,
           updated_at = EXCLUDED.updated_at`,
      [
        document.id,
        record.status === 'draft' ? 'draft' : 'approved',
        JSON.stringify(document),
        record.updatedAt ?? new Date().toISOString(),
      ],
    );
  }

  for (const user of rawState.users ?? []) {
    await pool.query(
      `INSERT INTO users (
         id, phone_number, role, subscription_plan, subscription_started_at,
         created_at, updated_at
       ) VALUES ($1, $2, $3, $4, $5, $6, $7)
       ON CONFLICT (phone_number) DO UPDATE
       SET role = EXCLUDED.role,
           subscription_plan = EXCLUDED.subscription_plan,
           subscription_started_at = EXCLUDED.subscription_started_at,
           updated_at = EXCLUDED.updated_at`,
      [
        user.id,
        user.phoneNumber,
        user.role ?? 'learner',
        user.subscriptionPlan,
        user.subscriptionStartedAt,
        user.createdAt ?? new Date().toISOString(),
        user.updatedAt ?? new Date().toISOString(),
      ],
    );
  }

  for (const transaction of rawState.paymentTransactions ?? []) {
    await pool.query(
      `INSERT INTO payment_transactions (
         id, plan_title, price, method, phone_number, status, message,
         receipt_number, provider, provider_reference, checkout_instructions,
         auto_confirm_at, subscription_plan, subscription_started_at
       ) VALUES (
         $1, $2, $3, $4, $5, $6, $7,
         $8, $9, $10, $11,
         $12, $13, $14
       )
       ON CONFLICT (id) DO NOTHING`,
      [
        transaction.id,
        transaction.planTitle,
        transaction.price,
        transaction.method,
        transaction.phoneNumber,
        transaction.status,
        transaction.message,
        transaction.receiptNumber,
        transaction.provider,
        transaction.providerReference,
        transaction.checkoutInstructions,
        transaction.autoConfirmAt,
        transaction.subscriptionPlan,
        transaction.subscriptionStartedAt,
      ],
    );
  }
}
