import assert from 'node:assert/strict';
import test from 'node:test';

import { PostgresStore } from '../store/postgres-store.js';

function withSupabaseStore(run) {
  return async () => {
    const previous = process.env.AJE_STORE;
    process.env.AJE_STORE = 'supabase';
    try {
      await run();
    } finally {
      if (previous == null) {
        delete process.env.AJE_STORE;
      } else {
        process.env.AJE_STORE = previous;
      }
    }
  };
}

test(
  'admin course listing reads the structured learner catalog in Supabase mode',
  withSupabaseStore(async () => {
    const store = new PostgresStore({
      pool: {
        query: async (sql) => {
          assert.match(sql, /FROM courses c/);
          assert.match(sql, /LEFT JOIN course_modules/);
          return {
            rows: [
              {
                course_id: 'course-uuid',
                course_code: 'NYANYA-001',
                course_title: 'Kilimo cha Nyanya',
                course_description: 'Mafunzo ya nyanya',
                delivery_type: 'text',
                course_status: 'published',
                course_updated_at: '2026-07-26T10:00:00.000Z',
                module_id: '00000000-0000-0000-0000-000000000010',
                module_title: 'Msingi',
                module_status: 'published',
                lesson_id: 'lesson-uuid',
                lesson_title: 'Utangulizi',
                lesson_body: 'Somo la kwanza',
                lesson_type: 'reading',
                duration_minutes: 5,
                lesson_status: 'published',
                lesson_link_status: 'linked',
                has_video: false,
                has_source_link: true,
                has_grounding: true,
              },
            ],
          };
        },
      },
      catalog: {},
      schema: 'public',
    });

    const records = await store.contentCoursesForAdmin();

    assert.equal(records.length, 1);
    assert.equal(records[0].id, 'NYANYA-001');
    assert.equal(records[0].status, 'approved');
    assert.equal(records[0].course.lessons[0].title, 'Utangulizi');
    assert.equal(
      records[0].course.lessons[0].moduleId,
      '00000000-0000-0000-0000-000000000010',
    );
    assert.equal(records[0].course.lessons[0].readiness.visible, true);
  }),
);

test(
  'learner catalog keeps valid reading and video lessons in a mixed course',
  withSupabaseStore(async () => {
    let queryText = '';
    const store = new PostgresStore({
      pool: {
        query: async (sql) => {
          queryText = sql;
          return {
            rows: [
              {
                course_id: 'course-uuid',
                course_code: 'MIXED-001',
                course_title: 'Kozi Mchanganyiko',
                course_description: 'Masomo na video',
                delivery_type: 'video',
                module_title: 'Msingi',
                lesson_id: 'lesson-reading',
                lesson_title: 'Somo',
                lesson_body: 'Maandishi',
                lesson_type: 'reading',
                duration_minutes: 5,
              },
              {
                course_id: 'course-uuid',
                course_code: 'MIXED-001',
                course_title: 'Kozi Mchanganyiko',
                course_description: 'Masomo na video',
                delivery_type: 'video',
                module_title: 'Msingi',
                lesson_id: 'lesson-video',
                lesson_title: 'Video',
                lesson_body: '',
                lesson_type: 'video',
                duration_minutes: 4,
                video_url: 'https://video.example/lesson.mp4',
              },
            ],
          };
        },
      },
      catalog: {},
      schema: 'public',
    });

    const courses = await store.approvedContentCourses();

    assert.deepEqual(
      courses[0].lessons.map((lesson) => lesson.type),
      ['reading', 'video'],
    );
    assert.doesNotMatch(
      queryText,
      /delivery_type[\s\S]*AND l\.lesson_type = 'reading'/,
    );
  }),
);

