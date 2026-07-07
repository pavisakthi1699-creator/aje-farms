import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';

import { registerApiRoutes } from '../api.js';
import { findApprovedSources } from '../mwalimu.js';

test('findApprovedSources returns approved lesson source metadata', () => {
  const sources = findApprovedSources('Nifanye nini kuhusu pasheni na maji?');

  assert.ok(sources.length > 0);
  assert.equal(sources[0].courseId, 'pasheni');
  assert.equal(typeof sources[0].lessonId, 'string');
  assert.equal(typeof sources[0].excerpt, 'string');
});

test('mwalimu chat returns grounded answer and sources', async () => {
  const app = express();
  app.use(express.json());
  await registerApiRoutes(app);

  const server = await new Promise((resolve) => {
    const listener = app.listen(0, '127.0.0.1', () => resolve(listener));
  });
  const { port } = server.address();

  try {
    const response = await fetch(`http://127.0.0.1:${port}/api/mwalimu-chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message: 'Nisaidie kuhusu kuku na chanjo' }),
    });
    const payload = await response.json();

    assert.equal(response.status, 200);
    assert.equal(typeof payload.text, 'string');
    assert.ok(payload.sources.length > 0);
    assert.equal(payload.sources[0].courseId, 'kuku');
  } finally {
    await new Promise((resolve, reject) => {
      server.close((error) => (error ? reject(error) : resolve()));
    });
  }
});
