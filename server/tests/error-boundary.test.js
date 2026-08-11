import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';

import { installApiErrorHandler } from '../api.js';

test('async route failures are sanitized and do not stop the server', async () => {
  const app = express();
  app.get('/reject', async () => {
    throw new Error('database-password-must-not-leak');
  });
  app.get('/health', (_req, res) => res.json({ status: 'ok' }));
  installApiErrorHandler(app);

  const server = await new Promise((resolve) => {
    const listener = app.listen(0, '127.0.0.1', () => resolve(listener));
  });
  const { port } = server.address();

  try {
    const failed = await fetch(`http://127.0.0.1:${port}/reject`);
    const failureBody = await failed.json();
    assert.equal(failed.status, 500);
    assert.equal(
      failureBody.error,
      'Huduma imepata tatizo. Tafadhali jaribu tena.',
    );
    assert.ok(!JSON.stringify(failureBody).includes('database-password'));

    const healthy = await fetch(`http://127.0.0.1:${port}/health`);
    assert.equal(healthy.status, 200);
    assert.deepEqual(await healthy.json(), { status: 'ok' });
  } finally {
    await new Promise((resolve, reject) => {
      server.close((error) => (error ? reject(error) : resolve()));
    });
  }
});
