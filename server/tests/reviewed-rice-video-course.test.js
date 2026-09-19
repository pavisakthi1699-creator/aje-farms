import assert from "node:assert/strict";
import test from "node:test";

import { REVIEWED_RICE_VIDEO_COURSE } from "../scripts/reviewed-rice-video-course.js";
import {
  PostgresStore,
  resolveSupabaseSignedUrl,
} from "../store/postgres-store.js";

test("reviewed rice course is a three-lesson video course", () => {
  assert.equal(REVIEWED_RICE_VIDEO_COURSE.code, "RICE-SEED-001");
  assert.equal(REVIEWED_RICE_VIDEO_COURSE.lessons.length, 3);
  assert.equal(REVIEWED_RICE_VIDEO_COURSE.videoDurationSeconds, 244);
  assert.match(REVIEWED_RICE_VIDEO_COURSE.videoStoragePath, /\.mp4$/);
  assert.match(REVIEWED_RICE_VIDEO_COURSE.transcriptStoragePath, /\.txt$/);

  for (const lesson of REVIEWED_RICE_VIDEO_COURSE.lessons) {
    assert.ok(lesson.body.length > 150, lesson.lessonCode);
    assert.ok(lesson.evidence.length > 120, lesson.lessonCode);
    assert.ok(lesson.fact.length > 80, lesson.lessonCode);
    assert.ok(lesson.question.endsWith("?"), lesson.lessonCode);
    assert.match(`${lesson.body} ${lesson.fact}`, /TARI|afisa ugani|wataalamu/iu);
  }
});

test("video lessons frame variety claims as observations and omit unsafe inputs", () => {
  const text = REVIEWED_RICE_VIDEO_COURSE.lessons
    .flatMap((lesson) => [lesson.body, lesson.evidence, lesson.fact])
    .join(" ");

  assert.match(text, /mzungumzaji/iu);
  assert.doesNotMatch(text, /\b\d+(?:[.,]\d+)?\s*(?:%|ml|gramu|kg|kilo|lita)\b/iu);
  assert.doesNotMatch(text, /\b(?:dawa|kiuatilifu|mbolea)\s+(?:tumia|weka)\b/iu);
  assert.doesNotMatch(text, /dhamana ya mavuno|utavuna|faida ya/iu);
});

test("Supabase signed storage paths retain the storage API prefix", () => {
  const result = resolveSupabaseSignedUrl(
    "https://project.supabase.co",
    "/object/sign/source-documents/video/rice.mp4?token=secret",
  );
  const url = new URL(result);

  assert.equal(
    url.pathname,
    "/storage/v1/object/sign/source-documents/video/rice.mp4",
  );
  assert.equal(url.searchParams.get("token"), "secret");
});

test("published reading lessons resolve their linked source book", async () => {
  const previousStore = process.env.AJE_STORE;
  const previousUrl = process.env.SUPABASE_URL;
  const previousKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  const previousFetch = globalThis.fetch;
  let queryText = "";
  let requestedUrl = "";

  process.env.AJE_STORE = "supabase";
  process.env.SUPABASE_URL = "https://project.supabase.co";
  process.env.SUPABASE_SERVICE_ROLE_KEY = "service-role-test";
  let signedRequest;
  globalThis.fetch = async (url, request) => {
    requestedUrl = String(url);
    signedRequest = request;
    return {
      ok: true,
      async json() {
        return {
          signedURL:
            "/object/sign/source-documents/books/Kilimo%20cha%20Mpunga.pdf?token=secret",
        };
      },
    };
  };

  const store = new PostgresStore({
    pool: {
      async query(text, values) {
        queryText = text;
        assert.deepEqual(values, ["lesson-1"]);
        return {
          rows: [
            {
              storage_bucket: "source-documents",
              storage_path: "books/Kilimo cha Mpunga.pdf",
            },
          ],
        };
      },
    },
    catalog: {},
    schema: "public",
  });

  try {
    const url = await store.lessonSourceDocumentUrl("lesson-1");

    assert.match(queryText, /l\.lesson_type = 'reading'/);
    assert.match(queryText, /csl\.link_status = 'linked'/);
    assert.match(queryText, /sd\.processing_status IN \('approved', 'published'\)/);
    assert.equal(
      requestedUrl,
      "https://project.supabase.co/storage/v1/object/sign/source-documents/books/Kilimo%20cha%20Mpunga.pdf",
    );
    assert.equal(
      url,
      "https://project.supabase.co/storage/v1/object/sign/source-documents/books/Kilimo%20cha%20Mpunga.pdf?token=secret",
    );
    assert.deepEqual(JSON.parse(signedRequest.body), { expiresIn: 3600 });
  } finally {
    globalThis.fetch = previousFetch;
    if (previousStore == null) delete process.env.AJE_STORE;
    else process.env.AJE_STORE = previousStore;
    if (previousUrl == null) delete process.env.SUPABASE_URL;
    else process.env.SUPABASE_URL = previousUrl;
    if (previousKey == null) delete process.env.SUPABASE_SERVICE_ROLE_KEY;
    else process.env.SUPABASE_SERVICE_ROLE_KEY = previousKey;
  }
});