test(
  'admin course save updates the structured course used by learners',
  withSupabaseStore(async () => {
    const calls = [];
    const courseId = '00000000-0000-0000-0000-000000000001';
    const moduleId = '00000000-0000-0000-0000-000000000010';
    const lessonId = '00000000-0000-0000-0000-000000000100';
    const client = {
      query: async (sql, params) => {
        calls.push({ sql, params });
        if (/SELECT id, status::text AS status, updated_at/.test(sql)) {
          return {
            rows: [
              {
                id: courseId,
                status: 'published',
                updated_at: '2026-07-26T10:00:00.000Z',
              },
            ],
          };
        }
        if (/SELECT id::text, code, title_sw, status::text AS status/.test(sql)) {
          return {
            rows: [
              {
                id: moduleId,
                code: 'MOD-1',
                title_sw: 'Msingi',
                status: 'published',
              },
            ],
          };
        }
        if (/l\.id::text,[\s\S]*l\.module_id::text/.test(sql)) {
          return {
            rows: [
              {
                id: lessonId,
                module_id: moduleId,
                body_sw: 'Maandishi mapya',
                lesson_type: 'reading',
                video_url: null,
              },
            ],
          };
        }
        if (/SELECT id::text FROM lessons/.test(sql)) {
          return { rows: [{ id: lessonId }] };
        }
        return { rows: [] };
      },
      release() {},
    };
    const store = new PostgresStore({
      pool: {
        connect: async () => client,
        query: async (sql, params) => {
          calls.push({ sql, params });
          assert.match(sql, /FROM courses c/);
          return {
            rows: [
              {
                course_id: courseId,
                course_code: 'NYANYA-001',
                course_title: 'Nyanya Bora',
                course_description: 'Mafunzo kamili ya nyanya',
                delivery_type: 'text',
                course_status: 'published',
                course_updated_at: '2026-07-26T10:05:00.000Z',
                module_id: moduleId,
                module_title: 'Msingi',
                module_status: 'published',
                lesson_id: lessonId,
                lesson_title: 'Utangulizi mpya',
                lesson_body: 'Maandishi mapya',
                lesson_type: 'reading',
                duration_minutes: 8,
                lesson_status: 'published',
                lesson_link_status: 'linked',
                has_source_link: true,
                has_grounding: true,
              },
            ],
          };
        },
      },
      catalog: {},
      schema: 'public',
    });

    const record = await store.upsertContentCourse({
      status: 'approved',
      replaceCurriculum: true,
      baseUpdatedAt: '2026-07-26T10:00:00.000Z',
      course: {
        id: 'NYANYA-001',
        title: 'Nyanya Bora',
        description: 'Mafunzo kamili ya nyanya',
        badge: 'Kozi ya maandishi',
        icon: 'menu_book',
        imageUrl: 'assets/images/courses/nyanya.jpg',
        outcomes: ['Msingi'],
        lessons: [
          {
            id: lessonId,
            moduleId,
            moduleTitle: 'Msingi',
            title: 'Utangulizi mpya',
            type: 'reading',
            meta: 'Dakika 8',
            description: 'Maandishi mapya',
            durationMinutes: 8,
          },
        ],
      },
    });

    assert.ok(
      calls.some(
        ({ sql, params }) =>
          /UPDATE courses/.test(sql) &&
          params[1] === 'Nyanya Bora' &&
          params[2] === 'Mafunzo kamili ya nyanya',
      ),
    );
    assert.ok(
      calls.some(
        ({ sql, params }) =>
          /UPDATE lessons/.test(sql) &&
          params[0] === lessonId &&
          params[1] === 'Utangulizi mpya' &&
          params[2] === 'Maandishi mapya',
      ),
    );
    assert.equal(record.status, 'approved');
    assert.equal(record.course.title, 'Nyanya Bora');
    assert.equal(record.course.lessons[0].moduleTitle, 'Msingi');
    assert.equal(record.course.lessons[0].description, 'Maandishi mapya');
  }),
);

