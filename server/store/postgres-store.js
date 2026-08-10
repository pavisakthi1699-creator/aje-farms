import fs from 'node:fs';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import pg from 'pg';

import {
  approvedCoursesFromCatalog,
  communityPostImageUrl,
  communityPostImagesBucket,
  createId,
  documentsFromCourses,
  defaultHomeTopics,
  defaultCommunityTopics,
  extensionForImageContentType,
  extensionForVideoContentType,
  hasApprovedLessonInCourses,
  isLearnerReadyCourse,
  lessonVideosBucket,
  lessonVideosPrefix,
  mergeLegacyHomeTopics,
  normalizeApprovedCourse,
  normalizeContentDocument,
  normalizeEmail,
  normalizeHomeTopics,
  normalizeCommunityTopics,
  paymentFromRow,
  userFromRow,
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
    const [courses, documents, plans, communityPosts, homeTopics, communityTopics] =
      await Promise.all([
        this.approvedContentCourses(),
        this.approvedContentDocuments(),
        this.activePlans(),
        this.communityPosts(),
        this.homeTopics(),
        this.communityTopics(),
      ]);
    return {
      courses,
      documents,
      problemCategories: this.catalog.problemCategories,
      plans,
      communityPosts,
      homeTopics,
      communityTopics,
    };
  }

  async homeTopics() {
    const result = await this.pool.query(
      `SELECT value FROM app_settings WHERE key = 'home_topics'`,
    );
    if (result.rows.length === 0) return [...defaultHomeTopics];
    try {
      return normalizeHomeTopics(result.rows[0].value);
    } catch (_) {
      return [...defaultHomeTopics];
    }
  }

  async updateHomeTopics(topics) {
    const normalized = normalizeHomeTopics(topics);
    await this.pool.query(
      `INSERT INTO app_settings (key, value, updated_at)
       VALUES ('home_topics', $1, NOW())
       ON CONFLICT (key) DO UPDATE
       SET value = EXCLUDED.value, updated_at = EXCLUDED.updated_at`,
      [JSON.stringify(normalized)],
    );
    return normalized;
  }

  async communityTopics() {
    const result = await this.pool.query(
      `SELECT value FROM app_settings WHERE key = 'community_topics'`,
    );
    if (result.rows.length === 0) return [...defaultCommunityTopics];
    try {
      return normalizeCommunityTopics(result.rows[0].value);
    } catch (_) {
      return [...defaultCommunityTopics];
    }
  }

  async updateCommunityTopics(topics) {
    const normalized = normalizeCommunityTopics(topics);
    await this.pool.query(
      `INSERT INTO app_settings (key, value, updated_at)
       VALUES ('community_topics', $1, NOW())
       ON CONFLICT (key) DO UPDATE
       SET value = EXCLUDED.value, updated_at = EXCLUDED.updated_at`,
      [JSON.stringify(normalized)],
    );
    return normalized;
  }

  async updateLegacyHomeTopics(topics) {
    const normalizedLegacy = normalizeHomeTopics(topics);
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      await client.query(
        `INSERT INTO app_settings (key, value, updated_at)
         VALUES ('home_topics', $1, NOW())
         ON CONFLICT (key) DO NOTHING`,
        [JSON.stringify(defaultHomeTopics)],
      );
      const result = await client.query(
        `SELECT value FROM app_settings
         WHERE key = 'home_topics'
         FOR UPDATE`,
      );
      let current;
      try {
        current = normalizeHomeTopics(result.rows[0].value);
      } catch (_) {
        current = [...defaultHomeTopics];
      }
      const merged = normalizeHomeTopics(
        mergeLegacyHomeTopics(current, normalizedLegacy),
      );
      await client.query(
        `UPDATE app_settings
         SET value = $1, updated_at = NOW()
         WHERE key = 'home_topics'`,
        [JSON.stringify(merged)],
      );
      await client.query('COMMIT');
      return merged;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async activePlans() {
    const result = await this.pool.query(
      `SELECT id, title, subtitle, price_tzs, duration_days, icon, recommended
       FROM plans WHERE enabled = TRUE ORDER BY sort_order`,
    );
    return result.rows.map((row) => ({
      id: row.id,
      title: row.title,
      subtitle: row.subtitle,
      price: `TZS ${Number(row.price_tzs).toLocaleString('en-US')}`,
      priceTzs: Number(row.price_tzs),
      durationDays: Number(row.duration_days),
      icon: row.icon,
      recommended: row.recommended,
    }));
  }

  async getPlan(planId) {
    const result = await this.pool.query(
      `SELECT id, title, price_tzs, duration_days, enabled
       FROM plans WHERE id = $1`,
      [planId],
    );
    const row = result.rows[0];
    if (!row) return null;
    return {
      id: row.id,
      title: row.title,
      priceTzs: Number(row.price_tzs),
      durationDays: Number(row.duration_days),
      enabled: row.enabled,
    };
  }

  // Staff pick a plan id; the price and duration always come from the plans
  // table, never from request input.
  async recordPaymentRecord({
    userId,
    planId,
    method,
    amountTzs,
    currency = 'TZS',
    reference = null,
    note = null,
    recordedByUserId,
  }) {
    const plan = await this.getPlan(planId);
    if (!plan || !plan.enabled) return null;
    if (currency !== 'TZS' || amountTzs !== plan.priceTzs) {
      const mismatch = new Error(
        `Payment must match the selected plan price of TZS ${plan.priceTzs}.`,
      );
      mismatch.code = 'PAYMENT_AMOUNT_MISMATCH';
      throw mismatch;
    }
    const normalizedReference =
      typeof reference === 'string' && reference.trim()
        ? reference.trim().toUpperCase()
        : null;
    const now = new Date().toISOString();
    try {
      const result = await this.pool.query(
        `INSERT INTO payment_records (
           id, user_id, plan_id, method, amount_tzs, currency, reference, note,
           status, recorded_by, created_at, updated_at
         ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'pending', $9, $10, $10)
         RETURNING *`,
        [
          createId('payrec'),
          userId,
          planId,
          method,
          amountTzs,
          currency,
          normalizedReference,
          note,
          recordedByUserId,
          now,
        ],
      );
      return paymentRecordFromRow(result.rows[0]);
    } catch (error) {
      if (error?.code === '23505') {
        const conflict = new Error('A payment with this reference already exists.');
        conflict.code = 'DUPLICATE_REFERENCE';
        throw conflict;
      }
      throw error;
    }
  }

  async getPaymentRecord(paymentRecordId) {
    const result = await this.pool.query(
      `SELECT * FROM payment_records WHERE id = $1`,
      [paymentRecordId],
    );
    return result.rows[0] ? paymentRecordFromRow(result.rows[0]) : null;
  }

  // For the staff review queue: joins in the learner's email/display name so
  // the UI doesn't need a second lookup per row.
  async paymentRecordsForAdmin({ status, userId, limit = 50, offset = 0 } = {}) {
    const safeLimit = Math.max(1, Math.min(200, Number(limit) || 50));
    const safeOffset = Math.max(0, Number(offset) || 0);
    const result = await this.pool.query(
      `SELECT pr.*, u.email AS user_email, u.display_name AS user_display_name,
              COUNT(*) OVER() AS total_count
       FROM payment_records pr
       JOIN users u ON u.id = pr.user_id
       WHERE ($1::text IS NULL OR pr.status = $1)
         AND ($2::text IS NULL OR pr.user_id = $2)
       ORDER BY pr.created_at DESC
       LIMIT $3 OFFSET $4`,
      [status ?? null, userId ?? null, safeLimit, safeOffset],
    );
    const total = Number(result.rows[0]?.total_count ?? 0);
    const records = result.rows.map((row) => ({
      ...paymentRecordFromRow(row),
      userEmail: row.user_email ?? null,
      userDisplayName: row.user_display_name ?? null,
    }));
    return { records, total };
  }

  // Idempotent and transactional: the `FOR UPDATE ... WHERE status='pending'`
  // guard means a concurrent second approval blocks on the row lock, then
  // sees status already 'approved' and returns the existing entitlement
  // instead of minting a second one. The unique index on
  // entitlements.payment_record_id is a second, defense-in-depth guard
  // against the same failure mode.
  async approvePaymentRecord({ paymentRecordId, approvedByUserId, reason = null }) {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      const existing = await client.query(
        `SELECT * FROM payment_records WHERE id = $1 FOR UPDATE`,
        [paymentRecordId],
      );
      if (!existing.rows[0]) {
        await client.query('ROLLBACK');
        return null;
      }
      const record = paymentRecordFromRow(existing.rows[0]);
      if (record.status !== 'pending') {
        const currentEntitlement = await client.query(
          `SELECT * FROM entitlements WHERE payment_record_id = $1`,
          [paymentRecordId],
        );
        await client.query('COMMIT');
        return {
          paymentRecord: record,
          entitlement: currentEntitlement.rows[0]
            ? entitlementFromRow(currentEntitlement.rows[0])
            : null,
        };
      }

      const planResult = await client.query(
        `SELECT title, duration_days FROM plans WHERE id = $1`,
        [record.planId],
      );
      const plan = planResult.rows[0];
      const now = new Date();
      const nowIso = now.toISOString();
      const expiresAtIso = new Date(
        now.getTime() + Number(plan.duration_days) * 24 * 60 * 60 * 1000,
      ).toISOString();

      const updatedRecord = await client.query(
        `UPDATE payment_records
         SET status = 'approved', approved_by = $2, approved_at = $3, updated_at = $3
         WHERE id = $1
         RETURNING *`,
        [paymentRecordId, approvedByUserId, nowIso],
      );

      const entitlementResult = await client.query(
        `INSERT INTO entitlements (
           id, user_id, plan_id, payment_record_id, status, granted_at,
           expires_at, created_at, updated_at
         ) VALUES ($1, $2, $3, $4, 'active', $5, $6, $5, $5)
         RETURNING *`,
        [
          createId('ent'),
          record.userId,
          record.planId,
          record.id,
          nowIso,
          expiresAtIso,
        ],
      );

      await client.query(
        `UPDATE users
         SET account_status = 'active', subscription_plan = $2,
             subscription_started_at = $3, updated_at = $3
         WHERE id = $1`,
        [record.userId, plan.title, nowIso],
      );

      // created_at is deliberately left to the column's own DEFAULT now()
      // rather than the JS-computed nowIso: approve and reverse each run in
      // their own transaction, and two events can land in the same
      // millisecond under JS Date precision, which breaks the ORDER BY
      // created_at DESC tiebreak in auditEventsFor. Postgres's own
      // transaction timestamp has finer precision and avoids that tie.
      await client.query(
        `INSERT INTO audit_events (
           id, actor_user_id, action, target_type, target_id,
           previous_status, new_status, reason
         ) VALUES ($1, $2, 'payment_approved', 'payment_record', $3, 'pending', 'approved', $4)`,
        [createId('audit'), approvedByUserId, record.id, reason],
      );

      await client.query('COMMIT');
      return {
        paymentRecord: paymentRecordFromRow(updatedRecord.rows[0]),
        entitlement: entitlementFromRow(entitlementResult.rows[0]),
      };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  // Idempotent for the same reason as approvePaymentRecord: reversing an
  // already-reversed record returns the current state under lock rather than
  // erroring or double-writing audit history.
  async reversePaymentRecord({ paymentRecordId, actorUserId, reason = null }) {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      const existing = await client.query(
        `SELECT * FROM payment_records WHERE id = $1 FOR UPDATE`,
        [paymentRecordId],
      );
      if (!existing.rows[0]) {
        await client.query('ROLLBACK');
        return null;
      }
      const record = paymentRecordFromRow(existing.rows[0]);
      if (record.status !== 'approved') {
        await client.query('COMMIT');
        return { paymentRecord: record, entitlement: null };
      }

      const now = new Date().toISOString();
      const updatedRecord = await client.query(
        `UPDATE payment_records
         SET status = 'reversed', reversed_by = $2, reversed_at = $3, updated_at = $3
         WHERE id = $1
         RETURNING *`,
        [paymentRecordId, actorUserId, now],
      );
      const updatedEntitlement = await client.query(
        `UPDATE entitlements
         SET status = 'revoked', revoked_at = $2, updated_at = $2
         WHERE payment_record_id = $1 AND status = 'active'
         RETURNING *`,
        [paymentRecordId, now],
      );

      // A learner can in principle hold more than one entitlement (e.g. two
      // approvals in quick succession); reversing one must not silently keep
      // showing its plan as active once it's the only one left standing.
      const remaining = await client.query(
        `SELECT e.granted_at, p.title
         FROM entitlements e
         JOIN plans p ON p.id = e.plan_id
         WHERE e.user_id = $1
           AND e.status = 'active'
           AND e.expires_at > now()
         ORDER BY e.granted_at DESC
         LIMIT 1`,
        [record.userId],
      );
      if (remaining.rows[0]) {
        await client.query(
          `UPDATE users
           SET account_status = 'active', subscription_plan = $2,
               subscription_started_at = $3, updated_at = $4
           WHERE id = $1`,
          [record.userId, remaining.rows[0].title, remaining.rows[0].granted_at, now],
        );
      } else {
        await client.query(
          `UPDATE users
           SET account_status = 'suspended', subscription_plan = NULL,
               subscription_started_at = NULL, updated_at = $2
           WHERE id = $1`,
          [record.userId, now],
        );
      }

      await client.query(
        `INSERT INTO audit_events (
           id, actor_user_id, action, target_type, target_id,
           previous_status, new_status, reason
         ) VALUES ($1, $2, 'payment_reversed', 'payment_record', $3, 'approved', 'reversed', $4)`,
        [createId('audit'), actorUserId, record.id, reason],
      );

      await client.query('COMMIT');
      return {
        paymentRecord: paymentRecordFromRow(updatedRecord.rows[0]),
        entitlement: updatedEntitlement.rows[0]
          ? entitlementFromRow(updatedEntitlement.rows[0])
          : null,
      };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async entitlementsForUser(userId) {
    const result = await this.pool.query(
      `SELECT * FROM entitlements WHERE user_id = $1 ORDER BY created_at DESC`,
      [userId],
    );
    return result.rows.map(entitlementFromRow);
  }

  async hasActiveEntitlement(userId) {
    const result = await this.pool.query(
      `SELECT 1 FROM entitlements
       WHERE user_id = $1 AND status = 'active' AND expires_at > now()
       LIMIT 1`,
      [userId],
    );
    return result.rows.length > 0;
  }

  async reconcileUserEntitlements(userId) {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      await client.query(
        `UPDATE entitlements
         SET status = 'expired', updated_at = now()
         WHERE user_id = $1 AND status = 'active' AND expires_at <= now()`,
        [userId],
      );
      const active = await client.query(
        `SELECT e.granted_at, p.title
         FROM entitlements e
         JOIN plans p ON p.id = e.plan_id
         WHERE e.user_id = $1
           AND e.status = 'active'
           AND e.expires_at > now()
         ORDER BY e.granted_at DESC
         LIMIT 1`,
        [userId],
      );
      if (active.rows[0]) {
        await client.query(
          `UPDATE users
           SET account_status = 'active', subscription_plan = $2,
               subscription_started_at = $3, updated_at = now()
           WHERE id = $1
             AND (
               account_status <> 'active'
               OR subscription_plan IS DISTINCT FROM $2
               OR subscription_started_at IS DISTINCT FROM $3
             )`,
          [userId, active.rows[0].title, active.rows[0].granted_at],
        );
      } else {
        await client.query(
          `UPDATE users
           SET account_status = 'suspended', subscription_plan = NULL,
               subscription_started_at = NULL, updated_at = now()
           WHERE id = $1 AND account_status = 'active'`,
          [userId],
        );
      }
      const userResult = await client.query(
        `SELECT id, phone_number, email, auth_user_id, account_status, role,
                subscription_plan, subscription_started_at,
                display_name, preferred_location, created_at, updated_at
         FROM users WHERE id = $1`,
        [userId],
      );
      await client.query('COMMIT');
      return userResult.rows[0] ? userFromRow(userResult.rows[0]) : null;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async auditEventsFor({ targetType, targetId }) {
    const result = await this.pool.query(
      `SELECT * FROM audit_events WHERE target_type = $1 AND target_id = $2
       ORDER BY created_at DESC`,
      [targetType, targetId],
    );
    return result.rows.map(auditEventFromRow);
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
         AND l.lesson_type IN ('reading', 'video')
         AND (
           (l.lesson_type = 'reading'
             AND NULLIF(BTRIM(l.body_sw), '') IS NOT NULL)
           OR
           (l.lesson_type = 'video'
             AND EXISTS (
               SELECT 1
               FROM lesson_resources lr
               WHERE lr.lesson_id = l.id
                 AND lr.resource_type = 'video'
                 AND lr.status = 'published'
                 AND (lr.external_url IS NOT NULL OR lr.storage_path IS NOT NULL)
             ))
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

  async lessonSourceDocumentUrl(lessonId) {
    if (process.env.AJE_STORE !== 'supabase') return null;
    const result = await this.pool.query(
      `SELECT sd.storage_bucket, sd.storage_path
       FROM lessons l
       JOIN course_modules m ON m.id = l.module_id
       JOIN courses c ON c.id = m.course_id
       JOIN content_source_links csl
         ON csl.content_type = 'lesson' AND csl.content_id = l.id
       JOIN source_segments ss ON ss.id = csl.source_segment_id
       JOIN source_documents sd ON sd.id = ss.source_document_id
       WHERE l.id = $1
         AND l.lesson_type = 'reading'
         AND l.status = 'published'
         AND m.status = 'published'
         AND c.status = 'published'
         AND csl.link_status = 'linked'
         AND ss.review_status IN ('approved', 'published')
         AND sd.processing_status IN ('approved', 'published')
         AND sd.storage_bucket = 'source-documents'
         AND (
           sd.source_kind = 'pdf'
           OR LOWER(sd.file_name) LIKE '%.pdf'
           OR LOWER(sd.source_type) LIKE '%pdf%'
         )
       ORDER BY csl.created_at
       LIMIT 1`,
      [lessonId],
    );
    const document = result.rows[0];
    if (!document?.storage_path) return null;

    const supabaseUrl = process.env.SUPABASE_URL;
    const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
    if (!supabaseUrl || !serviceRoleKey) return null;
    const response = await fetch(
      `${supabaseUrl}/storage/v1/object/sign/${encodeURIComponent(document.storage_bucket)}/${encodeStoragePath(document.storage_path)}`,
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
    if (process.env.AJE_STORE === 'supabase') {
      const result = await this.pool.query(
        `SELECT
           c.id::text AS course_id,
           c.code AS course_code,
           c.title_sw AS course_title,
           COALESCE(c.description_sw, c.summary_sw, '') AS course_description,
           COALESCE(c.delivery_type, 'text') AS delivery_type,
           c.status AS course_status,
           c.updated_at AS course_updated_at,
           m.id::text AS module_id,
           m.title_sw AS module_title,
           m.sort_order AS module_order,
           m.status::text AS module_status,
           l.id::text AS lesson_id,
           l.title_sw AS lesson_title,
           l.body_sw AS lesson_body,
           l.lesson_type,
           l.duration_minutes,
           l.sort_order AS lesson_order,
           l.status::text AS lesson_status,
           l.source_link_status::text AS lesson_link_status,
           (
             SELECT lr.external_url
             FROM lesson_resources lr
             WHERE lr.lesson_id = l.id
               AND lr.resource_type = 'video'
             ORDER BY
               CASE WHEN lr.status = 'published' THEN 0 ELSE 1 END,
               lr.created_at
             LIMIT 1
           ) AS video_url,
           (
             SELECT lr.storage_path
             FROM lesson_resources lr
             WHERE lr.lesson_id = l.id
               AND lr.resource_type = 'video'
             ORDER BY
               CASE WHEN lr.status = 'published' THEN 0 ELSE 1 END,
               lr.created_at
             LIMIT 1
           ) AS video_storage_path,
           EXISTS (
             SELECT 1
             FROM lesson_resources lr
             WHERE lr.lesson_id = l.id
               AND lr.resource_type = 'video'
               AND (lr.external_url IS NOT NULL OR lr.storage_path IS NOT NULL)
           ) AS has_video,
           EXISTS (
             SELECT 1
             FROM content_source_links csl
             JOIN source_segments ss ON ss.id = csl.source_segment_id
             JOIN source_documents sd ON sd.id = ss.source_document_id
             WHERE csl.content_type = 'lesson'
               AND csl.content_id = l.id
               AND csl.link_status = 'linked'
               AND ss.review_status IN ('approved', 'published')
               AND sd.processing_status IN ('approved', 'published')
           ) AS has_source_link,
           EXISTS (
             SELECT 1
             FROM grounding_facts gf
             JOIN source_segments ss ON ss.id = gf.source_segment_id
             JOIN source_documents sd ON sd.id = ss.source_document_id
             WHERE (
                 gf.lesson_id = l.id
                 OR (gf.lesson_id IS NULL AND gf.course_id = c.id)
               )
               AND gf.status = 'published'
               AND gf.risk_level <> 'high'
               AND ss.review_status IN ('approved', 'published')
               AND sd.processing_status IN ('approved', 'published')
           ) AS has_grounding
         FROM courses c
         LEFT JOIN course_modules m ON m.course_id = c.id
         LEFT JOIN lessons l ON l.module_id = m.id
         ORDER BY c.updated_at DESC, c.sort_order, c.code,
                  m.sort_order, l.sort_order`,
      );
      return structuredContentCourseRecords(result.rows);
    }
    const result = await this.pool.query(
      `SELECT id, status, payload, updated_at
       FROM content_courses
       ORDER BY updated_at DESC`,
    );
    return result.rows.map(contentCourseFromRow);
  }

  async upsertContentCourse({
    course,
    status = 'approved',
    replaceCurriculum = false,
    baseUpdatedAt = null,
    createOnly = false,
  }) {
    const normalizedCourse = normalizeApprovedCourse(course);
    if (process.env.AJE_STORE === 'supabase') {
      if (createOnly) {
        const curriculum = await this.saveCourseCurriculum(
          normalizedCourse.id,
          {
            createIfMissing: true,
            failIfExists: true,
            status,
            title: normalizedCourse.title,
            description: normalizedCourse.description,
            deliveryType: normalizedCourse.lessons.some(
              (lesson) => lesson.type === 'video',
            )
              ? 'video'
              : 'text',
            lessons: normalizedCourse.lessons.map((lesson) => ({
              id: lesson.id,
              moduleId: lesson.moduleId ?? null,
              moduleKey: lesson.moduleKey ?? null,
              moduleTitle: lesson.moduleTitle ?? 'Somo',
              title: lesson.title,
              type: lesson.type,
              meta: lesson.meta,
              body: lesson.description,
              durationMinutes:
                lesson.durationMinutes ?? durationFromMeta(lesson.meta),
              videoUrl: lesson.resourceUrl ?? null,
              videoPath: lesson.videoPath ?? null,
            })),
          },
        );
        return contentCourseRecordFromCurriculum(curriculum);
      }
      if (!replaceCurriculum) {
        const structuredStatus =
          status === 'approved' ? 'published' : 'draft';
        const result = await this.pool.query(
          `UPDATE courses
           SET title_sw = $2,
               description_sw = $3,
               status = $4::content_status,
               published_at = CASE
                 WHEN $4 = 'published' THEN COALESCE(published_at, NOW())
                 ELSE NULL
               END,
               updated_at = NOW()
           WHERE code = $1
           RETURNING code, status, updated_at`,
          [
            normalizedCourse.id,
            normalizedCourse.title,
            normalizedCourse.description,
            structuredStatus,
          ],
        );
        if (result.rows.length === 0) {
          const curriculum = await this.saveCourseCurriculum(
            normalizedCourse.id,
            {
              createIfMissing: true,
              status,
              title: normalizedCourse.title,
              description: normalizedCourse.description,
              deliveryType: normalizedCourse.lessons.some(
                (lesson) => lesson.type === 'video',
              )
                ? 'video'
                : 'text',
              lessons: normalizedCourse.lessons.map((lesson) => ({
                id: lesson.id,
                moduleId: lesson.moduleId ?? null,
                moduleKey: lesson.moduleKey ?? null,
                moduleTitle: lesson.moduleTitle ?? 'Somo',
                title: lesson.title,
                type: lesson.type,
                meta: lesson.meta,
                body: lesson.description,
                durationMinutes:
                  lesson.durationMinutes ?? durationFromMeta(lesson.meta),
                videoUrl: lesson.resourceUrl ?? null,
              })),
            },
          );
          return contentCourseRecordFromCurriculum(curriculum);
        }
        return this.contentCoursesForAdmin().then((records) => {
          const record = records.find(
            (candidate) => candidate.id === normalizedCourse.id,
          );
          if (!record) {
            throw new Error('Updated course could not be loaded.');
          }
          return record;
        });
      }
      const curriculum = await this.saveCourseCurriculum(
        normalizedCourse.id,
        {
          baseUpdatedAt,
          status,
          title: normalizedCourse.title,
          description: normalizedCourse.description,
          deliveryType: normalizedCourse.lessons.some(
            (lesson) => lesson.type === 'video',
          )
            ? 'video'
            : 'text',
          badge: normalizedCourse.badge,
          icon: normalizedCourse.icon,
          imageUrl: normalizedCourse.imageUrl,
          lessons: normalizedCourse.lessons.map((lesson) => ({
            id: lesson.id,
            moduleId: lesson.moduleId ?? null,
            moduleKey: lesson.moduleKey ?? null,
            moduleTitle: lesson.moduleTitle ?? 'Somo',
            title: lesson.title,
            type: lesson.type,
            meta: lesson.meta,
            body: lesson.description,
            durationMinutes:
              lesson.durationMinutes ?? durationFromMeta(lesson.meta),
            videoUrl: lesson.resourceUrl ?? null,
            videoPath: lesson.videoPath ?? null,
          })),
        },
      );
      return contentCourseRecordFromCurriculum(curriculum);
    }
    const result = await this.pool.query(
      `INSERT INTO content_courses (id, status, payload, updated_at)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (id) ${createOnly
    ? 'DO NOTHING'
    : `DO UPDATE
       SET status = EXCLUDED.status,
           payload = EXCLUDED.payload,
           updated_at = EXCLUDED.updated_at`}
       RETURNING id, status, payload, updated_at`,
      [
        normalizedCourse.id,
        status,
        JSON.stringify(normalizedCourse),
        new Date().toISOString(),
      ],
    );
    if (createOnly && result.rows.length === 0) {
      const conflict = new Error('A course with this code already exists.');
      conflict.code = 'COURSE_ALREADY_EXISTS';
      throw conflict;
    }
    return contentCourseFromRow(result.rows[0]);
  }

  /**
   * Full module/lesson tree for one course, with a per-lesson learner-visibility
   * verdict. Unlike `approvedContentCourses`, this includes draft and
   * unlinked rows so an admin can see and fix what is blocking a lesson.
   */
  async courseCurriculum(courseCode) {
    if (process.env.AJE_STORE === 'supabase') {
      return this.#structuredCourseCurriculum(courseCode);
    }
    const result = await this.pool.query(
      `SELECT id, status, payload, updated_at
       FROM content_courses
       WHERE id = $1`,
      [courseCode],
    );
    const row = result.rows[0];
    if (!row) {
      throw new Error('Course was not found.');
    }
    return contentCourseToCurriculum(row);
  }

  async #structuredCourseCurriculum(courseCode) {
    const result = await this.pool.query(
      `SELECT
         c.id::text AS course_id,
         c.code AS course_code,
         c.title_sw AS course_title,
         COALESCE(c.description_sw, c.summary_sw, '') AS course_description,
         COALESCE(c.delivery_type, 'text') AS delivery_type,
         c.status::text AS course_status,
         c.updated_at AS course_updated_at,
         m.id::text AS module_id,
         m.title_sw AS module_title,
         m.sort_order AS module_order,
         m.status::text AS module_status,
         l.id::text AS lesson_id,
         l.title_sw AS lesson_title,
         l.body_sw AS lesson_body,
         l.lesson_type,
         l.duration_minutes,
         l.sort_order AS lesson_order,
         l.status::text AS lesson_status,
         l.source_link_status::text AS lesson_link_status,
         (
           SELECT lr.external_url
           FROM lesson_resources lr
           WHERE lr.lesson_id = l.id
             AND lr.resource_type = 'video'
           ORDER BY
             CASE WHEN lr.status = 'published' THEN 0 ELSE 1 END,
             lr.created_at
           LIMIT 1
         ) AS video_url,
         (
           SELECT lr.storage_path
           FROM lesson_resources lr
           WHERE lr.lesson_id = l.id
             AND lr.resource_type = 'video'
           ORDER BY
             CASE WHEN lr.status = 'published' THEN 0 ELSE 1 END,
             lr.created_at
           LIMIT 1
         ) AS video_storage_path,
         EXISTS (
           SELECT 1
           FROM content_source_links csl
           JOIN source_segments ss ON ss.id = csl.source_segment_id
           JOIN source_documents sd ON sd.id = ss.source_document_id
           WHERE csl.content_type = 'lesson'
             AND csl.content_id = l.id
             AND csl.link_status = 'linked'
             AND ss.review_status IN ('approved', 'published')
             AND sd.processing_status IN ('approved', 'published')
         ) AS has_source_link,
         EXISTS (
           SELECT 1
           FROM grounding_facts gf
           JOIN source_segments ss ON ss.id = gf.source_segment_id
           JOIN source_documents sd ON sd.id = ss.source_document_id
           WHERE (gf.lesson_id = l.id OR (gf.lesson_id IS NULL AND gf.course_id = c.id))
             AND gf.status = 'published'
             AND gf.risk_level <> 'high'
             AND ss.review_status IN ('approved', 'published')
             AND sd.processing_status IN ('approved', 'published')
         ) AS has_grounding
       FROM courses c
       LEFT JOIN course_modules m ON m.course_id = c.id
       LEFT JOIN lessons l ON l.module_id = m.id
       WHERE c.code = $1
       ORDER BY m.sort_order, m.title_sw, l.sort_order`,
      [courseCode],
    );
    if (result.rows.length === 0) {
      throw new Error('Course was not found in the live content catalog.');
    }
    return structuredCourseCurriculumFromRows(result.rows);
  }

  /**
   * Replaces a course's module/lesson tree in one transaction. Modules and
   * lessons are matched by id when present; anything else is treated as new.
   * Existing rows not present in the incoming lesson/module lists are deleted
   * (cascading to their lesson_resources and grounding_facts).
   */
  async saveCourseCurriculum(courseCode, curriculum) {
    if (process.env.AJE_STORE === 'supabase') {
      return this.#saveStructuredCourseCurriculum(courseCode, curriculum);
    }
    const status = curriculum.status === 'approved' ? 'approved' : 'draft';
    const outcomes = [
      ...new Set(
        curriculum.lessons
          .map((lesson) => (lesson.moduleTitle ?? '').trim())
          .filter((title) => title.length > 0),
      ),
    ];
    const course = normalizeApprovedCourse({
      id: courseCode,
      title: curriculum.title,
      description: curriculum.description,
      badge: curriculum.badge,
      icon: curriculum.icon,
      progress: 0,
      imageUrl: curriculum.imageUrl,
      outcomes,
      lessons: curriculum.lessons.map((lesson) => ({
        id: lesson.id || undefined,
        title: lesson.title,
        type: lesson.type,
        meta: lesson.meta,
        description: lesson.body,
        resourceUrl: lesson.videoUrl || undefined,
        videoPath: lesson.videoPath || undefined,
        isPremium: false,
        isCompleted: false,
      })),
    });
    await this.upsertContentCourse({ course, status });
    return this.courseCurriculum(courseCode);
  }

  async #saveStructuredCourseCurriculum(courseCode, curriculum) {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      const courseResult = await client.query(
        `SELECT id, status::text AS status, updated_at
         FROM courses
         WHERE code = $1
         FOR UPDATE`,
        [courseCode],
      );
      let courseRow = courseResult.rows[0];
      if (courseRow && curriculum.failIfExists) {
        const conflict = new Error('A course with this code already exists.');
        conflict.code = 'COURSE_ALREADY_EXISTS';
        throw conflict;
      }
      if (!courseRow) {
        if (!curriculum.createIfMissing) {
          throw new Error('Course was not found in the live content catalog.');
        }
        // import_source is deliberately passed as a bare literal. The live
        // courses.import_source is a text column and no import_source enum
        // type exists, so casting it made every new-course insert fail with
        // 'type "import_source" does not exist'. An uncast literal coerces to
        // whichever type the column actually has.
        const insertedCourse = await client.query(
          `INSERT INTO courses
             (code, title_sw, description_sw, delivery_type, status,
              import_source, source_link_status, sort_order)
           VALUES ($1, $2, $3, $4, 'draft'::content_status,
                   'manual',
                   'pending_review'::source_link_status,
                   COALESCE((SELECT MAX(sort_order) + 1 FROM courses), 0))
           RETURNING id, status::text AS status, updated_at`,
          [
            courseCode,
            curriculum.title,
            curriculum.description,
            curriculum.deliveryType === 'video' ? 'video' : 'text',
          ],
        );
        courseRow = insertedCourse.rows[0];
      }
      const courseId = courseRow.id;
      if (
        curriculum.baseUpdatedAt &&
        new Date(courseRow.updated_at).getTime() !==
          new Date(curriculum.baseUpdatedAt).getTime()
      ) {
        const conflict = new Error(
          'Kozi imebadilishwa na msimamizi mwingine. Pakia upya kabla ya kuhifadhi.',
        );
        conflict.code = 'CURRICULUM_CONFLICT';
        throw conflict;
      }
      const structuredStatus =
        curriculum.status === 'approved' ? 'published' : 'draft';

      await client.query(
        `UPDATE courses
         SET title_sw = $2,
             description_sw = $3,
             delivery_type = $4,
             status = $5::content_status,
             source_link_status = CASE
               WHEN $5 = 'published' THEN 'linked'::source_link_status
               ELSE 'pending_review'::source_link_status
             END,
             published_at = CASE
               WHEN $5 = 'published' THEN COALESCE(published_at, NOW())
               ELSE NULL
             END,
             updated_at = NOW()
         WHERE id = $1`,
        [
          courseId,
          curriculum.title,
          curriculum.description,
          curriculum.deliveryType === 'video' ? 'video' : 'text',
          structuredStatus,
        ],
      );

      const existingModules = await client.query(
        `SELECT id::text, code, title_sw, status::text AS status
         FROM course_modules
         WHERE course_id = $1`,
        [courseId],
      );
      const existingModuleIds = new Set(
        existingModules.rows.map((row) => row.id),
      );
      const existingModuleTitles = new Map(
        existingModules.rows.map((row) => [row.id, row.title_sw]),
      );
      const existingCourseLessons = await client.query(
        `SELECT
           l.id::text,
           l.module_id::text,
           l.body_sw,
           l.lesson_type::text,
           (
             SELECT lr.external_url
             FROM lesson_resources lr
             WHERE lr.lesson_id = l.id
               AND lr.resource_type = 'video'
             ORDER BY
               CASE WHEN lr.status = 'published' THEN 0 ELSE 1 END,
               lr.created_at
             LIMIT 1
           ) AS video_url,
           (
             SELECT lr.storage_path
             FROM lesson_resources lr
             WHERE lr.lesson_id = l.id
               AND lr.resource_type = 'video'
             ORDER BY
               CASE WHEN lr.status = 'published' THEN 0 ELSE 1 END,
               lr.created_at
             LIMIT 1
           ) AS video_storage_path
         FROM lessons l
         JOIN course_modules m ON m.id = l.module_id
         WHERE m.course_id = $1`,
        [courseId],
      );
      const existingLessonModules = new Map(
        existingCourseLessons.rows.map((row) => [row.id, row.module_id]),
      );
      const existingLessonsById = new Map(
        existingCourseLessons.rows.map((row) => [row.id, row]),
      );

      // Group incoming lessons by the module they belong to, preserving order.
      const moduleGroups = new Map();
      curriculum.lessons.forEach((lesson, index) => {
        const explicitModuleId =
          lesson.moduleId && existingModuleIds.has(lesson.moduleId)
            ? lesson.moduleId
            : null;
        const legacyModuleId =
          lesson.id && existingLessonModules.has(lesson.id)
            ? existingLessonModules.get(lesson.id)
            : null;
        const resolvedModuleId = explicitModuleId ?? legacyModuleId;
        const requestedTitle = (lesson.moduleTitle ?? '').trim();
        const resolvedTitle =
          explicitModuleId || !legacyModuleId
            ? requestedTitle || 'Somo'
            : existingModuleTitles.get(legacyModuleId) || requestedTitle || 'Somo';
        const key = resolvedModuleId
          ? resolvedModuleId
          : `new:${lesson.moduleKey ?? resolvedTitle}`;
        if (!moduleGroups.has(key)) {
          moduleGroups.set(key, {
            moduleId: resolvedModuleId,
            title: resolvedTitle,
            order: moduleGroups.size,
            lessons: [],
          });
        }
        moduleGroups.get(key).lessons.push({ ...lesson, sortOrder: index });
      });

      const keptModuleIds = new Set();
      let moduleOrder = 0;
      for (const group of moduleGroups.values()) {
        let moduleId = group.moduleId;
        if (moduleId) {
          await client.query(
            `UPDATE course_modules
             SET title_sw = $2, sort_order = $3, updated_at = NOW()
             WHERE id = $1`,
            [moduleId, group.title, moduleOrder],
          );
        } else {
          const inserted = await client.query(
            `INSERT INTO course_modules
               (course_id, code, title_sw, sort_order, status, source_link_status)
             VALUES ($1, $2, $3, $4, 'draft'::content_status,
                     'pending_review'::source_link_status)
             RETURNING id::text`,
            [
              courseId,
              createId('MOD'),
              group.title,
              moduleOrder,
            ],
          );
          moduleId = inserted.rows[0].id;
        }
        keptModuleIds.add(moduleId);
        moduleOrder += 1;

        const existingLessons = await client.query(
          `SELECT id::text FROM lessons WHERE module_id = $1`,
          [moduleId],
        );
        const existingLessonIds = new Set(
          existingLessons.rows.map((row) => row.id),
        );
        const keptLessonIds = new Set();

        for (const lesson of group.lessons) {
          const lessonType = lesson.type === 'video' ? 'video' : 'reading';
          let lessonId =
            lesson.id && existingLessonIds.has(lesson.id) ? lesson.id : null;
          if (lessonId) {
            const existingLesson = existingLessonsById.get(lessonId);
            const requestedBody = lesson.body || null;
            const uploadedVideoPath = (lesson.videoPath ?? '').trim() || null;
            const requestedVideoUrl = uploadedVideoPath
                ? null
                : (lesson.videoUrl ?? '').trim() || null;
            const lessonContentChanged =
              (existingLesson?.body_sw ?? null) !== requestedBody ||
              existingLesson?.lesson_type !== lessonType;
            // A newly uploaded or re-pointed video sends the lesson back
            // through source review, exactly like edited body text.
            const videoChanged =
              lessonType === 'video' &&
              (uploadedVideoPath != null || requestedVideoUrl != null) &&
              ((existingLesson?.video_url ?? null) !== requestedVideoUrl ||
                (existingLesson?.video_storage_path ?? null) !==
                  uploadedVideoPath);
            const requiresReview = lessonContentChanged || videoChanged;
            await client.query(
              `UPDATE lessons
               SET title_sw = $2, body_sw = $3, lesson_type = $4,
                   duration_minutes = $5, sort_order = $6,
                   status = CASE
                     WHEN $7 THEN 'draft'::content_status
                     ELSE status
                   END,
                   source_link_status = CASE
                     WHEN $7 THEN 'pending_review'::source_link_status
                     ELSE source_link_status
                   END,
                   updated_at = NOW()
               WHERE id = $1`,
              [
                lessonId,
                lesson.title,
                requestedBody,
                lessonType,
                lesson.durationMinutes || null,
                lesson.sortOrder,
                requiresReview,
              ],
            );
            if (requiresReview) {
              await client.query(
                `UPDATE content_source_links
                 SET link_status = 'pending_review'::source_link_status
                 WHERE content_type = 'lesson' AND content_id = $1`,
                [lessonId],
              );
            }
          } else {
            const inserted = await client.query(
              `INSERT INTO lessons
                 (module_id, code, title_sw, body_sw, lesson_type,
                  duration_minutes, sort_order, status, source_link_status)
               VALUES ($1, $2, $3, $4, $5, $6, $7,
                       'draft'::content_status,
                       'pending_review'::source_link_status)
               RETURNING id::text`,
              [
                moduleId,
                createId('LSN'),
                lesson.title,
                lesson.body || null,
                lessonType,
                lesson.durationMinutes || null,
                lesson.sortOrder,
              ],
            );
            lessonId = inserted.rows[0].id;
          }
          keptLessonIds.add(lessonId);

          // A lesson video arrives either as an uploaded object key
          // (`videoPath`, stored in the private bucket and signed at playback)
          // or as a pasted external link (`videoUrl`). An upload wins when both
          // are present, and setting one clears the other so the two sources
          // can never disagree.
          const requestedVideoPath = (lesson.videoPath ?? '').trim() || null;
          const requestedVideoUrl = requestedVideoPath
              ? null
              : (lesson.videoUrl ?? '').trim() || null;
          if (lessonType === 'video' && (requestedVideoPath || requestedVideoUrl)) {
            const existingLesson = existingLessonsById.get(lessonId);
            const videoChanged =
              existingLesson != null &&
              ((existingLesson.video_url ?? null) !== requestedVideoUrl ||
                (existingLesson.video_storage_path ?? null) !==
                  requestedVideoPath);
            const existingResource = await client.query(
              `UPDATE lesson_resources
               SET external_url = $2,
                   storage_path = $3,
                   title_sw = $4,
                   status = CASE
                     WHEN $5 THEN 'draft'::content_status
                     ELSE status
                   END,
                   updated_at = NOW()
               WHERE id = (
                 SELECT id
                 FROM lesson_resources
                 WHERE lesson_id = $1 AND resource_type = 'video'
                 ORDER BY
                   CASE WHEN status = 'published' THEN 0 ELSE 1 END,
                   created_at
                 LIMIT 1
               )
               RETURNING id`,
              [
                lessonId,
                requestedVideoUrl,
                requestedVideoPath,
                lesson.title,
                videoChanged,
              ],
            );
            if (existingResource.rows.length === 0) {
              await client.query(
                `INSERT INTO lesson_resources
                   (lesson_id, resource_type, external_url, storage_path,
                    title_sw, status)
                 VALUES ($1, 'video', $2, $3, $4, 'draft'::content_status)`,
                [
                  lessonId,
                  requestedVideoUrl,
                  requestedVideoPath,
                  lesson.title,
                ],
              );
            }
          } else {
            // No video in the payload means the editor removed it, or the
            // lesson is no longer a video lesson. The client always round-trips
            // videoPath/videoUrl for a video it is keeping, so an absent one is
            // a deliberate removal. Without this the row survived: the object
            // stayed in the bucket and came back as soon as the lesson was set
            // to video again.
            await client.query(
              `DELETE FROM lesson_resources
               WHERE lesson_id = $1 AND resource_type = 'video'`,
              [lessonId],
            );
          }
        }

        const removedLessonIds = [...existingLessonIds].filter(
          (id) => !keptLessonIds.has(id),
        );
        if (removedLessonIds.length > 0) {
          await client.query(
            `DELETE FROM content_source_links
             WHERE content_type = 'lesson' AND content_id = ANY($1::uuid[])`,
            [removedLessonIds],
          );
          await client.query(`DELETE FROM lessons WHERE id = ANY($1::uuid[])`, [
            removedLessonIds,
          ]);
        }
      }

      const removedModuleIds = [...existingModuleIds].filter(
        (id) => !keptModuleIds.has(id),
      );
      if (removedModuleIds.length > 0) {
        await client.query(
          `DELETE FROM content_source_links
           WHERE content_type = 'lesson' AND content_id IN (
             SELECT id FROM lessons WHERE module_id = ANY($1::uuid[])
           )`,
          [removedModuleIds],
        );
        await client.query(
          `DELETE FROM course_modules WHERE id = ANY($1::uuid[])`,
          [removedModuleIds],
        );
      }

      // AJE's only publisher is the trusted admin who authored the material.
      // Publishing therefore applies to the complete curriculum in one
      // transaction; source documents remain optional attribution metadata,
      // not a second-person approval gate.
      await client.query(
        `UPDATE course_modules
         SET status = $2::content_status,
             source_link_status = CASE
               WHEN $2 = 'published' THEN 'linked'::source_link_status
               ELSE 'pending_review'::source_link_status
             END,
             published_at = CASE
               WHEN $2 = 'published' THEN COALESCE(published_at, NOW())
               ELSE NULL
             END,
             updated_at = NOW()
         WHERE course_id = $1`,
        [courseId, structuredStatus],
      );
      await client.query(
        `UPDATE lessons l
         SET status = $2::content_status,
             source_link_status = CASE
               WHEN $2 = 'published' THEN 'linked'::source_link_status
               ELSE 'pending_review'::source_link_status
             END,
             published_at = CASE
               WHEN $2 = 'published' THEN COALESCE(l.published_at, NOW())
               ELSE NULL
             END,
             updated_at = NOW()
         FROM course_modules m
         WHERE m.id = l.module_id AND m.course_id = $1`,
        [courseId, structuredStatus],
      );
      await client.query(
        `UPDATE lesson_resources lr
         SET status = $2::content_status,
             updated_at = NOW()
         FROM lessons l
         JOIN course_modules m ON m.id = l.module_id
         WHERE lr.lesson_id = l.id AND m.course_id = $1`,
        [courseId, structuredStatus],
      );

      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
    return this.courseCurriculum(courseCode);
  }

  async sourceSegmentsForAdmin({ search = '', limit = 50 } = {}) {
    if (process.env.AJE_STORE !== 'supabase') return [];
    const normalizedSearch = String(search).trim();
    const result = await this.pool.query(
      `SELECT
         ss.id::text,
         sd.id::text AS document_id,
         sd.title AS document_title,
         ss.section_title,
         ss.page_start,
         ss.page_end,
         ss.time_start_seconds,
         ss.time_end_seconds,
         LEFT(ss.content_sw, 500) AS content_preview
       FROM source_segments ss
       JOIN source_documents sd ON sd.id = ss.source_document_id
       WHERE ss.review_status IN ('approved', 'published')
         AND sd.processing_status IN ('approved', 'published')
         AND (
           $1 = ''
           OR sd.title ILIKE '%' || $1 || '%'
           OR COALESCE(ss.section_title, '') ILIKE '%' || $1 || '%'
           OR ss.content_sw ILIKE '%' || $1 || '%'
         )
       ORDER BY sd.title, ss.segment_order
       LIMIT $2`,
      [normalizedSearch, Math.min(Math.max(Number(limit) || 50, 1), 100)],
    );
    return result.rows.map((row) => ({
      id: row.id,
      documentId: row.document_id,
      documentTitle: row.document_title,
      sectionTitle: row.section_title ?? null,
      locationLabel:
        row.page_start != null
          ? `Kurasa ${row.page_start}-${row.page_end}`
          : row.time_start_seconds != null
            ? `Sekunde ${row.time_start_seconds}-${row.time_end_seconds}`
            : '',
      contentPreview: row.content_preview ?? '',
    }));
  }

  async approveLessonSource({
    lessonId,
    sourceSegmentId,
    evidenceNote,
    groundingFact,
    reviewerActorId = null,
  }) {
    if (process.env.AJE_STORE !== 'supabase') {
      throw new Error('Source review is only available in Supabase mode.');
    }
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      const target = await client.query(
        `SELECT
           l.id AS lesson_id,
           m.id AS module_id,
           c.id AS course_id,
           c.code AS course_code,
           l.lesson_type::text,
           l.body_sw,
           EXISTS (
             SELECT 1
             FROM lesson_resources lr
             WHERE lr.lesson_id = l.id
               AND lr.resource_type = 'video'
               AND (lr.external_url IS NOT NULL OR lr.storage_path IS NOT NULL)
           ) AS has_video,
           ss.id AS source_segment_id,
           sd.id AS source_document_id
         FROM lessons l
         JOIN course_modules m ON m.id = l.module_id
         JOIN courses c ON c.id = m.course_id
         CROSS JOIN source_segments ss
         JOIN source_documents sd ON sd.id = ss.source_document_id
         WHERE l.id = $1
           AND ss.id = $2
           AND ss.review_status IN ('approved', 'published')
           AND sd.processing_status IN ('approved', 'published')
         FOR UPDATE OF l, m, c`,
        [lessonId, sourceSegmentId],
      );
      const row = target.rows[0];
      if (!row) {
        throw new Error(
          'Lesson or approved source segment could not be found.',
        );
      }
      const contentReady =
        (row.lesson_type === 'reading' && Boolean(row.body_sw?.trim())) ||
        (row.lesson_type === 'video' && row.has_video === true);

      await client.query(
        `INSERT INTO content_source_links
           (content_type, content_id, source_segment_id, source_document_id,
            link_status, evidence_note)
         VALUES ('lesson', $1, $2, $3, 'linked'::source_link_status, $4)
         ON CONFLICT (content_type, content_id, source_segment_id)
         DO UPDATE SET
           source_document_id = EXCLUDED.source_document_id,
           link_status = 'linked'::source_link_status,
           evidence_note = EXCLUDED.evidence_note,
           updated_at = NOW()`,
        [
          row.lesson_id,
          row.source_segment_id,
          row.source_document_id,
          evidenceNote,
        ],
      );
      await client.query(
        `INSERT INTO grounding_facts
           (course_id, module_id, lesson_id, source_segment_id, code, fact_sw,
            status, risk_level, import_source, reviewed_at)
         VALUES ($1, $2, $3, $4, $5, $6,
                 'published'::content_status, 'normal'::content_risk_level,
                 'manual', NOW())
         ON CONFLICT (source_segment_id, code)
         DO UPDATE SET
           fact_sw = EXCLUDED.fact_sw,
           status = 'published'::content_status,
           risk_level = 'normal'::content_risk_level,
           reviewed_at = NOW(),
           updated_at = NOW()`,
        [
          row.course_id,
          row.module_id,
          row.lesson_id,
          row.source_segment_id,
          `ADMIN-${row.lesson_id}`,
          groundingFact,
        ],
      );
      if (row.lesson_type === 'video' && row.has_video === true) {
        await client.query(
          `UPDATE lesson_resources
           SET status = 'published'::content_status,
               updated_at = NOW()
           WHERE lesson_id = $1
             AND resource_type = 'video'
             AND (external_url IS NOT NULL OR storage_path IS NOT NULL)`,
          [row.lesson_id],
        );
      }
      await client.query(
        `UPDATE lessons
         SET status = CASE
               WHEN $2 THEN 'published'::content_status
               ELSE status
             END,
             source_link_status = 'linked'::source_link_status,
             published_at = CASE
               WHEN $2 THEN COALESCE(published_at, NOW())
               ELSE published_at
             END,
             updated_at = NOW()
         WHERE id = $1`,
        [row.lesson_id, contentReady],
      );
      await client.query(
        `UPDATE course_modules
         SET status = 'published'::content_status,
             source_link_status = 'linked'::source_link_status,
             published_at = COALESCE(published_at, NOW()),
             updated_at = NOW()
         WHERE id = $1`,
        [row.module_id],
      );
      const updatedCourse = await client.query(
        `UPDATE courses
         SET source_link_status = 'linked'::source_link_status,
             updated_at = NOW()
         WHERE id = $1
         RETURNING updated_at`,
        [row.course_id],
      );
      await client.query(
        `INSERT INTO content_reviews
           (content_type, content_id, status, risk_level, notes, reviewed_at)
         VALUES ('lesson', $1, 'published'::content_status,
                 'normal'::content_risk_level, $2, NOW())`,
        [row.lesson_id, evidenceNote],
      );
      await client.query(
        `INSERT INTO content_change_log
           (content_type, content_id, action, metadata)
         VALUES ('lesson', $1, 'source_review_approved',
                 jsonb_build_object(
                   'appUserId', $2::text,
                   'sourceSegmentId', $3::text
                 ))`,
        [row.lesson_id, reviewerActorId, row.source_segment_id],
      );
      await client.query('COMMIT');
      return {
        courseId: row.course_code,
        lessonId: String(row.lesson_id),
        status: 'approved',
        contentReady,
        courseUpdatedAt: new Date(
          updatedCourse.rows[0].updated_at,
        ).toISOString(),
      };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async registerUploadedVideoEvidence({
    lessonId,
    transcript,
    evidenceNote,
    groundingFact,
    reviewerActorId = null,
  }) {
    if (process.env.AJE_STORE !== 'supabase') {
      throw new Error('Video evidence is only available in Supabase mode.');
    }
    const video = await this.pool.query(
      `SELECT l.title_sw, lr.storage_path
       FROM lessons l
       JOIN lesson_resources lr ON lr.lesson_id = l.id
       WHERE l.id = $1 AND l.lesson_type = 'video'
         AND lr.resource_type = 'video' AND lr.storage_path IS NOT NULL
       ORDER BY lr.updated_at DESC LIMIT 1`,
      [lessonId],
    );
    const row = video.rows[0];
    if (!row) throw new Error('Uploaded video could not be found for this lesson.');
    const contentHash = createHash('sha256').update(transcript).digest('hex');
    const document = await this.pool.query(
      `INSERT INTO source_documents
         (title, language_code, source_type, source_kind, storage_bucket,
          storage_path, file_name, checksum, processing_status, metadata)
       VALUES ($1, 'sw', 'video/mp4', 'video', $2, $3, $4, $5,
               'approved'::content_status, $6::jsonb)
       RETURNING id::text`,
      [
        `Video: ${row.title_sw}`,
        lessonVideosBucket,
        row.storage_path,
        path.basename(row.storage_path),
        createHash('sha256').update(row.storage_path).digest('hex'),
        JSON.stringify({ origin: 'admin_uploaded_video', reviewerActorId }),
      ],
    );
    const segment = await this.pool.query(
      `INSERT INTO source_segments
         (source_document_id, section_title, segment_order, content_sw,
          content_hash, extraction_method, review_status, risk_level,
          reviewed_by, reviewed_at)
       VALUES ($1, 'Transcript ya video', 1, $2, $3,
               'admin_video_transcript', 'approved'::content_status,
               'normal'::content_risk_level, $4, NOW())
       RETURNING id::text`,
      [document.rows[0].id, transcript, contentHash, reviewerActorId],
    );
    return this.approveLessonSource({
      lessonId,
      sourceSegmentId: segment.rows[0].id,
      evidenceNote,
      groundingFact,
      reviewerActorId,
    });
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
    if (process.env.AJE_STORE === 'supabase') {
      const result = await this.pool.query(
        `SELECT id::text, title, source_type, file_name, page_count,
                processing_status, updated_at
         FROM source_documents
         ORDER BY updated_at DESC`,
      );
      return result.rows.map(structuredContentDocumentFromRow);
    }
    const result = await this.pool.query(
      `SELECT id, status, payload, updated_at
       FROM content_documents
       ORDER BY updated_at DESC`,
    );
    return result.rows.map(contentDocumentFromRow);
  }

  async upsertContentDocument({ document, status = 'approved' }) {
    const normalizedDocument = normalizeContentDocument(document);
    if (process.env.AJE_STORE === 'supabase') {
      const structuredStatus =
        status === 'approved' ? 'published' : 'draft';
      const result = await this.pool.query(
        `UPDATE source_documents
         SET title = $2,
             processing_status = $3::content_status,
             updated_at = NOW()
         WHERE id = $1::uuid
         RETURNING id::text, processing_status, updated_at`,
        [normalizedDocument.id, normalizedDocument.title, structuredStatus],
      );
      const row = result.rows[0];
      if (!row) {
        throw new Error(
          'Source document was not found in the live content catalog.',
        );
      }
      return {
        id: row.id,
        status: structuredStatus === 'published' ? 'approved' : 'draft',
        document: normalizedDocument,
        updatedAt: new Date(row.updated_at).toISOString(),
      };
    }
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

  async getUser(userId) {
    const result = await this.pool.query(
      `SELECT id, phone_number, email, auth_user_id, account_status, role,
              subscription_plan, subscription_started_at,
              display_name, preferred_location, created_at, updated_at
       FROM users
       WHERE id = $1`,
      [userId],
    );
    return result.rows[0] ? userFromRow(result.rows[0]) : null;
  }

  async getUserByAuthUserId(authUserId) {
    if (!authUserId) return null;
    const result = await this.pool.query(
      `SELECT id, phone_number, email, auth_user_id, account_status, role,
              subscription_plan, subscription_started_at,
              display_name, preferred_location, created_at, updated_at
       FROM users
       WHERE auth_user_id = $1`,
      [authUserId],
    );
    return result.rows[0] ? userFromRow(result.rows[0]) : null;
  }

  async getUserByEmail(email) {
    const normalizedEmail = normalizeEmail(email);
    if (!normalizedEmail) return null;
    const result = await this.pool.query(
      `SELECT id, phone_number, email, auth_user_id, account_status, role,
              subscription_plan, subscription_started_at,
              display_name, preferred_location, created_at, updated_at
       FROM users
       WHERE lower(email) = $1`,
      [normalizedEmail],
    );
    return result.rows[0] ? userFromRow(result.rows[0]) : null;
  }

  // Called on every authenticated request with claims taken from the verified
  // Supabase JWT, never from request input. An account created before
  // Supabase Auth existed is matched by email and keeps its existing `id`, so
  // every row that already points at that id stays attached.
  async linkOrCreateUserForAuth({ authUserId, email }) {
    const normalizedEmail = normalizeEmail(email);
    const linked = await this.getUserByAuthUserId(authUserId);
    if (linked) {
      if (normalizedEmail && linked.email !== normalizedEmail) {
        const updatedAt = new Date().toISOString();
        await this.pool.query(
          `UPDATE users SET email = $2, updated_at = $3 WHERE id = $1`,
          [linked.id, normalizedEmail, updatedAt],
        );
        return { ...linked, email: normalizedEmail, updatedAt };
      }
      return linked;
    }

    const existing = await this.getUserByEmail(normalizedEmail);
    if (existing) {
      const updatedAt = new Date().toISOString();
      await this.pool.query(
        `UPDATE users SET auth_user_id = $2, email = $3, updated_at = $4 WHERE id = $1`,
        [existing.id, authUserId, normalizedEmail, updatedAt],
      );
      return { ...existing, authUserId, email: normalizedEmail, updatedAt };
    }

    const now = new Date().toISOString();
    const user = {
      id: createId('user'),
      authUserId,
      email: normalizedEmail,
      phoneNumber: null,
      role: 'learner',
      accountStatus: 'pending_activation',
      subscriptionPlan: null,
      subscriptionStartedAt: null,
      createdAt: now,
      updatedAt: now,
    };
    await this.pool.query(
      `INSERT INTO users (
         id, auth_user_id, email, role, account_status, subscription_plan,
         subscription_started_at, created_at, updated_at
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
      [
        user.id,
        user.authUserId,
        user.email,
        user.role,
        user.accountStatus,
        user.subscriptionPlan,
        user.subscriptionStartedAt,
        user.createdAt,
        user.updatedAt,
      ],
    );
    return user;
  }

  async setAccountStatus({ userId, accountStatus }) {
    const updatedAt = new Date().toISOString();
    const result = await this.pool.query(
      `UPDATE users SET account_status = $2, updated_at = $3
       WHERE id = $1
       RETURNING id, phone_number, email, auth_user_id, account_status, role,
                 subscription_plan, subscription_started_at,
                 display_name, preferred_location, created_at, updated_at`,
      [userId, accountStatus, updatedAt],
    );
    return result.rows[0] ? userFromRow(result.rows[0]) : null;
  }

  async activateSubscription({ userId, planTitle }) {
    const startedAt = new Date();
    const updatedAt = startedAt.toISOString();
    const result = await this.pool.query(
      `UPDATE users
       SET subscription_plan = $2,
           subscription_started_at = $3,
           account_status = 'active',
           updated_at = $4
       WHERE id = $1
       RETURNING id, phone_number, email, auth_user_id, account_status, role,
                 subscription_plan, subscription_started_at,
                 display_name, preferred_location, created_at, updated_at`,
      [userId, planTitle, startedAt.toISOString(), updatedAt],
    );
    return result.rows[0] ? userFromRow(result.rows[0]) : null;
  }

  async cancelSubscription(userId) {
    const user = await this.getUser(userId);
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

  async updateUserProfile(userId, { displayName, preferredLocation }) {
    const user = await this.getUser(userId);
    if (!user) return null;
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
       RETURNING id, phone_number, email, auth_user_id, account_status, role,
                 subscription_plan, subscription_started_at,
                 display_name, preferred_location, created_at, updated_at`,
      [user.id, nextDisplayName, nextPreferredLocation, updatedAt],
    );
    return userFromRow(result.rows[0]);
  }

  async adminUsersForAdmin({ search = '', limit = 50, offset = 0 } = {}) {
    const safeLimit = Math.max(1, Math.min(200, Number(limit) || 50));
    const safeOffset = Math.max(0, Number(offset) || 0);
    const query = String(search).trim();
    const queryLike = query.length > 0 ? `%${query}%` : null;
    const result = await this.pool.query(
      `WITH filtered_users AS (
         SELECT id, email, account_status, role, subscription_plan,
                subscription_started_at, display_name, preferred_location,
                created_at, updated_at
         FROM users
         WHERE ($1::text IS NULL)
            OR email ILIKE $1
            OR COALESCE(display_name, '') ILIKE $1
       )
       SELECT fu.id, fu.email, fu.account_status, fu.role, fu.subscription_plan,
              fu.subscription_started_at, fu.display_name, fu.preferred_location,
              fu.created_at, fu.updated_at,
              COALESCE(lp.learning_progress_count, 0) AS learning_progress_count,
              COALESCE(pt.payment_transactions_count, 0) AS payment_transactions_count,
              COALESCE(n.notification_count, 0) AS notification_count,
              COALESCE(cp.community_posts_count, 0) AS community_posts_count,
              COUNT(*) OVER() AS total_count
       FROM filtered_users fu
       LEFT JOIN (
         SELECT user_id, COUNT(*)::int AS learning_progress_count
         FROM learning_progress
         GROUP BY user_id
       ) lp ON lp.user_id = fu.id
       LEFT JOIN (
         SELECT user_id, COUNT(*)::int AS payment_transactions_count
         FROM (
           SELECT user_id FROM payment_transactions
           UNION ALL
           SELECT user_id FROM payment_records
         ) payments
         GROUP BY user_id
       ) pt ON pt.user_id = fu.id
       LEFT JOIN (
         SELECT user_id, COUNT(*)::int AS notification_count
         FROM notifications
         GROUP BY user_id
       ) n ON n.user_id = fu.id
       LEFT JOIN (
         SELECT author_user_id, COUNT(*)::int AS community_posts_count
         FROM community_posts
         WHERE author_user_id IS NOT NULL
         GROUP BY author_user_id
       ) cp ON cp.author_user_id = fu.id
       ORDER BY fu.updated_at DESC
       LIMIT $2
       OFFSET $3`,
      [queryLike, safeLimit, safeOffset],
    );

    const total = Number(result.rows[0]?.total_count ?? 0);
    const users = result.rows.map((row) => ({
      id: row.id,
      email: row.email ?? null,
      accountStatus: row.account_status ?? 'pending_activation',
      displayName: row.display_name ?? null,
      preferredLocation: row.preferred_location ?? null,
      role: row.role ?? 'learner',
      subscriptionPlan: row.subscription_plan ?? null,
      subscriptionStartedAt: row.subscription_started_at
        ? new Date(row.subscription_started_at).toISOString()
        : null,
      createdAt: new Date(row.created_at).toISOString(),
      updatedAt: new Date(row.updated_at).toISOString(),
      learningProgressCount: Number(row.learning_progress_count ?? 0),
      paymentTransactionsCount: Number(row.payment_transactions_count ?? 0),
      notificationCount: Number(row.notification_count ?? 0),
      communityPostsCount: Number(row.community_posts_count ?? 0),
    }));
    return { users, total };
  }

  async notificationSettings(userId) {
    const result = await this.pool.query(
      `SELECT user_id, enabled, community_replies, moderation_updates,
              learning_reminders, updated_at
       FROM notification_settings
       WHERE user_id = $1`,
      [userId],
    );
    if (!result.rows[0]) {
      return {
        userId,
        enabled: true,
        communityReplies: true,
        moderationUpdates: true,
        learningReminders: true,
      };
    }
    return notificationSettingsFromRow(result.rows[0]);
  }

  async updateNotificationSettings({ userId, settings }) {
    const current = await this.notificationSettings(userId);
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
         user_id, enabled, community_replies, moderation_updates,
         learning_reminders, updated_at
       ) VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (user_id) DO UPDATE
       SET enabled = EXCLUDED.enabled,
           community_replies = EXCLUDED.community_replies,
           moderation_updates = EXCLUDED.moderation_updates,
           learning_reminders = EXCLUDED.learning_reminders,
           updated_at = EXCLUDED.updated_at
       RETURNING user_id, enabled, community_replies, moderation_updates,
                 learning_reminders, updated_at`,
      [
        userId,
        next.enabled,
        next.communityReplies,
        next.moderationUpdates,
        next.learningReminders,
        new Date().toISOString(),
      ],
    );
    return notificationSettingsFromRow(result.rows[0]);
  }

  async registerNotificationDevice({ userId, token, platform }) {
    const now = new Date().toISOString();
    const result = await this.pool.query(
      `INSERT INTO notification_devices (
         id, user_id, token, platform, created_at, updated_at
       ) VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (token) DO UPDATE
       SET user_id = EXCLUDED.user_id,
           platform = EXCLUDED.platform,
           updated_at = EXCLUDED.updated_at
       RETURNING id, user_id, token, platform, created_at, updated_at`,
      [createId('device'), userId, token, platform, now, now],
    );
    return notificationDeviceFromRow(result.rows[0]);
  }

  async notificationDevices(userId) {
    const result = await this.pool.query(
      `SELECT id, user_id, token, platform, created_at, updated_at
       FROM notification_devices
       WHERE user_id = $1`,
      [userId],
    );
    return result.rows.map(notificationDeviceFromRow);
  }

  async notificationsFor(userId) {
    const result = await this.pool.query(
      `SELECT id, user_id, type, title, body, data, read_at, created_at
       FROM notifications
       WHERE user_id = $1
       ORDER BY created_at DESC`,
      [userId],
    );
    return result.rows.map(notificationFromRow);
  }

  async createNotification({ userId, type, title, body, data = {} }) {
    const settings = await this.notificationSettings(userId);
    if (!settings.enabled) return null;
    if (type === 'community_reply' && !settings.communityReplies) return null;
    if (type === 'moderation_update' && !settings.moderationUpdates) return null;
    const now = new Date().toISOString();
    const result = await this.pool.query(
      `INSERT INTO notifications (
         id, user_id, type, title, body, data, read_at, created_at
       ) VALUES ($1, $2, $3, $4, $5, $6, NULL, $7)
       RETURNING id, user_id, type, title, body, data, read_at, created_at`,
      [
        createId('notification'),
        userId,
        type,
        title,
        body,
        JSON.stringify(data),
        now,
      ],
    );
    return notificationFromRow(result.rows[0]);
  }

  async markNotificationRead({ userId, notificationId }) {
    const result = await this.pool.query(
      `UPDATE notifications
       SET read_at = COALESCE(read_at, $3)
       WHERE id = $1 AND user_id = $2
       RETURNING id, user_id, type, title, body, data, read_at, created_at`,
      [notificationId, userId, new Date().toISOString()],
    );
    return result.rows[0] ? notificationFromRow(result.rows[0]) : null;
  }

  async learningProgress(userId) {
    const result = await this.pool.query(
      `SELECT user_id, course_id, lesson_id, completed_at
       FROM learning_progress
       WHERE user_id = $1
       ORDER BY completed_at ASC`,
      [userId],
    );
    return result.rows.map((row) => ({
      userId: row.user_id,
      courseId: row.course_id,
      lessonId: row.lesson_id,
      completedAt: new Date(row.completed_at).toISOString(),
    }));
  }

  async markLessonCompleted({ userId, courseId, lessonId }) {
    if (
      !hasApprovedLessonInCourses(
        await this.approvedContentCourses(),
        courseId,
        lessonId,
      )
    ) {
      return null;
    }
    const completedAt = new Date().toISOString();
    const result = await this.pool.query(
      `INSERT INTO learning_progress (
         user_id, course_id, lesson_id, completed_at
       ) VALUES ($1, $2, $3, $4)
       ON CONFLICT (user_id, course_id, lesson_id) DO UPDATE
       SET completed_at = learning_progress.completed_at
       RETURNING user_id, course_id, lesson_id, completed_at`,
      [userId, courseId, lessonId, completedAt],
    );
    const row = result.rows[0];
    return {
      userId: row.user_id,
      courseId: row.course_id,
      lessonId: row.lesson_id,
      completedAt: new Date(row.completed_at).toISOString(),
    };
  }

  async communityPosts() {
    const posts = await this.pool.query(
      `SELECT id, author, location, time_label, content, likes, comments, tags,
              related_topic, image_path, has_image, is_expert, is_urgent,
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

  async createPaymentTransaction(transaction) {
    await this.pool.query(
      `INSERT INTO payment_transactions (
         id, plan_title, price, method, user_id, status, message,
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
        transaction.userId,
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
      `SELECT id, plan_title, price, method, user_id, status, message,
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
        `SELECT id, plan_title, price, method, user_id, status, message,
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
        userId: transaction.userId,
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
         RETURNING id, plan_title, price, method, user_id, status, message,
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
       RETURNING id, plan_title, price, method, user_id, status, message,
                 receipt_number, provider, provider_reference, checkout_instructions,
                 auto_confirm_at, subscription_plan, subscription_started_at`,
      [transactionId, message],
    );
    return result.rows[0] ? paymentFromRow(result.rows[0]) : null;
  }

  async createCommunityPost({
    author,
    authorUserId,
    content,
    location,
    tags,
    imagePath = null,
    isExpert = false,
  }) {
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
      imagePath: imagePath ?? null,
      hasImage: Boolean(imagePath),
      isExpert,
      isUrgent:
        normalizedTags.includes('Magonjwa') ||
        normalizedTags.includes('Wadudu'),
      moderationStatus: 'visible',
    };
    await this.#insertCommunityPost(post, new Date(), authorUserId);
    const { imagePath: _imagePath, ...publicPost } = post;
    return { ...publicPost, imageUrl: communityPostImageUrl(post.imagePath) };
  }

  // Uploads directly to Supabase Storage using the service role key. Only
  // available when running against a real Supabase project (the JSON store
  // used for local dev has no storage backend).
  async uploadCommunityPostImage({ contentType, bytes }) {
    if (process.env.AJE_STORE !== 'supabase') return null;
    const supabaseUrl = process.env.SUPABASE_URL;
    const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
    if (!supabaseUrl || !serviceRoleKey) return null;
    const extension = extensionForImageContentType(contentType);
    if (!extension) return null;

    const imagePath = `${createId('img')}.${extension}`;
    const response = await fetch(
      `${supabaseUrl}/storage/v1/object/${communityPostImagesBucket}/${imagePath}`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${serviceRoleKey}`,
          apikey: serviceRoleKey,
          'Content-Type': contentType,
        },
        body: bytes,
      },
    );
    if (!response.ok) return null;
    return imagePath;
  }

  // Mints a short-lived Supabase signed upload URL so the admin app can send a
  // lesson video straight to storage. Proxying the file through this API would
  // buffer 100MB in memory per upload; the token is scoped to one object key
  // and expires on its own.
  async createLessonVideoUploadUrl({ contentType }) {
    if (process.env.AJE_STORE !== 'supabase') return null;
    const supabaseUrl = process.env.SUPABASE_URL;
    const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
    if (!supabaseUrl || !serviceRoleKey) return null;
    const extension = extensionForVideoContentType(contentType);
    if (!extension) return null;

    const videoPath = `${lessonVideosPrefix}/${createId('vid')}.${extension}`;
    const response = await fetch(
      `${supabaseUrl}/storage/v1/object/upload/sign/${lessonVideosBucket}/${encodeStoragePath(videoPath)}`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${serviceRoleKey}`,
          apikey: serviceRoleKey,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ expiresIn: 3600 }),
      },
    );
    if (!response.ok) return null;
    const payload = await response.json();
    const signedPath = payload.url ?? payload.signedURL ?? payload.signedUrl;
    if (!signedPath) return null;
    return {
      videoPath,
      uploadUrl: resolveSupabaseSignedUrl(supabaseUrl, signedPath),
    };
  }

  async communityPostAuthorUserId(postId) {
    const result = await this.pool.query(
      `SELECT author_user_id FROM community_posts WHERE id = $1`,
      [postId],
    );
    return result.rows[0]?.author_user_id ?? null;
  }

  async addCommunityReply({
    postId,
    author,
    authorUserId,
    body,
    isExpert = false,
  }) {
    const reply = {
      author: author.trim(),
      body: body.trim(),
      time: 'Sasa hivi',
      isExpert,
    };
    await this.pool.query(
      `INSERT INTO community_replies (
         id, post_id, author, author_user_id, body, time_label, is_expert,
         created_at
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        createId('reply'),
        postId,
        reply.author,
        authorUserId ?? null,
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
              p.comments, p.tags, p.related_topic, p.image_path, p.has_image,
              p.is_expert, p.is_urgent, p.moderation_status, p.moderated_at,
              p.moderated_by, p.created_at
       FROM reported_community_posts r
       JOIN community_posts p ON p.id = r.post_id
       ORDER BY r.reported_at DESC`,
    );
    return reports.rows.map((row) => ({
      post: communityPostFromRow(row, { includeModeration: true }),
      report: {
        postId: row.post_id,
        reportedAt: new Date(row.reported_at).toISOString(),
        status: row.moderation_status === 'hidden' ? 'hidden' : 'open',
      },
    }));
  }

  async resolveCommunityReport({ postId, action, moderatorUserId }) {
    if (action === 'hide') {
      const result = await this.pool.query(
        `UPDATE community_posts
         SET moderation_status = 'hidden',
             moderated_at = $2,
             moderated_by = $3
         WHERE id = $1
         RETURNING id, author, location, time_label, content, likes, comments,
                   tags, related_topic, image_path, has_image, is_expert,
                   is_urgent, moderation_status, moderated_at, moderated_by,
                   created_at`,
        [postId, new Date().toISOString(), moderatorUserId],
      );
      await this.pool.query(
        `DELETE FROM reported_community_posts WHERE post_id = $1`,
        [postId],
      );
      return result.rows[0]
        ? communityPostFromRow(result.rows[0], { includeModeration: true })
        : null;
    }

    const result = await this.pool.query(
      `SELECT id, author, location, time_label, content, likes, comments, tags,
              related_topic, image_path, has_image, is_expert, is_urgent,
              moderation_status, moderated_at, moderated_by, created_at
       FROM community_posts
       WHERE id = $1`,
      [postId],
    );
    await this.pool.query(
      `DELETE FROM reported_community_posts WHERE post_id = $1`,
      [postId],
    );
    return result.rows[0]
      ? communityPostFromRow(result.rows[0], { includeModeration: true })
      : null;
  }

  // Only used by the NODE_ENV=development dev-session issuer (see auth.js) so
  // local dev and the server test suite can authenticate without a real
  // Supabase Auth token. Production sessions come from Supabase JWTs and
  // never touch this table.
  async createAuthSession(userId) {
    await this.#purgeExpiredAuthSessions();
    const token = createSessionToken();
    const createdAt = new Date().toISOString();
    const expiresAt = sessionExpiresAt();
    await this.pool.query(
      `INSERT INTO auth_sessions (token, user_id, created_at, expires_at)
       VALUES ($1, $2, $3, $4)`,
      [token, userId, createdAt, expiresAt],
    );
    return { token, userId, createdAt, expiresAt };
  }

  async getAuthSession(token) {
    await this.#purgeExpiredAuthSessions();
    const result = await this.pool.query(
      `SELECT user_id, expires_at
       FROM auth_sessions
       WHERE token = $1`,
      [token],
    );
    const row = result.rows[0];
    if (!row || isSessionExpired(row.expires_at)) return null;
    return { userId: row.user_id };
  }

  async resetForTests() {
    await this.pool.query(`
      TRUNCATE TABLE
        reported_community_posts,
        community_replies,
        community_posts,
        auth_sessions,
        learning_progress,
        notification_settings,
        notification_devices,
        notifications,
        content_documents,
        content_courses,
        app_settings,
        payment_transactions,
        audit_events,
        entitlements,
        payment_records,
        users
      RESTART IDENTITY
    `);
    await this.#seedContentCatalog();
    await this.#seedCommunityCatalog();
  }

  // The caller (markPaymentPaid) already holds `users` FOR UPDATE within its
  // own transaction, and the user row always exists by the time a payment
  // happens (requireAuthSession links/creates it on first authenticated
  // request), so this only ever updates.
  async #activateSubscriptionWithClient(client, { userId, planTitle }) {
    const startedAt = new Date();
    const updatedAt = startedAt.toISOString();
    const updated = await client.query(
      `UPDATE users
       SET subscription_plan = $2,
           subscription_started_at = $3,
           account_status = 'active',
           updated_at = $4
       WHERE id = $1
       RETURNING id, phone_number, email, auth_user_id, account_status, role,
                 subscription_plan, subscription_started_at,
                 created_at, updated_at`,
      [userId, planTitle, startedAt.toISOString(), updatedAt],
    );
    return userFromRow(updated.rows[0]);
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

  async #insertCommunityPost(post, createdAt, authorUserId = null) {
    await this.pool.query(
      `INSERT INTO community_posts (
         id, author, author_user_id, location, time_label, content, likes,
         comments, tags, related_topic, image_path, has_image, is_expert,
         is_urgent, moderation_status, moderated_at, moderated_by, created_at
       ) VALUES (
         $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13,
         $14, $15, $16, $17, $18
       )
       ON CONFLICT (id) DO NOTHING`,
      [
        post.id,
        post.author,
        authorUserId,
        post.location,
        post.time,
        post.content,
        post.likes ?? 0,
        post.comments ?? 0,
        JSON.stringify(post.tags ?? []),
        post.relatedTopic ?? null,
        post.imagePath ?? null,
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

// `moderatedBy` holds a moderator's internal user id, so it is omitted unless an
// admin-only caller opts in. `/api/community/posts` is unauthenticated.
function communityPostFromRow(row, { includeModeration = false } = {}) {
  const post = {
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
    imageUrl: communityPostImageUrl(row.image_path),
    hasImage: row.has_image,
    isExpert: row.is_expert,
    isUrgent: row.is_urgent,
    moderationStatus: row.moderation_status ?? 'visible',
  };
  if (!includeModeration) return post;
  return {
    ...post,
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
    userId: row.user_id,
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
    userId: row.user_id,
    token: row.token,
    platform: row.platform,
    createdAt: new Date(row.created_at).toISOString(),
    updatedAt: new Date(row.updated_at).toISOString(),
  };
}

function notificationFromRow(row) {
  return {
    id: row.id,
    userId: row.user_id,
    type: row.type,
    title: row.title,
    body: row.body,
    data: row.data ?? {},
    readAt: row.read_at ? new Date(row.read_at).toISOString() : null,
    createdAt: new Date(row.created_at).toISOString(),
  };
}

function paymentRecordFromRow(row) {
  return {
    id: row.id,
    userId: row.user_id,
    planId: row.plan_id,
    method: row.method,
    amountTzs: Number(row.amount_tzs),
    currency: row.currency,
    reference: row.reference ?? null,
    note: row.note ?? null,
    status: row.status,
    recordedBy: row.recorded_by,
    approvedBy: row.approved_by ?? null,
    approvedAt: row.approved_at ? new Date(row.approved_at).toISOString() : null,
    reversedBy: row.reversed_by ?? null,
    reversedAt: row.reversed_at ? new Date(row.reversed_at).toISOString() : null,
    createdAt: new Date(row.created_at).toISOString(),
    updatedAt: new Date(row.updated_at).toISOString(),
  };
}

function entitlementFromRow(row) {
  return {
    id: row.id,
    userId: row.user_id,
    planId: row.plan_id,
    paymentRecordId: row.payment_record_id,
    status: row.status,
    grantedAt: new Date(row.granted_at).toISOString(),
    expiresAt: new Date(row.expires_at).toISOString(),
    revokedAt: row.revoked_at ? new Date(row.revoked_at).toISOString() : null,
    createdAt: new Date(row.created_at).toISOString(),
    updatedAt: new Date(row.updated_at).toISOString(),
  };
}

function auditEventFromRow(row) {
  return {
    id: row.id,
    actorUserId: row.actor_user_id ?? null,
    action: row.action,
    targetType: row.target_type,
    targetId: row.target_id,
    previousStatus: row.previous_status ?? null,
    newStatus: row.new_status ?? null,
    reason: row.reason ?? null,
    metadata: row.metadata ?? {},
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

function contentCourseToCurriculum(row) {
  const payload = row.payload ?? {};
  const isApproved = row.status === 'approved';
  return {
    id: row.id,
    status: row.status,
    updatedAt: new Date(row.updated_at).toISOString(),
    course: {
      id: row.id,
      title: payload.title ?? '',
      description: payload.description ?? '',
      badge: payload.badge ?? '',
      icon: payload.icon ?? 'menu_book',
      imageUrl: payload.imageUrl ?? '',
      deliveryType: 'text',
      lessons: (payload.lessons ?? []).map((lesson) => {
        const isVideo = lesson.type === 'video';
        const hasContent = isVideo
          ? Boolean(
              (lesson.resourceUrl ?? '').trim() ||
                (lesson.videoPath ?? '').trim(),
            )
          : Boolean((lesson.description ?? '').trim());
        const reasons = [];
        if (!isApproved) reasons.push('Kozi bado haijaidhinishwa.');
        if (!hasContent) {
          reasons.push(
            isVideo
              ? 'Somo hili halina video.'
              : 'Somo hili halina maandishi.',
          );
        }
        return {
          id: lesson.id ?? null,
          moduleId: null,
          moduleTitle: null,
          title: lesson.title ?? '',
          type: isVideo ? 'video' : 'reading',
          meta: lesson.meta ?? '',
          body: lesson.description ?? '',
          durationMinutes: null,
          videoUrl: lesson.resourceUrl ?? null,
          videoPath: lesson.videoPath ?? null,
          readiness: { visible: reasons.length === 0, reasons },
        };
      }),
    },
  };
}

function structuredCourseCurriculumFromRows(rows) {
  const first = rows[0];
  const isApproved = first.course_status === 'published';
  const lessons = [];
  for (const row of rows) {
    if (!row.lesson_id) continue;
    const isVideo = row.lesson_type === 'video';
    const hasVideo = Boolean(row.video_url || row.video_storage_path);
    const hasBody = Boolean((row.lesson_body ?? '').trim());
    const reasons = [];
    if (row.course_status !== 'published') {
      reasons.push('Kozi bado haijachapishwa.');
    }
    if (row.module_status !== 'published') {
      reasons.push('Sehemu (module) bado haijachapishwa.');
    }
    if (row.lesson_status !== 'published') {
      reasons.push('Somo bado halijachapishwa.');
    }
    if (isVideo && !hasVideo) {
      reasons.push('Video ya somo haijawekwa.');
    }
    if (!isVideo && !hasBody) {
      reasons.push('Maandishi ya somo hayajajazwa.');
    }
    lessons.push({
      id: row.lesson_id,
      moduleId: row.module_id,
      moduleTitle: row.module_title,
      title: row.lesson_title,
      type: isVideo ? 'video' : 'reading',
      meta: row.duration_minutes ? `Dakika ${row.duration_minutes}` : '',
      body: row.lesson_body ?? '',
      durationMinutes: row.duration_minutes ?? null,
      videoUrl: row.video_url ?? null,
      videoPath: row.video_storage_path ?? null,
      readiness: { visible: reasons.length === 0, reasons },
    });
  }
  return {
    id: first.course_code,
    status: isApproved ? 'approved' : 'draft',
    updatedAt: new Date(first.course_updated_at).toISOString(),
    course: {
      id: first.course_code,
      title: first.course_title,
      description: first.course_description,
      badge: first.delivery_type === 'video' ? 'Kozi ya video' : 'Kozi ya maandishi',
      icon: first.delivery_type === 'video' ? 'play_circle' : 'menu_book',
      imageUrl: courseImageForCode(first.course_code),
      deliveryType: first.delivery_type,
      lessons,
    },
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

function structuredContentCourseRecords(rows) {
  const records = new Map();
  for (const row of rows) {
    let record = records.get(row.course_id);
    if (!record) {
      const course = {
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
      record = {
        id: row.course_code,
        status:
          row.course_status === 'published' ? 'approved' : 'draft',
        course,
        updatedAt: new Date(row.course_updated_at).toISOString(),
      };
      records.set(row.course_id, record);
    }
    if (
      row.module_title &&
      !record.course.outcomes.includes(row.module_title)
    ) {
      record.course.outcomes.push(row.module_title);
    }
    if (row.lesson_id) {
      const isVideo = row.lesson_type === 'video';
      const readinessReasons = [];
      if (row.course_status !== 'published') {
        readinessReasons.push('Kozi bado haijachapishwa.');
      }
      if (row.module_status !== 'published') {
        readinessReasons.push('Sehemu bado haijachapishwa.');
      }
      if (row.lesson_status !== 'published') {
        readinessReasons.push('Somo bado halijachapishwa.');
      }
      if (isVideo && !row.has_video) {
        readinessReasons.push('Video ya somo haijawekwa.');
      }
      if (!isVideo && !(row.lesson_body ?? '').trim()) {
        readinessReasons.push('Maandishi ya somo hayajajazwa.');
      }
      record.course.lessons.push({
        id: row.lesson_id,
        moduleId: row.module_id,
        moduleTitle: row.module_title,
        title: row.lesson_title,
        type: isVideo ? 'video' : 'reading',
        meta: row.duration_minutes
          ? `Dakika ${row.duration_minutes}`
          : isVideo
            ? 'Video'
            : 'Somo',
        description: row.lesson_body ?? '',
        durationMinutes: row.duration_minutes ?? null,
        resourceUrl: row.video_url ?? null,
        videoPath: row.video_storage_path ?? null,
        readiness: {
          visible: readinessReasons.length === 0,
          reasons: readinessReasons,
        },
        isPremium: false,
        isCompleted: false,
      });
    }
  }
  return [...records.values()].map((record) => ({
    ...record,
    course: normalizeApprovedCourse(record.course),
  }));
}

function contentCourseRecordFromCurriculum(record) {
  return {
    id: record.id,
    status: record.status,
    updatedAt: record.updatedAt,
    course: normalizeApprovedCourse({
      id: record.course.id,
      title: record.course.title,
      description: record.course.description,
      badge: record.course.badge,
      icon: record.course.icon,
      progress: 0,
      imageUrl: record.course.imageUrl,
      outcomes: [
        ...new Set(
          record.course.lessons
            .map((lesson) => lesson.moduleTitle)
            .filter(Boolean),
        ),
      ],
      lessons: record.course.lessons.map((lesson) => ({
        id: lesson.id,
        moduleId: lesson.moduleId,
        moduleTitle: lesson.moduleTitle,
        title: lesson.title,
        type: lesson.type,
        meta: lesson.meta,
        description: lesson.body,
        durationMinutes: lesson.durationMinutes,
        resourceUrl: lesson.videoUrl,
        videoPath: lesson.videoPath,
        readiness: lesson.readiness,
        isPremium: false,
        isCompleted: false,
      })),
    }),
  };
}

function durationFromMeta(meta) {
  const match = String(meta ?? '').match(/\d+/);
  if (!match) return null;
  const duration = Number.parseInt(match[0], 10);
  return Number.isInteger(duration) && duration > 0 ? duration : null;
}

function structuredContentDocumentFromRow(row) {
  return {
    id: row.id,
    status:
      row.processing_status === 'published' ? 'approved' : 'draft',
    document: normalizeContentDocument({
      id: row.id,
      title: row.title,
      courseId: '',
      courseTitle: 'Chanzo cha mafunzo',
      description: row.file_name || row.source_type,
      type: row.source_type === 'pdf' ? 'pdf' : row.source_type,
      sizeLabel: row.page_count ? `Kurasa ${row.page_count}` : '',
      url: null,
      isPremium: false,
    }),
    updatedAt: new Date(row.updated_at).toISOString(),
  };
}

const sourceCourseCoverByCode = new Map([
  ['CRS-001', 'assets/images/courses/crs-001.jpg'],
  ['CRS-ALZ-01', 'assets/images/courses/crs-alz-01.jpg'],
  ['CRS-CHK-01', 'assets/images/courses/crs-chk-01.jpg'],
  ['CRS-KUK-01', 'assets/images/courses/crs-kuk-01.jpg'],
  ['CRS-KUK-02', 'assets/images/courses/crs-kuk-02.jpg'],
  ['CRS-MGB-01', 'assets/images/courses/crs-mgb-01.jpg'],
  ['CRS-MHG-01', 'assets/images/courses/crs-mhg-01.jpg'],
  ['CRS-MPU-01', 'assets/images/courses/crs-mpu-01.jpg'],
  ['CRS-NAN-01', 'assets/images/courses/crs-nan-01.jpg'],
  ['CRS-NYN-01', 'assets/images/courses/crs-nyn-01.jpg'],
  ['CRS-PSH-01', 'assets/images/courses/crs-psh-01.jpg'],
  ['CRS-USH-01', 'assets/images/courses/crs-ush-01.jpg'],
]);

export function courseImageForCode(code) {
  const exactCode = String(code ?? '').trim().toUpperCase();
  const sourceCover = sourceCourseCoverByCode.get(exactCode);
  if (sourceCover) return sourceCover;

  const normalized = exactCode.toLowerCase();
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
