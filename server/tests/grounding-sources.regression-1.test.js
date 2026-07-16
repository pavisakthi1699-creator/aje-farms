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
            question_sw: 'Kilimo mseto kina faida gani?',
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
            question_sw: 'Nguzo tatu za biashara ni zipi?',
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

test('grounding retrieval excludes lower-relevance facts', async () => {
  const previousStoreMode = process.env.AJE_STORE;
  process.env.AJE_STORE = 'supabase';
  const store = new PostgresStore({
    pool: {
      query: async () => ({
        rows: [
          {
            id: 'fact-best',
            course_id: 'CRS-USH-01',
            course_title: 'Misingi ya Ujasiriamali wa Kilimo',
            lesson_id: 'lesson-3',
            title: 'Nguzo Tatu: Mfumo, Watu na Bidhaa',
            excerpt:
              'Nguzo tatu ni Process, People na Product katika biashara.',
            question_sw: 'Nguzo tatu za biashara ni zipi?',
            source_title: 'Ushuhuda Wangu',
            page_start: 151,
            page_end: 155,
            time_start_seconds: null,
            time_end_seconds: null,
          },
          {
            id: 'fact-weaker',
            course_id: 'CRS-USH-01',
            course_title: 'Misingi ya Ujasiriamali wa Kilimo',
            lesson_id: 'lesson-1',
            title: 'Anza Kidogo na Ujifunze Biashara',
            excerpt: 'Anza biashara kwa kiwango kidogo.',
            question_sw: 'Mtu aanzaje biashara?',
            source_title: 'Ushuhuda Wangu',
            page_start: 80,
            page_end: 81,
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
    assert.deepEqual(
      sources.map((source) => source.id),
      ['fact-best'],
    );
  } finally {
    if (previousStoreMode == null) {
      delete process.env.AJE_STORE;
    } else {
      process.env.AJE_STORE = previousStoreMode;
    }
  }
});

test('grounding retrieval does not use a treatment book title as evidence', async () => {
  const previousStoreMode = process.env.AJE_STORE;
  process.env.AJE_STORE = 'supabase';
  const store = new PostgresStore({
    pool: {
      query: async () => ({
        rows: [
          {
            id: 'biosecurity-fact',
            course_id: 'CRS-KUK-02',
            course_title: 'Usalama wa Banda na Ufuatiliaji wa Afya ya Kuku',
            lesson_id: 'lesson-1',
            title: 'Tenga Kuku Wapya na Dhibiti Viatu',
            excerpt:
              'Tenga kuku wapya kwa wiki mbili na tumia viatu maalum vya banda.',
            question_sw: 'Nizuieje magonjwa kuingia bandani?',
            source_title: 'MAGONJWA YA KUKU TIBA ZAKE ZA ASILI',
            page_start: 12,
            page_end: 12,
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
      await store.groundingSources('Ni tiba gani nitumie?'),
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

test('grounding retrieval refuses an unsupported poultry vaccination schedule', async () => {
  const previousStoreMode = process.env.AJE_STORE;
  process.env.AJE_STORE = 'supabase';
  let queryCount = 0;
  const store = new PostgresStore({
    pool: {
      query: async () => {
        queryCount += 1;
        return { rows: [] };
      },
    },
    catalog: {},
    schema: 'public',
  });

  try {
    assert.deepEqual(
      await store.groundingSources('Nipe ratiba ya chanjo ya kuku'),
      [],
    );
    assert.equal(queryCount, 0);
  } finally {
    if (previousStoreMode == null) {
      delete process.env.AJE_STORE;
    } else {
      process.env.AJE_STORE = previousStoreMode;
    }
  }
});

test('grounding retrieval can answer why vaccination records matter', async () => {
  const previousStoreMode = process.env.AJE_STORE;
  process.env.AJE_STORE = 'supabase';
  const store = new PostgresStore({
    pool: {
      query: async () => ({
        rows: [
          {
            id: 'monitoring-fact',
            course_id: 'CRS-KUK-02',
            course_title: 'Usalama wa Banda na Ufuatiliaji wa Afya ya Kuku',
            lesson_id: 'lesson-3',
            title: 'Fuatilia Afya na Weka Kumbukumbu',
            excerpt:
              'Kumbukumbu za afya na chanjo humpa mtaalamu historia ya kundi.',
            question_sw:
              'Kwa nini nifuatilie kuku na kuweka kumbukumbu za chanjo?',
            source_title: 'MAGONJWA YA KUKU TIBA ZAKE ZA ASILI',
            page_start: 27,
            page_end: 27,
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
      'Kwa nini niweke kumbukumbu za chanjo?',
    );
    assert.equal(sources.length, 1);
    assert.equal(sources[0].id, 'monitoring-fact');
  } finally {
    if (previousStoreMode == null) {
      delete process.env.AJE_STORE;
    } else {
      process.env.AJE_STORE = previousStoreMode;
    }
  }
});