test(
  'legacy admin saves preserve the existing module for lessons without module ids',
  withSupabaseStore(async () => {
    const calls = [];
    const courseId = '00000000-0000-0000-0000-000000000001';
    const moduleId = '00000000-0000-0000-0000-000000000010';
    const lessonId = '00000000-0000-0000-0000-000000000100';
    const client = {
      query: async (sql, params) => {
        calls.push({ sql, params });
        if (/SELECT id, status::text AS status, updated_at/.test(sql)) {
          return {
            rows: [
              {
                id: courseId,
                status: 'published',
                updated_at: '2026-07-26T10:00:00.000Z',
              },
            ],
          };
        }
        if (/SELECT id::text, code, title_sw, status::text AS status/.test(sql)) {
          return {
            rows: [
              {
                id: moduleId,
                code: 'MOD-1',
                title_sw: 'Msingi uliopo',
                status: 'published',
              },
            ],
          };
        }
        if (/l\.id::text,[\s\S]*l\.module_id::text/.test(sql)) {
          return {
            rows: [
              {
                id: lessonId,
                module_id: moduleId,
                body_sw: 'Maandishi',
                lesson_type: 'reading',
                video_url: null,
              },
            ],
          };
        }
        if (/SELECT id::text FROM lessons/.test(sql)) {
          return { rows: [{ id: lessonId }] };
        }
        return { rows: [] };
      },
      release() {},
    };
    const store = new PostgresStore({
      pool: {
        connect: async () => client,
        query: async () => ({
          rows: [
            {
              course_id: courseId,
              course_code: 'NYANYA-001',
              course_title: 'Jina jipya',
              course_description: 'Maelezo',
              delivery_type: 'text',
              course_status: 'published',
              course_updated_at: '2026-07-26T10:05:00.000Z',
              module_id: moduleId,
              module_title: 'Msingi uliopo',
              module_status: 'published',
              lesson_id: lessonId,
              lesson_title: 'Utangulizi',
              lesson_body: 'Maandishi',
              lesson_type: 'reading',
              duration_minutes: 5,
              lesson_status: 'published',
              lesson_link_status: 'linked',
              has_source_link: true,
              has_grounding: true,
            },
          ],
        }),
      },
      catalog: {},
      schema: 'public',
    });

    await store.upsertContentCourse({
      status: 'approved',
      replaceCurriculum: true,
      baseUpdatedAt: '2026-07-26T10:00:00.000Z',
      course: {
        id: 'NYANYA-001',
        title: 'Jina jipya',
        description: 'Maelezo',
        badge: 'Kozi ya maandishi',
        icon: 'menu_book',
        imageUrl: 'assets/images/courses/nyanya.jpg',
        outcomes: ['Jina la kwanza kutoka APK ya zamani'],
        lessons: [
          {
            id: lessonId,
            title: 'Utangulizi',
            type: 'reading',
            meta: 'Dakika 5',
            description: 'Maandishi',
          },
        ],
      },
    });

    assert.ok(
      calls.some(
        ({ sql, params }) =>
          /UPDATE course_modules/.test(sql) &&
          params[0] === moduleId &&
          params[1] === 'Msingi uliopo',
      ),
    );
    assert.ok(
      calls.some(
        ({ sql, params }) =>
          /UPDATE lessons/.test(sql) && params[0] === lessonId,
      ),
    );
    assert.equal(
      calls.some(({ sql }) => /INSERT INTO course_modules/.test(sql)),
      false,
    );
    assert.equal(
      calls.some(({ sql }) => /DELETE FROM course_modules/.test(sql)),
      false,
    );
  }),
);

test(
  'legacy admin payload updates course metadata without replacing curriculum',
  withSupabaseStore(async () => {
    const calls = [];
    const store = new PostgresStore({
      pool: {
        query: async (sql, params) => {
          calls.push({ sql, params });
          if (/UPDATE courses/.test(sql)) {
            return {
              rows: [
                {
                  code: 'NYANYA-001',
                  status: 'published',
                  updated_at: '2026-07-26T10:05:00.000Z',
                },
              ],
            };
          }
          return {
            rows: [
              {
                course_id: '00000000-0000-0000-0000-000000000001',
                course_code: 'NYANYA-001',
                course_title: 'Jina jipya',
                course_description: 'Maelezo mapya',
                delivery_type: 'text',
                course_status: 'published',
                course_updated_at: '2026-07-26T10:05:00.000Z',
                module_id: '00000000-0000-0000-0000-000000000010',
                module_title: 'Msingi uliopo',
                module_status: 'published',
                lesson_id: '00000000-0000-0000-0000-000000000100',
                lesson_title: 'Utangulizi',
                lesson_body: 'Maandishi',
                lesson_type: 'reading',
                duration_minutes: 5,
                lesson_status: 'published',
                lesson_link_status: 'linked',
                has_source_link: true,
                has_grounding: true,
              },
            ],
          };
        },
        connect: async () => {
          throw new Error('Legacy save must not open a replacement transaction.');
        },
      },
      catalog: {},
      schema: 'public',
    });

    const saved = await store.upsertContentCourse({
      status: 'approved',
      course: {
        id: 'NYANYA-001',
        title: 'Jina jipya',
        description: 'Maelezo mapya',
        badge: 'Kozi ya maandishi',
        icon: 'menu_book',
        imageUrl: 'assets/images/courses/nyanya.jpg',
        outcomes: ['Msingi uliopo'],
        lessons: [
          {
            id: '00000000-0000-0000-0000-000000000100',
            title: 'Utangulizi',
            type: 'reading',
            meta: 'Dakika 5',
            description: 'Maandishi',
          },
        ],
      },
    });

    assert.equal(saved.course.title, 'Jina jipya');
    assert.equal(
      calls.some(({ sql }) => /DELETE FROM|INSERT INTO course_modules/.test(sql)),
      false,
    );
  }),
);

