import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';

import express from 'express';

import { registerApiRoutes } from '../api.js';

function createTempDataFile() {
  const filePath = path.join(
    os.tmpdir(),
    `aje-farms-search-${Date.now()}-${Math.random().toString(36).slice(2)}.json`,
  );
  fs.writeFileSync(filePath, '{}');
  return filePath;
}

async function withTestServer(run) {
  const dataFile = createTempDataFile();
  process.env.AJE_STORE = 'json';
  process.env.AJE_DATA_FILE = dataFile;
  process.env.AJE_ENABLE_DEBUG_OTP = 'true';
  process.env.NODE_ENV = 'development';

  const app = express();
  app.use(express.json());
  await registerApiRoutes(app);
  const server = await new Promise((resolve) => {
    const listener = app.listen(0, '127.0.0.1', () => resolve(listener));
  });
  const baseUrl = `http://127.0.0.1:${server.address().port}`;

  try {
    await run(baseUrl);
  } finally {
    await new Promise((resolve, reject) => {
      server.close((error) => (error ? reject(error) : resolve()));
    });
    fs.rmSync(dataFile, { force: true });
  }
}

async function postJson(baseUrl, route, body, headers = {}) {
  const response = await fetch(`${baseUrl}${route}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...headers },
    body: JSON.stringify(body),
  });
  return { response, payload: await response.json() };
}

async function signIn(baseUrl) {
  const { response, payload } = await postJson(
    baseUrl,
    '/api/auth/dev-session',
    { email: 'search-farmer@aje.test' },
  );
  assert.equal(response.status, 200);
  return payload.sessionToken;
}

test('authenticated learner searches the unified catalog', async () => {
  await withTestServer(async (baseUrl) => {
    const unauthenticated = await postJson(baseUrl, '/api/search', {
      query: 'nyanya',
      scope: 'all',
    });
    assert.equal(unauthenticated.response.status, 401);

    const sessionToken = await signIn(baseUrl);
    const search = await postJson(
      baseUrl,
      '/api/search',
      { query: 'nyanya', scope: 'all' },
      { Authorization: `Bearer ${sessionToken}` },
    );

    assert.equal(search.response.status, 200);
    assert.equal(search.payload.query, 'nyanya');
    assert.equal(search.payload.scope, 'all');
    assert.equal(search.payload.truncated, false);
    assert.ok(
      search.payload.results.some(
        (result) =>
          result.kind === 'course' &&
          result.id === 'nyanya' &&
          result.title === 'Kilimo cha Nyanya',
      ),
    );
  });
});

test('search scopes results and never matches protected lesson descriptions', async () => {
  await withTestServer(async (baseUrl) => {
    const sessionToken = await signIn(baseUrl);
    const headers = { Authorization: `Bearer ${sessionToken}` };

    const community = await postJson(
      baseUrl,
      '/api/search',
      { query: 'jamii', scope: 'community' },
      headers,
    );
    assert.equal(community.response.status, 200);
    assert.ok(community.payload.results.length > 0);
    assert.ok(
      community.payload.results.every((result) => result.kind === 'community'),
    );

    const typo = await postJson(
      baseUrl,
      '/api/search',
      { query: 'nyaynya', scope: 'learning' },
      headers,
    );
    assert.equal(typo.response.status, 200);
    assert.equal(typo.payload.results[0].id, 'nyanya');

    const protectedText = await postJson(
      baseUrl,
      '/api/search',
      { query: 'wanunuzi', scope: 'learning' },
      headers,
    );
    assert.equal(protectedText.response.status, 200);
    assert.ok(
      protectedText.payload.results.every((result) => result.kind !== 'lesson'),
    );

    const invalid = await postJson(
      baseUrl,
      '/api/search',
      { query: 'x', scope: 'all' },
      headers,
    );
    assert.equal(invalid.response.status, 400);
  });
});

test('search throttles an authenticated burst and returns retry guidance', async () => {
  await withTestServer(async (baseUrl) => {
    const sessionToken = await signIn(baseUrl);
    const headers = { Authorization: `Bearer ${sessionToken}` };

    for (let index = 0; index < 30; index += 1) {
      const search = await postJson(
        baseUrl,
        '/api/search',
        { query: 'nyanya', scope: 'all' },
        headers,
      );
      assert.equal(search.response.status, 200);
    }
    const throttled = await postJson(
      baseUrl,
      '/api/search',
      { query: 'nyanya', scope: 'all' },
      headers,
    );

    assert.equal(throttled.response.status, 429);
    assert.ok(Number(throttled.response.headers.get('retry-after')) >= 1);
  });
});
