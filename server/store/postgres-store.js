import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import pg from 'pg';

import {
  approvedCoursesFromCatalog,
  communityPostImageUrl,
  communityPostImagesBucket,
  createId,
  documentsFromCourses,
  extensionForImageContentType,
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
  }) {
    const normalizedCourse = normalizeApprovedCourse(course);
    if (process.env.AJE_STORE === 'supabase') {
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
          throw new Error('Course was not found in the live content catalog.');
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
          })),
        },
      );
      return contentCourseRecordFromCurriculum(curriculum);
    }
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
      const courseRow = courseResult.rows[0];
      if (!courseRow) {
        throw new Error('Course was not found in the live content catalog.');
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
           ) AS video_url
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
            const requestedVideoUrl = (lesson.videoUrl ?? '').trim() || null;
            const lessonContentChanged =
              (existingLesson?.body_sw ?? null) !== requestedBody ||
              existingLesson?.lesson_type !== lessonType;
            const videoChanged =
              lessonType === 'video' &&
              requestedVideoUrl != null &&
              (existingLesson?.video_url ?? null) !== requestedVideoUrl;
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

          if (lessonType === 'video' && (lesson.videoUrl ?? '').trim()) {
            const existingLesson = existingLessonsById.get(lessonId);
            const videoChanged =
              existingLesson != null &&
              (existingLesson.video_url ?? null) !== lesson.videoUrl.trim();
            const existingResource = await client.query(
              `UPDATE lesson_resources
               SET external_url = $2,
                   title_sw = $3,
                   status = CASE
                     WHEN $4 THEN 'draft'::content_status
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
              [lessonId, lesson.videoUrl.trim(), lesson.title, videoChanged],
            );
            if (existingResource.rows.length === 0) {
              await client.query(
                `INSERT INTO lesson_resources
                   (lesson_id, resource_type, external_url, title_sw, status)
                 VALUES ($1, 'video', $2, $3, 'draft'::content_status)`,
                [lessonId, lesson.videoUrl.trim(), lesson.title],
              );
            }
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

      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
    return this.courseCurriculum(courseCode);
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

  async adminUsersForAdmin({ search = '', limit = 50, offset = 0 } = {}) {
    const safeLimit = Math.max(1, Math.min(200, Number(limit) || 50));
    const safeOffset = Math.max(0, Number(offset) || 0);
    const query = String(search).trim();
    const queryLike = query.length > 0 ? `%${query}%` : null;
    const result = await this.pool.query(
      `WITH filtered_users AS (
         SELECT id, phone_number, role, subscription_plan, subscription_started_at,
                display_name, preferred_location, created_at, updated_at
         FROM users
         WHERE ($1::text IS NULL)
            OR phone_number ILIKE $1
            OR COALESCE(display_name, '') ILIKE $1
       )
       SELECT fu.id, fu.phone_number, fu.role, fu.subscription_plan,
              fu.subscription_started_at, fu.display_name, fu.preferred_location,
              fu.created_at, fu.updated_at,
              COALESCE(lp.learning_progress_count, 0) AS learning_progress_count,
              COALESCE(pt.payment_transactions_count, 0) AS payment_transactions_count,
              COALESCE(n.notification_count, 0) AS notification_count,
              COALESCE(cp.community_posts_count, 0) AS community_posts_count,
              COUNT(*) OVER() AS total_count
       FROM filtered_users fu
       LEFT JOIN (
         SELECT phone_number, COUNT(*)::int AS learning_progress_count
         FROM learning_progress
         GROUP BY phone_number
       ) lp ON lp.phone_number = fu.phone_number
       LEFT JOIN (
         SELECT phone_number, COUNT(*)::int AS payment_transactions_count
         FROM payment_transactions
         GROUP BY phone_number
       ) pt ON pt.phone_number = fu.phone_number
       LEFT JOIN (
         SELECT phone_number, COUNT(*)::int AS notification_count
         FROM notifications
         GROUP BY phone_number
       ) n ON n.phone_number = fu.phone_number
       LEFT JOIN (
         SELECT author_phone AS phone_number,
                COUNT(*)::int AS community_posts_count
         FROM community_posts
         WHERE author_phone IS NOT NULL
         GROUP BY author_phone
       ) cp ON cp.phone_number = fu.phone_number
       ORDER BY fu.updated_at DESC
       LIMIT $2
       OFFSET $3`,
      [queryLike, safeLimit, safeOffset],
    );

    const total = Number(result.rows[0]?.total_count ?? 0);
    const users = result.rows.map((row) => ({
      id: row.id,
      phoneNumber: row.phone_number,
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

  async createCommunityPost({
    author,
    authorPhone,
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
    await this.#insertCommunityPost(post, new Date(), authorPhone);
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

  async communityPostAuthorPhone(postId) {
    const result = await this.pool.query(
      `SELECT author_phone FROM community_posts WHERE id = $1`,
      [postId],
    );
    return result.rows[0]?.author_phone ?? null;
  }

  async addCommunityReply({
    postId,
    author,
    authorPhone,
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
         id, post_id, author, author_phone, body, time_label, is_expert,
         created_at
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        createId('reply'),
        postId,
        reply.author,
        authorPhone ?? null,
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

  async resolveCommunityReport({ postId, action, moderatorPhoneNumber }) {
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
        [postId, new Date().toISOString(), moderatorPhoneNumber],
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

  async #insertCommunityPost(post, createdAt, authorPhone = null) {
    await this.pool.query(
      `INSERT INTO community_posts (
         id, author, author_phone, location, time_label, content, likes,
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
        authorPhone,
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

// `moderatedBy` holds a moderator phone number, so it is omitted unless an
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
          ? Boolean((lesson.resourceUrl ?? '').trim())
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
    if (row.lesson_link_status !== 'linked') {
      reasons.push('Somo halijaunganishwa na hati chanzo.');
    }
    if (isVideo && !hasVideo) {
      reasons.push('Video ya somo haijawekwa.');
    }
    if (!isVideo && !hasBody) {
      reasons.push('Maandishi ya somo hayajajazwa.');
    }
    if (!row.has_source_link) {
      reasons.push('Hakuna kiungo cha chanzo kilichothibitishwa.');
    }
    if (!row.has_grounding) {
      reasons.push('Hakuna ukweli wa msingi (grounding facts) uliochapishwa.');
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
      if (row.lesson_link_status !== 'linked') {
        readinessReasons.push('Somo halijaunganishwa na hati chanzo.');
      }
      if (isVideo && !row.has_video) {
        readinessReasons.push('Video ya somo haijawekwa.');
      }
      if (!isVideo && !(row.lesson_body ?? '').trim()) {
        readinessReasons.push('Maandishi ya somo hayajajazwa.');
      }
      if (!row.has_source_link) {
        readinessReasons.push('Hakuna kiungo cha chanzo kilichothibitishwa.');
      }
      if (!row.has_grounding) {
        readinessReasons.push('Hakuna ukweli wa msingi uliochapishwa.');
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