test(
  'admin create-only course save rejects a duplicate course code',
  withSupabaseStore(async () => {
    const calls = [];
    const client = {
      query: async (sql) => {
        calls.push(sql);
        if (/SELECT id, status::text AS status, updated_at/.test(sql)) {
          return {
            rows: [
              {
                id: '00000000-0000-0000-0000-000000000901',
                status: 'published',
                updated_at: '2026-07-26T12:00:00.000Z',
              },
            ],
          };
        }
        return { rows: [] };
      },
      release() {},
    };
    const store = new PostgresStore({
      pool: { connect: async () => client },
      catalog: {},
      schema: 'public',
    });

    await assert.rejects(
      () =>
        store.upsertContentCourse({
          status: 'draft',
          createOnly: true,
          course: {
            id: 'CRS-MAH-01',
            title: 'Kozi nyingine',
            description: 'Haipaswi kubadilisha kozi iliyopo.',
            badge: 'Kozi ya maandishi',
            icon: 'menu_book',
            imageUrl: 'assets/images/courses/nyanya.jpg',
            outcomes: ['Sehemu'],
            lessons: [
              {
                moduleKey: 'sehemu',
                moduleTitle: 'Sehemu',
                title: 'Somo',
                type: 'reading',
                meta: 'Dakika 5',
                description: 'Maandishi ya somo.',
              },
            ],
          },
        }),
      (error) => error.code === 'COURSE_ALREADY_EXISTS',
    );
    assert.ok(calls.includes('ROLLBACK'));
    assert.equal(calls.includes('COMMIT'), false);
  }),
);

