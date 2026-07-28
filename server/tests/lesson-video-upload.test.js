import assert from 'node:assert/strict';
import test from 'node:test';

import { PostgresStore } from '../store/postgres-store.js';
import {
  extensionForVideoContentType,
  isValidLessonVideoPath,
} from '../store/utils.js';

function withSupabaseEnv(run) {
  return async () => {
    const previous = {
      store: process.env.AJE_STORE,
      url: process.env.SUPABASE_URL,
      key: process.env.SUPABASE_SERVICE_ROLE_KEY,
    };
    const previousFetch = globalThis.fetch;
    process.env.AJE_STORE = 'supabase';
    process.env.SUPABASE_URL = 'https://example.supabase.co';
    process.env.SUPABASE_SERVICE_ROLE_KEY = 'service-role-key';
    try {
      await run();
    } finally {
      globalThis.fetch = previousFetch;
      for (const [name, value] of [
        ['AJE_STORE', previous.store],
        ['SUPABASE_URL', previous.url],
        ['SUPABASE_SERVICE_ROLE_KEY', previous.key],
      ]) {
        if (value == null) delete process.env[name];
        else process.env[name] = value;
      }
    }
  };
}

test('video content types map to the extensions the bucket accepts', () => {
  assert.equal(extensionForVideoContentType('video/mp4'), 'mp4');
  assert.equal(extensionForVideoContentType('video/quicktime'), 'mov');
  assert.equal(extensionForVideoContentType('video/webm'), 'webm');
  assert.equal(extensionForVideoContentType('video/mp4; codecs=avc1'), 'mp4');
  assert.equal(extensionForVideoContentType('application/pdf'), null);
  assert.equal(extensionForVideoContentType(undefined), null);
});

test('lesson video paths are confined to the lesson-videos prefix', () => {
  assert.equal(isValidLessonVideoPath('lesson-videos/vid-123-abc.mp4'), true);
  assert.equal(isValidLessonVideoPath('lesson-videos/vid-1.mov'), true);
  assert.equal(isValidLessonVideoPath('lesson-videos/vid-1.webm'), true);

  // The bucket also holds unpublished source documents, so anything that
  // escapes the prefix has to be refused.
  assert.equal(isValidLessonVideoPath('source-pdfs/secret.mp4'), false);
  assert.equal(isValidLessonVideoPath('lesson-videos/../secret.mp4'), false);
  assert.equal(isValidLessonVideoPath('lesson-videos/nested/vid.mp4'), false);
  assert.equal(isValidLessonVideoPath('lesson-videos/vid.exe'), false);
  assert.equal(isValidLessonVideoPath(''), false);
  assert.equal(isValidLessonVideoPath(null), false);
  assert.equal(
    isValidLessonVideoPath(`lesson-videos/${'a'.repeat(220)}.mp4`),
    false,
  );
});

