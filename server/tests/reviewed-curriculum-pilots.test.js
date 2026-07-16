import assert from "node:assert/strict";
import test from "node:test";

import {
  EXCLUDED_STAGING_ITEM_TYPES,
  REVIEWED_CURRICULUM_CODES,
  REVIEWED_CURRICULUM_PILOTS,
} from "../scripts/reviewed-curriculum-pilots.js";

test("reviewed curriculum pilots cover all nine staged books", () => {
  assert.equal(REVIEWED_CURRICULUM_PILOTS.length, 9);
  assert.equal(new Set(REVIEWED_CURRICULUM_CODES).size, 9);
});

test("every pilot has exactly three manually cited learner lessons", () => {
  for (const course of REVIEWED_CURRICULUM_PILOTS) {
    assert.equal(course.lessons.length, 3, course.code);
    assert.ok(course.pageCount > 0, course.code);
    for (const lesson of course.lessons) {
      assert.ok(lesson.title.length > 0, course.code);
      assert.ok(lesson.body.length > 80, `${course.code}: ${lesson.title}`);
      assert.ok(lesson.evidence.length > 60, `${course.code}: ${lesson.title}`);
      assert.ok(lesson.fact.length > 40, `${course.code}: ${lesson.title}`);
      assert.ok(lesson.question.endsWith("?"), `${course.code}: ${lesson.title}`);
      assert.ok(lesson.pageStart > 0, `${course.code}: ${lesson.title}`);
      assert.ok(lesson.pageEnd >= lesson.pageStart, `${course.code}: ${lesson.title}`);
      assert.ok(lesson.pageEnd <= course.pageCount, `${course.code}: ${lesson.title}`);
    }
  }
});

test("learner lessons omit exact input rates, treatment recipes, and unsupported promises", () => {
  const forbidden = [
    /\b\d+(?:[.,]\d+)?\s*%/u,
    /\b\d+(?:[.,]\d+)?\s*(?:ml|gramu|kg|kilo|lita)\b/iu,
    /\b(?:amoxicillin|oxytetracycline|tylosin|sulphadimidine)\b/iu,
    /\b(?:utapata|utavuna|faida ya)\s+(?:shilingi|milioni|asilimia)\b/iu,
  ];
  for (const course of REVIEWED_CURRICULUM_PILOTS) {
    for (const lesson of course.lessons) {
      for (const pattern of forbidden) {
        assert.doesNotMatch(lesson.body, pattern, `${course.code}: ${lesson.title}`);
        assert.doesNotMatch(lesson.fact, pattern, `${course.code}: ${lesson.title}`);
      }
    }
  }
});

test("publication excludes generated learner adjuncts from later promotion", () => {
  assert.deepEqual(
    EXCLUDED_STAGING_ITEM_TYPES,
    ["quiz", "checklist", "faq"],
  );
});