test(
  'trusted admin can create and publish a structured course in one save',
  withSupabaseStore(async () => {
    const calls = [];
    const courseId = '00000000-0000-0000-0000-000000000901';
    const moduleId = '00000000-0000-0000-0000-000000000902';
    const lessonId = '00000000-0000-0000-0000-000000000903';
    const client = {
      query: async (sql, params) => {
        calls.push({ sql, params });
        if (/SELECT id, status::text AS status, updated_at/.test(sql)) {
          return { rows: [] };
        }
        if (/INSERT INTO courses/.test(sql)) {
          return {
            rows: [
              {
                id: courseId,
                status: 'draft',
                updated_at: '2026-07-26T12:00:00.000Z',
              },
            ],
          };
        }
        if (/SELECT id::text, code, title_sw, status::text AS status/.test(sql)) {
          return { rows: [] };
        }
        if (/l\.id::text,[\s\S]*l\.module_id::text/.test(sql)) {
          return { rows: [] };
        }
        if (/INSERT INTO course_modules/.test(sql)) {
          return { rows: [{ id: moduleId }] };
        }
        if (/SELECT id::text FROM lessons/.test(sql)) {
          return { rows: [] };
        }
        if (/INSERT INTO lessons/.test(sql)) {
          return { rows: [{ id: lessonId }] };
        }
        return { rows: [] };
      },
      release() {},
    };
    const store = new PostgresStore({
      pool: {
        connect: async () => client,
        query: async (sql) => {
          calls.push({ sql, params: [] });
          if (/UPDATE courses/.test(sql)) return { rows: [] };
          assert.match(sql, /FROM courses c/);
          return {
            rows: [
              {
                course_id: courseId,
                course_code: 'CRS-MAH-01',
                course_title: 'Kilimo cha Maharage',
                course_description: 'Mtaala mpya wa maharage.',
                delivery_type: 'text',
                course_status: 'published',
                course_updated_at: '2026-07-26T12:00:00.000Z',
                module_id: moduleId,
                module_title: 'Maandalizi',
                module_status: 'published',
                lesson_id: lessonId,
                lesson_title: 'Chagua shamba',
                lesson_body: 'Kagua eneo na udongo kabla ya kupanda.',
                lesson_type: 'reading',
                duration_minutes: 5,
                lesson_status: 'published',
                lesson_link_status: 'linked',
                has_source_link: false,
                has_grounding: false,
              },
            ],
          };
        },
      },
      catalog: {},
      schema: 'public',
    });

    const saved = await store.upsertContentCourse({
      status: 'approved',
      createOnly: true,
      course: {
        id: 'CRS-MAH-01',
        title: 'Kilimo cha Maharage',
        description: 'Mtaala mpya wa maharage.',
        badge: 'Kozi ya maandishi',
        icon: 'menu_book',
        imageUrl: 'assets/images/courses/nyanya.jpg',
        outcomes: ['Maandalizi'],
        lessons: [
          {
            moduleKey: 'maandalizi',
            moduleTitle: 'Maandalizi',
            title: 'Chagua shamba',
            type: 'reading',
            meta: 'Dakika 5',
            description: 'Kagua eneo na udongo kabla ya kupanda.',
            durationMinutes: 5,
          },
        ],
      },
    });

    assert.equal(saved.status, 'approved');
    assert.equal(saved.course.lessons[0].readiness.visible, true);
    assert.ok(calls.some(({ sql }) => /INSERT INTO courses/.test(sql)));
    assert.ok(calls.some(({ sql }) => /INSERT INTO course_modules/.test(sql)));
    assert.ok(calls.some(({ sql }) => /INSERT INTO lessons/.test(sql)));
    assert.ok(
      calls.some(
        ({ sql, params }) =>
          /UPDATE course_modules[\s\S]*status = \$2::content_status/.test(sql) &&
          params[1] === 'published',
      ),
    );
    assert.ok(
      calls.some(
        ({ sql, params }) =>
          /UPDATE lessons l[\s\S]*status = \$2::content_status/.test(sql) &&
          params[1] === 'published',
      ),
    );
    assert.ok(
      calls.some(
        ({ sql, params }) =>
          /UPDATE lesson_resources lr[\s\S]*status = \$2::content_status/.test(
            sql,
          ) && params[1] === 'published',
      ),
    );
    assert.equal(
      calls.some(
        ({ sql }) =>
          /UPDATE lesson_resources lr[\s\S]*published_at/.test(sql),
      ),
      false,
    );
    assert.ok(calls.some(({ sql }) => sql === 'COMMIT'));
  }),
);

test(
  'published structured courses do not require third-party source-review rows',
  withSupabaseStore(async () => {
    let queryText = '';
    const store = new PostgresStore({
      pool: {
        query: async (sql) => {
          queryText = sql;
          return {
            rows: [
              {
                course_id: 'course-uuid',
                course_code: 'AJE-ORIGINAL-001',
                course_title: 'Kilimo cha Maharage',
                course_description: 'Kozi iliyoandikwa na AJE.',
                delivery_type: 'text',
                module_id: 'module-uuid',
                module_title: 'Maandalizi',
                module_order: 0,
                lesson_id: 'lesson-uuid',
                lesson_title: 'Chagua shamba',
                lesson_body: 'Kagua eneo na udongo kabla ya kupanda.',
                lesson_type: 'reading',
                duration_minutes: 5,
                lesson_order: 0,
                source_title: null,
                video_url: null,
                video_storage_path: null,
              },
            ],
          };
        },
      },
      catalog: {},
      schema: 'public',
    });

    const courses = await store.approvedContentCourses();

    assert.equal(courses.length, 1);
    assert.equal(courses[0].id, 'AJE-ORIGINAL-001');
    assert.equal(courses[0].lessons.length, 1);
    const visibilityFilter = queryText.slice(queryText.indexOf('WHERE c.status'));
    assert.doesNotMatch(visibilityFilter, /content_source_links/);
    assert.doesNotMatch(visibilityFilter, /grounding_facts/);
  }),
);

