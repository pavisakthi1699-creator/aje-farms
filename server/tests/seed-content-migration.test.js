import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';

import { catalog } from '../catalog.js';
import { JsonStore } from '../store/json-store.js';

function tempDataFile() {
  return path.join(
    os.tmpdir(),
    `aje-content-migration-${Date.now()}-${Math.random().toString(36).slice(2)}.json`,
  );
}

test('stale built-in content upgrades once without overwriting editor changes', () => {
  const filePath = tempDataFile();
  fs.writeFileSync(
    filePath,
    JSON.stringify({
      contentCourses: [
        {
          id: 'pasheni',
          status: 'approved',
          course: {
            ...catalog.courses[0],
            contentVersion: undefined,
            title: 'Stale seed title',
          },
        },
      ],
      communityPosts: [
        {
          id: 'seed-nyanya-market',
          author: 'Legacy seed',
          location: 'Arusha',
          time: 'Leo',
          content: 'Legacy market claim',
          likes: 10,
          comments: 0,
          tags: ['Masoko'],
          replies: [],
        },
      ],
    }),
  );

  try {
    const migrated = new JsonStore({ catalog, filePath });
    const pasheni = migrated
      .approvedContentCourses()
      .find((course) => course.id === 'pasheni');
    assert.equal(pasheni.contentVersion, 2);
    assert.equal(pasheni.title, 'Kilimo cha Pasheni');
    assert.equal(
      migrated.communityPosts().some((post) => post.id === 'seed-nyanya-market'),
      false,
    );

    migrated.upsertContentCourse({
      course: { ...pasheni, title: 'Kichwa Kilichohaririwa' },
      status: 'approved',
    });

    const restarted = new JsonStore({ catalog, filePath });
    assert.equal(
      restarted
        .approvedContentCourses()
        .find((course) => course.id === 'pasheni').title,
      'Kichwa Kilichohaririwa',
    );
  } finally {
    fs.rmSync(filePath, { force: true });
  }
});
