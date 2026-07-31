import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
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
  const previous = {
    adminEmails: process.env.AJE_ADMIN_EMAILS,
    dataFile: process.env.AJE_DATA_FILE,
    debugOtp: process.env.AJE_ENABLE_DEBUG_OTP,
    nodeEnv: process.env.NODE_ENV,
  };
  const dataFile = path.join(
    os.tmpdir(),
    `aje-mwalimu-${Date.now()}-${Math.random().toString(36).slice(2)}.json`,
  );
  process.env.AJE_ADMIN_EMAILS = 'mwalimu-admin@ajefarms.test';
  process.env.AJE_DATA_FILE = dataFile;
  process.env.AJE_ENABLE_DEBUG_OTP = 'true';
  process.env.NODE_ENV = 'test';
  const app = express();
  app.use(express.json());
  await registerApiRoutes(app);

  const server = await new Promise((resolve) => {
    const listener = app.listen(0, '127.0.0.1', () => resolve(listener));
  });
  const { port } = server.address();

  try {
    const signIn = await fetch(`http://127.0.0.1:${port}/api/auth/dev-session`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'mwalimu-admin@ajefarms.test' }),
    });
    const session = await signIn.json();
    assert.equal(signIn.status, 200);

    const response = await fetch(`http://127.0.0.1:${port}/api/mwalimu-chat`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${session.sessionToken}`,
      },
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
    fs.rmSync(dataFile, { force: true });
    for (const [key, value] of Object.entries(previous)) {
      const envKey = {
        adminEmails: 'AJE_ADMIN_EMAILS',
        dataFile: 'AJE_DATA_FILE',
        debugOtp: 'AJE_ENABLE_DEBUG_OTP',
        nodeEnv: 'NODE_ENV',
      }[key];
      if (value === undefined) delete process.env[envKey];
      else process.env[envKey] = value;
    }
  }
});
