import assert from 'node:assert/strict';
import test from 'node:test';

import { PostgresStore } from '../store/postgres-store.js';

// Regression: ISSUE-001 — common Swahili words matched unrelated grounding facts
// Found by /qa on 2026-07-16
// Report: .gstack/qa-reports/qa-report-ushuhuda-pilot-2026-07-16.md
test('grounding retrieval refuses an unrelated poultry medicine question', async () => {
  const previousStoreMode = process.env.AJE_STORE;
  process.env.AJE_STORE = 'supabase';
  const store = new PostgresStore({
    pool: {
      query: async () => ({
        rows: [
          {
            id: 'fact-1',
            course_id: 'CRS-USH-01',
            course_title: 'Misingi ya Ujasiriamali wa Kilimo',
            lesson_id: 'lesson-1',
            title: 'Kilimo Mseto na Mapato ya Nyakati Tofauti',
            excerpt:
              'Shughuli tofauti zinaweza kuleta mapato kwa nyakati tofauti.',
            source_title: 'Ushuhuda Wangu',
            page_start: 82,
            page_end: 84,
            time_start_seconds: null,
            time_end_seconds: null,
          },
        ],
      }),
    },
    catalog: {},
    schema: 'public',
  });

  try {
    assert.deepEqual(
      await store.groundingSources('Ni dawa gani nitumie kwa kuku wangu?'),
      [],
    );
  } finally {
    if (previousStoreMode == null) {
      delete process.env.AJE_STORE;
    } else {
      process.env.AJE_STORE = previousStoreMode;
    }
  }
});

test('grounding retrieval still returns a fact for distinctive matching terms', async () => {
  const previousStoreMode = process.env.AJE_STORE;
  process.env.AJE_STORE = 'supabase';
  const store = new PostgresStore({
    pool: {
      query: async () => ({
        rows: [
          {
            id: 'fact-1',
            course_id: 'CRS-USH-01',
            course_title: 'Misingi ya Ujasiriamali wa Kilimo',
            lesson_id: 'lesson-1',
            title: 'Nguzo Tatu: Mfumo, Watu na Bidhaa',
            excerpt:
              'Nguzo tatu ni Process, People na Product katika biashara.',
            source_title: 'Ushuhuda Wangu',
            page_start: 151,
            page_end: 155,
            time_start_seconds: null,
            time_end_seconds: null,
          },
        ],
      }),
    },
    catalog: {},
    schema: 'public',
  });

  try {
    const sources = await store.groundingSources(
      'Nguzo tatu za biashara ni zipi?',
    );
    assert.equal(sources.length, 1);
    assert.equal(sources[0].id, 'fact-1');
    assert.equal(sources[0].citation, 'Ushuhuda Wangu, kurasa 151-155');
  } finally {
    if (previousStoreMode == null) {
      delete process.env.AJE_STORE;
    } else {
      process.env.AJE_STORE = previousStoreMode;
    }
  }
});
