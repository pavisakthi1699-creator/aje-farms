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
                module_title: 'Msingi',
                lesson_id: 'lesson-uuid',
                lesson_title: 'Utangulizi',
                lesson_body: 'Somo la kwanza',
                lesson_type: 'reading',
                duration_minutes: 5,
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
  }),
);

test(
  'admin course save updates the structured course used by learners',
  withSupabaseStore(async () => {
    const calls = [];
    const store = new PostgresStore({
      pool: {
        query: async (sql, params) => {
          calls.push({ sql, params });
          return {
            rows: [
              {
                code: 'NYANYA-001',
                status: 'published',
                updated_at: '2026-07-26T10:05:00.000Z',
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
      course: {
        id: 'NYANYA-001',
        title: 'Nyanya Bora',
        description: 'Mafunzo ya nyanya',
        badge: 'Kozi ya maandishi',
        icon: 'menu_book',
        imageUrl: 'assets/images/courses/nyanya.jpg',
        outcomes: [],
        lessons: [],
      },
    });

    assert.match(calls[0].sql, /UPDATE courses/);
    assert.deepEqual(calls[0].params, [
      'NYANYA-001',
      'Nyanya Bora',
      'published',
    ]);
    assert.equal(record.status, 'approved');
    assert.equal(record.course.title, 'Nyanya Bora');
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
