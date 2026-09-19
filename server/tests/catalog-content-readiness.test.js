import assert from 'node:assert/strict';
import test from 'node:test';

import { catalog } from '../catalog.js';
import { isLearnerReadyCourse } from '../store/utils.js';

test('built-in courses make only supported, uncompleted reading claims', () => {
  for (const course of catalog.courses) {
    assert.equal(course.contentVersion, 2);
    assert.equal(course.progress, 0);
    assert.ok(course.lessons.length > 0);
    for (const lesson of course.lessons) {
      assert.equal(lesson.type, 'reading');
      assert.notEqual(lesson.isCompleted, true);
      assert.notEqual(lesson.isPremium, true);
      assert.doesNotMatch(lesson.meta, /\bMB\b|\bDKK\b/);
    }
  }
});

test('high-risk, unreviewed, and incomplete imported courses stay hidden', () => {
  assert.equal(
    isLearnerReadyCourse({
      status: 'needs_review',
      riskLevel: 'high',
      lessons: [],
      contentGaps: [],
    }),
    false,
  );
  assert.equal(
    isLearnerReadyCourse({
      modules: [{ status: 'approved', riskLevel: 'normal' }],
      lessons: [{ status: 'needs_review', riskLevel: 'high' }],
      contentGaps: [],
    }),
    false,
  );
  assert.equal(
    isLearnerReadyCourse({
      modules: [{ status: 'approved', riskLevel: 'normal' }],
      lessons: [{ status: 'approved', riskLevel: 'normal' }],
      contentGaps: [{ title: 'Missing source' }],
    }),
    false,
  );
  assert.equal(
    isLearnerReadyCourse({
      modules: [{ status: 'published', riskLevel: 'normal' }],
      lessons: [
        { type: 'reading', status: 'approved', riskLevel: 'normal' },
      ],
      contentGaps: [],
    }),
    true,
  );
  assert.equal(
    isLearnerReadyCourse({
      lessons: [{ type: 'quiz', status: 'approved', riskLevel: 'normal' }],
      contentGaps: [],
    }),
    false,
  );
});

test('built-in community contains only evergreen official guidance', () => {
  assert.equal(catalog.communityPosts.length, 1);
  const post = catalog.communityPosts[0];
  assert.equal(post.author, 'Timu ya Chuo Kikuu Cha Mtaani');
  assert.equal(post.likes, 0);
  assert.equal(post.comments, 0);
  assert.deepEqual(post.replies, []);
  assert.doesNotMatch(post.content.toLowerCase(), /bei.*(leo|imepanda)/);
  assert.doesNotMatch(post.time.toLowerCase(), /leo|saa .*zilizopita/);
});