test(
  'admin source review lists approved segments and approves a lesson atomically',
  withSupabaseStore(async () => {
    const calls = [];
    const client = {
      query: async (sql, params) => {
        calls.push({ sql, params });
        if (/FROM lessons l[\s\S]*CROSS JOIN source_segments/.test(sql)) {
          return {
            rows: [
              {
                lesson_id: '00000000-0000-0000-0000-000000000903',
                module_id: '00000000-0000-0000-0000-000000000902',
                course_id: '00000000-0000-0000-0000-000000000901',
                course_code: 'CRS-MAH-01',
                lesson_type: 'reading',
                body_sw: 'Kagua eneo na udongo kabla ya kupanda.',
                has_video: false,
                source_segment_id:
                  '00000000-0000-0000-0000-000000000904',
                source_document_id:
                  '00000000-0000-0000-0000-000000000905',
              },
            ],
          };
        }
        if (/UPDATE courses[\s\S]*RETURNING updated_at/.test(sql)) {
          return {
            rows: [{ updated_at: '2026-07-26T12:30:00.000Z' }],
          };
        }
        return { rows: [] };
      },
      release() {},
    };
    const store = new PostgresStore({
      pool: {
        connect: async () => client,
        query: async (sql, params) => {
          calls.push({ sql, params });
          return {
            rows: [
              {
                id: '00000000-0000-0000-0000-000000000904',
                document_id: '00000000-0000-0000-0000-000000000905',
                document_title: 'Mwongozo wa Maharage',
                section_title: 'Maandalizi',
                page_start: 10,
                page_end: 12,
                time_start_seconds: null,
                time_end_seconds: null,
                content_preview: 'Chagua eneo na udongo unaofaa.',
              },
            ],
          };
        },
      },
      catalog: {},
      schema: 'public',
    });

    const segments = await store.sourceSegmentsForAdmin({
      search: 'maharage',
      limit: 20,
    });
    assert.equal(segments.length, 1);
    assert.equal(segments[0].documentTitle, 'Mwongozo wa Maharage');
    assert.equal(segments[0].locationLabel, 'Kurasa 10-12');

    const approved = await store.approveLessonSource({
      lessonId: '00000000-0000-0000-0000-000000000903',
      sourceSegmentId: '00000000-0000-0000-0000-000000000904',
      evidenceNote: 'Sehemu hii inaunga mkono somo.',
      groundingFact: 'Udongo unaopitisha maji hupunguza kutuama.',
      reviewerActorId: 'user-20260726-admin',
    });

    assert.equal(approved.status, 'approved');
    assert.equal(approved.contentReady, true);
    assert.equal(approved.courseUpdatedAt, '2026-07-26T12:30:00.000Z');
    assert.ok(
      calls.some(({ sql }) => /INSERT INTO content_source_links/.test(sql)),
    );
    assert.ok(calls.some(({ sql }) => /INSERT INTO grounding_facts/.test(sql)));
    assert.ok(calls.some(({ sql }) => /INSERT INTO content_change_log/.test(sql)));
    assert.ok(
      calls.some(
        ({ sql }) =>
          /UPDATE lessons/.test(sql) &&
          /source_link_status = 'linked'/.test(sql),
      ),
    );
    assert.ok(calls.some(({ sql }) => sql === 'COMMIT'));
    assert.equal(calls.some(({ sql }) => sql === 'ROLLBACK'), false);
  }),
);