test(
  'signed upload URL is minted for the private lesson video bucket',
  withSupabaseEnv(async () => {
    let requestedUrl = '';
    let requestedBody = '';
    globalThis.fetch = async (url, init) => {
      requestedUrl = String(url);
      requestedBody = String(init.body);
      return {
        ok: true,
        json: async () => ({
          url: '/object/upload/sign/source-documents/lesson-videos/vid-1.mp4?token=abc',
        }),
      };
    };
    const store = new PostgresStore({
      pool: {},
      catalog: {},
      schema: 'public',
    });

    const upload = await store.createLessonVideoUploadUrl({
      contentType: 'video/mp4',
    });

    assert.ok(upload, 'expected an upload target');
    assert.match(upload.videoPath, /^lesson-videos\/vid-[\w-]+\.mp4$/);
    assert.equal(isValidLessonVideoPath(upload.videoPath), true);
    assert.equal(
      upload.uploadUrl,
      'https://example.supabase.co/storage/v1/object/upload/sign/source-documents/lesson-videos/vid-1.mp4?token=abc',
    );
    assert.match(requestedUrl, /\/storage\/v1\/object\/upload\/sign\//);
    assert.match(requestedUrl, /source-documents/);
    assert.match(requestedBody, /expiresIn/);
  }),
);

test(
  'an unsupported video type yields no upload target',
  withSupabaseEnv(async () => {
    globalThis.fetch = async () => {
      throw new Error('should not reach storage');
    };
    const store = new PostgresStore({
      pool: {},
      catalog: {},
      schema: 'public',
    });

    assert.equal(
      await store.createLessonVideoUploadUrl({ contentType: 'video/avi' }),
      null,
    );
  }),
);

test('video upload is unavailable outside Supabase mode', async () => {
  const previous = process.env.AJE_STORE;
  delete process.env.AJE_STORE;
  try {
    const store = new PostgresStore({
      pool: {},
      catalog: {},
      schema: 'public',
    });
    assert.equal(
      await store.createLessonVideoUploadUrl({ contentType: 'video/mp4' }),
      null,
    );
  } finally {
    if (previous == null) delete process.env.AJE_STORE;
    else process.env.AJE_STORE = previous;
  }
});

test(
  'an uploaded video is stored as a storage path, not an external URL',
  withSupabaseEnv(async () => {
    const resourceWrites = [];
    const client = {
      query: async (sql, params) => {
        if (/SELECT id, status::text AS status, updated_at/.test(sql)) {
          return {
            rows: [
              {
                id: '00000000-0000-0000-0000-000000000001',
                status: 'draft',
                updated_at: '2026-07-26T10:00:00.000Z',
              },
            ],
          };
        }
        if (/INSERT INTO course_modules/.test(sql)) {
          return { rows: [{ id: '00000000-0000-0000-0000-000000000010' }] };
        }
        if (/INSERT INTO lessons/.test(sql)) {
          return { rows: [{ id: '00000000-0000-0000-0000-000000000020' }] };
        }
        if (/lesson_resources/.test(sql)) {
          resourceWrites.push({ sql, params });
          return { rows: [] };
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
    store.courseCurriculum = async () => ({ stub: true });

    await store.saveCourseCurriculum('CRS-VID-01', {
      status: 'draft',
      title: 'Kozi ya Video',
      description: 'Maelezo',
      deliveryType: 'video',
      lessons: [
        {
          moduleKey: 'new-1',
          moduleTitle: 'Sehemu ya video',
          title: 'Somo la video',
          type: 'video',
          meta: 'Dakika 5',
          body: '',
          durationMinutes: 5,
          videoUrl: null,
          videoPath: 'lesson-videos/vid-abc.mp4',
        },
      ],
    });

    const insert = resourceWrites.find(({ sql }) =>
      /INSERT INTO lesson_resources/.test(sql),
    );
    assert.ok(insert, 'expected a lesson_resources insert');
    assert.equal(insert.params[1], null, 'external_url must stay empty');
    assert.equal(insert.params[2], 'lesson-videos/vid-abc.mp4');
  }),
);

test(
  'creating a course does not cast import_source to a non-existent enum',
  withSupabaseEnv(async () => {
    // The live `courses.import_source` is a text column and there is no
    // `import_source` enum type, so casting made every new-course insert fail
    // with 'type "import_source" does not exist'.
    let courseInsert = '';
    const client = {
      query: async (sql) => {
        if (/INSERT INTO courses/.test(sql)) {
          courseInsert = sql;
          return {
            rows: [
              {
                id: '00000000-0000-0000-0000-000000000001',
                status: 'draft',
                updated_at: '2026-07-26T10:00:00.000Z',
              },
            ],
          };
        }
        if (/INSERT INTO course_modules/.test(sql)) {
          return { rows: [{ id: '00000000-0000-0000-0000-000000000010' }] };
        }
        if (/INSERT INTO lessons/.test(sql)) {
          return { rows: [{ id: '00000000-0000-0000-0000-000000000020' }] };
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
    store.courseCurriculum = async () => ({ stub: true });

    await store.saveCourseCurriculum('CRS-NEW-01', {
      createIfMissing: true,
      failIfExists: true,
      status: 'draft',
      title: 'Kozi Mpya',
      description: 'Maelezo',
      deliveryType: 'text',
      lessons: [
        {
          moduleKey: 'new-1',
          moduleTitle: 'Sehemu mpya',
          title: 'Somo la kwanza',
          type: 'reading',
          meta: 'Dakika 5',
          body: 'Maandishi',
          durationMinutes: 5,
        },
      ],
    });

    assert.match(courseInsert, /INSERT INTO courses/);
    assert.doesNotMatch(courseInsert, /::import_source/);
  }),
);

test(
  'an uploaded video replaces a previously pasted link',
  withSupabaseEnv(async () => {
    const resourceWrites = [];
    const client = {
      query: async (sql, params) => {
        if (/SELECT id, status::text AS status, updated_at/.test(sql)) {
          return {
            rows: [
              {
                id: '00000000-0000-0000-0000-000000000001',
                status: 'draft',
                updated_at: '2026-07-26T10:00:00.000Z',
              },
            ],
          };
        }
        if (/SELECT\s+id::text,\s+code, title_sw/.test(sql)) {
          return {
            rows: [
              {
                id: '00000000-0000-0000-0000-000000000010',
                code: 'MOD-1',
                title_sw: 'Sehemu ya video',
                status: 'draft',
              },
            ],
          };
        }
        if (/AS video_storage_path\s+FROM lessons l/.test(sql)) {
          return {
            rows: [
              {
                id: '00000000-0000-0000-0000-000000000020',
                module_id: '00000000-0000-0000-0000-000000000010',
                body_sw: null,
                lesson_type: 'video',
                video_url: 'https://example.com/old.mp4',
                video_storage_path: null,
              },
            ],
          };
        }
        if (/SELECT id::text FROM lessons WHERE module_id/.test(sql)) {
          return { rows: [{ id: '00000000-0000-0000-0000-000000000020' }] };
        }
        if (/UPDATE lesson_resources/.test(sql)) {
          resourceWrites.push({ sql, params });
          return { rows: [{ id: 'resource-1' }] };
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
    store.courseCurriculum = async () => ({ stub: true });

    await store.saveCourseCurriculum('CRS-VID-01', {
      status: 'draft',
      title: 'Kozi ya Video',
      description: 'Maelezo',
      deliveryType: 'video',
      lessons: [
        {
          id: '00000000-0000-0000-0000-000000000020',
          moduleId: '00000000-0000-0000-0000-000000000010',
          moduleTitle: 'Sehemu ya video',
          title: 'Somo la video',
          type: 'video',
          meta: 'Dakika 5',
          body: '',
          durationMinutes: 5,
          videoUrl: 'https://example.com/old.mp4',
          videoPath: 'lesson-videos/vid-new.mp4',
        },
      ],
    });

    const update = resourceWrites[0];
    assert.ok(update, 'expected a lesson_resources update');
    assert.equal(update.params[1], null, 'the stale link must be cleared');
    assert.equal(update.params[2], 'lesson-videos/vid-new.mp4');
    assert.equal(update.params[4], true, 'a new video must re-enter review');
  }),
);
