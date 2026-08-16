import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';

import { lockedCatalogSnapshot } from '../api.js';
import {
  normalizeSearchText,
  parseSearchRequest,
  searchCatalogSnapshot,
} from '../search.js';
import { CommunityJsonStore } from '../store/community-json-store.js';

const snapshot = {
  courses: [
    {
      id: 'rice',
      title: 'Kilimo cha Mpunga',
      description: 'Mbegu na mavuno',
      outcomes: [],
      lessons: [],
    },
  ],
  documents: [
    {
      id: 'rice-guide',
      courseId: 'rice',
      title: 'Mwongozo wa Mpunga',
      description: 'Hatua za shambani',
      type: 'PDF',
      courseTitle: 'Kilimo cha Mpunga',
    },
    {
      id: 'tomato-guide',
      courseId: 'tomato',
      title: 'Mwongozo wa Nyanya',
      description: 'Udhibiti wa magonjwa',
      type: 'PDF',
      courseTitle: 'Kilimo cha Nyanya',
    },
  ],
  problemCategories: [],
  communityPosts: [
    {
      id: 'post-1',
      content: 'Wakulima wa mpunga tushirikiane',
      tags: ['Mpunga'],
      location: 'Morogoro',
      time: 'Leo',
    },
  ],
};

test('learning scope includes course documents but excludes community posts', () => {
  const request = {
    query: 'mpunga',
    scope: 'learning',
    limit: 20,
    savedDocumentIds: [],
  };
  const response = searchCatalogSnapshot(snapshot, request);

  assert.deepEqual(
    new Set(response.results.map((result) => result.kind)),
    new Set(['course', 'document']),
  );
  assert.equal('body' in response.results[0], false);
  assert.equal('score' in response.results[0], false);
});

test('saved-document preference only boosts documents that match the query', () => {
  const request = {
    query: 'mpunga',
    scope: 'documents',
    limit: 20,
    savedDocumentIds: ['tomato-guide'],
  };
  const response = searchCatalogSnapshot(snapshot, request);

  assert.deepEqual(response.results.map((result) => result.id), ['rice-guide']);
});

test('community result titles do not split non-BMP characters', () => {
  const content = `${'a'.repeat(68)}😀${'b'.repeat(10)}`;
  const response = searchCatalogSnapshot(
    {
      courses: [],
      documents: [],
      problemCategories: [],
      communityPosts: [{ id: 'emoji-post', content, tags: [] }],
    },
    {
      query: 'aaaaaaaa',
      scope: 'community',
      limit: 20,
      savedDocumentIds: [],
    },
  );

  assert.equal(response.results[0].title, `${'a'.repeat(68)}😀…`);
});

test('search returns at most three lessons from the same course', () => {
  const response = searchCatalogSnapshot(
    {
      courses: [
        {
          id: 'course-a',
          title: 'Kozi A',
          description: 'Mafunzo ya shamba',
          lessons: Array.from({ length: 5 }, (_, index) => ({
            id: `a-${index}`,
            title: `Nyanya afya somo ${index}`,
            description: 'Nyanya afya',
          })),
        },
        {
          id: 'course-b',
          title: 'Kozi B',
          description: 'Mafunzo mengine',
          lessons: [
            {
              id: 'b-0',
              title: 'Nyanya afya somo la ziada',
              description: 'Nyanya afya',
            },
          ],
        },
      ],
      documents: [],
      problemCategories: [],
      communityPosts: [],
    },
    {
      query: 'nyanya afya',
      scope: 'learning',
      limit: 10,
      savedDocumentIds: [],
    },
  );

  assert.equal(
    response.results.filter((result) => result.parentId === 'course-a').length,
    3,
  );
  assert.equal(
    response.results.some((result) => result.parentId === 'course-b'),
    true,
  );
});

test('request parser rejects unknown fields and normalizes the query', () => {
  assert.deepEqual(parseSearchRequest({ query: '  MPUNGA! ', scope: 'all' }), {
    query: 'mpunga',
    scope: 'all',
    limit: 20,
    savedDocumentIds: [],
  });
  assert.ok(parseSearchRequest({ query: 'mpunga', unexpected: true }).error);
  assert.equal(
    parseSearchRequest({
      query: 'mpunga',
      scope: 'documents',
      savedDocumentIds: Array.from({ length: 101 }, (_, index) => `doc-${index}`),
    }).savedDocumentIds.length,
    101,
  );
});

test('locked catalog removes protected lesson and document details', () => {
  const locked = lockedCatalogSnapshot({
    courses: [
      {
        id: 'rice',
        lessons: [
          {
            id: 'lesson-1',
            description: 'Paid lesson details',
            resourceUrl: 'https://example.com/lesson',
            resourcePath: 'private/lesson.pdf',
          },
        ],
      },
    ],
    documents: [
      {
        id: 'document-1',
        description: 'Paid document details',
        url: 'https://example.com/document',
      },
    ],
  });

  assert.equal(locked.courses[0].lessons[0].description, '');
  assert.equal(locked.courses[0].lessons[0].resourceUrl, null);
  assert.equal(locked.courses[0].lessons[0].resourcePath, null);
  assert.equal(locked.courses[0].lessons[0].isPremium, true);
  assert.equal(locked.documents[0].description, '');
  assert.equal(locked.documents[0].url, null);
  assert.equal(locked.documents[0].isPremium, true);
});

test('community discovery fails closed for unknown moderation states', () => {
  const filePath = path.join(
    os.tmpdir(),
    `aje-community-search-${Date.now()}-${Math.random().toString(36).slice(2)}.json`,
  );
  fs.writeFileSync(
    filePath,
    JSON.stringify({
      communityPosts: [
        {
          id: 'pending-post',
          content: 'Not approved',
          moderationStatus: 'pending-review',
          replies: [],
        },
      ],
    }),
  );
  try {
    const store = new CommunityJsonStore(
      { communityPosts: [] },
      filePath,
      { persist() {} },
    );
    assert.deepEqual(store.communityPosts(), []);
  } finally {
    fs.rmSync(filePath, { force: true });
  }
});

test('normalization matches the shared cross-runtime fixture', () => {
  const fixture = JSON.parse(
    fs.readFileSync(
      new URL('../../fixtures/search_normalization_v1.json', import.meta.url),
      'utf8',
    ),
  );
  for (const searchCase of fixture.cases) {
    assert.equal(
      normalizeSearchText(searchCase.input),
      searchCase.expected,
      searchCase.input,
    );
  }
  for (const boundary of fixture.boundaries) {
    const parsed = parseSearchRequest({ query: 'a'.repeat(boundary.codePoints) });
    assert.equal(!parsed.error, boundary.valid, `${boundary.codePoints} code points`);
  }
});