test(
  'admin source review publishes an attached video resource atomically',
  withSupabaseStore(async () => {
    const calls = [];
    const client = {
      query: async (sql, params) => {
        calls.push({ sql, params });
        if (/FROM lessons l[\s\S]*CROSS JOIN source_segments/.test(sql)) {
          return {
            rows: [
              {
                lesson_id: '00000000-0000-0000-0000-000000000913',
                module_id: '00000000-0000-0000-0000-000000000912',
                course_id: '00000000-0000-0000-0000-000000000911',
                course_code: 'RICE-VIDEO-01',
                lesson_type: 'video',
                body_sw: '',
                has_video: true,
                source_segment_id:
                  '00000000-0000-0000-0000-000000000914',
                source_document_id:
                  '00000000-0000-0000-0000-000000000915',
              },
            ],
          };
        }
        if (/UPDATE courses[\s\S]*RETURNING updated_at/.test(sql)) {
          return {
            rows: [{ updated_at: '2026-07-26T12:40:00.000Z' }],
          };
        }
        return { rows: [] };
      },
      release() {},
    };
    const store = new PostgresStore({
      pool: { connect: async () => client },
      catalog: {},
      schema: 'public',
    });

    const approved = await store.approveLessonSource({
      lessonId: '00000000-0000-0000-0000-000000000913',
      sourceSegmentId: '00000000-0000-0000-0000-000000000914',
      evidenceNote: 'Video hii inaonyesha aina ya mbegu.',
      groundingFact: 'Mbegu iliyothibitishwa husaidia kuanza zao salama.',
    });

    assert.equal(approved.contentReady, true);
    assert.ok(
      calls.some(
        ({ sql }) =>
          /UPDATE lesson_resources/.test(sql) &&
          /status = 'published'/.test(sql),
      ),
    );
    assert.ok(calls.some(({ sql }) => sql === 'COMMIT'));
  }),
);

test(
  'structured curriculum save rejects a stale editor revision and rolls back',
  withSupabaseStore(async () => {
    const calls = [];
    const client = {
      query: async (sql) => {
        calls.push(sql);
        if (/SELECT id, status::text AS status, updated_at/.test(sql)) {
          return {
            rows: [
              {
                id: '00000000-0000-0000-0000-000000000001',
                status: 'published',
                updated_at: '2026-07-26T10:10:00.000Z',
              },
            ],
          };
        }
        return { rows: [] };
      },
      release() {},
    };
    const store = new PostgresStore({
      pool: { connect: async () => client },
      catalog: {},
      schema: 'public',
    });

    await assert.rejects(
      () =>
        store.saveCourseCurriculum('NYANYA-001', {
          baseUpdatedAt: '2026-07-26T10:00:00.000Z',
          status: 'approved',
          title: 'Nyanya',
          description: 'Maelezo',
          deliveryType: 'text',
          lessons: [],
        }),
      (error) => error.code === 'CURRICULUM_CONFLICT',
    );
    assert.ok(calls.includes('ROLLBACK'));
    assert.equal(calls.includes('COMMIT'), false);
  }),
);

test(
  'admin document listing and save use structured source documents',
  withSupabaseStore(async () => {
    let request = 0;
    const store = new PostgresStore({
      pool: {
        query: async (sql, params) => {
          request += 1;
          if (request === 1) {
            assert.match(sql, /FROM source_documents/);
            return {
              rows: [
                {
                  id: '00000000-0000-0000-0000-000000000001',
                  title: 'Mwongozo',
                  source_type: 'pdf',
                  file_name: 'mwongozo.pdf',
                  page_count: 12,
                  metadata: { imageUrl: 'https://example.test/book.jpg', introVideoUrl: 'https://example.test/book.mp4' },
                  processing_status: 'approved',
                  updated_at: '2026-07-26T10:00:00.000Z',
                },
              ],
            };
          }
          assert.match(sql, /UPDATE source_documents/);
          assert.deepEqual(params, [
            '00000000-0000-0000-0000-000000000001',
            'Mwongozo Mpya',
            'published',
            JSON.stringify({ imageUrl: 'https://example.test/book.jpg', introVideoUrl: 'https://example.test/book.mp4' }),
          ]);
          return {
            rows: [
              {
                id: '00000000-0000-0000-0000-000000000001',
                processing_status: 'published',
                updated_at: '2026-07-26T10:10:00.000Z',
              },
            ],
          };
        },
      },
      catalog: {},
      schema: 'public',
    });

    const documents = await store.contentDocumentsForAdmin();
    assert.equal(documents[0].document.sizeLabel, 'Kurasa 12');
    assert.equal(documents[0].document.imageUrl, 'https://example.test/book.jpg');

    const saved = await store.upsertContentDocument({
      status: 'approved',
      document: {
        ...documents[0].document,
        title: 'Mwongozo Mpya',
      },
    });
    assert.equal(saved.status, 'approved');
    assert.equal(saved.document.title, 'Mwongozo Mpya');
  }),
);
