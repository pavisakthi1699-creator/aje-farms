import assert from "node:assert/strict";
import test from "node:test";

import { REVIEWED_RICE_VIDEO_COURSE } from "../scripts/reviewed-rice-video-course.js";
import { resolveSupabaseSignedUrl } from "../store/postgres-store.js";

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
