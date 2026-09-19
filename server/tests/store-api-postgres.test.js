import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';

import express from 'express';

import { registerApiRoutes } from '../api.js';

const databaseUrl = process.env.SUPABASE_DATABASE_URL ?? process.env.DATABASE_URL;
const ADMIN_EMAIL = 'admin@ajefarms.test';

function createTempCommunityFile() {
  const filePath = path.join(
    os.tmpdir(),
    `aje-farms-community-${Date.now()}-${Math.random().toString(36).slice(2)}.json`,
  );
  fs.writeFileSync(filePath, '{}');
  return filePath;
}

async function withPostgresServer(run) {
  const communityFile = createTempCommunityFile();
  process.env.AJE_STORE = process.env.AJE_STORE ?? 'postgres';
  process.env.DATABASE_URL = databaseUrl;
  if (process.env.SUPABASE_DATABASE_URL) {
    process.env.SUPABASE_DATABASE_URL = databaseUrl;
  }
  process.env.AJE_COMMUNITY_DATA_FILE = communityFile;
  process.env.AJE_ENABLE_DEBUG_OTP = 'true';
  process.env.AJE_ENABLE_LEGACY_DEV_PAYMENTS = 'true';
  process.env.AJE_DEV_PAYMENT_WEBHOOK_SECRET = 'test-webhook-secret';
  process.env.AJE_ADMIN_EMAILS = ADMIN_EMAIL;
  process.env.NODE_ENV = 'development';

  const app = express();
  app.use(express.json());
  const store = await registerApiRoutes(app);

  const server = await new Promise((resolve) => {
    const listener = app.listen(0, '127.0.0.1', () => resolve(listener));
  });
  const { port } = server.address();
  const baseUrl = `http://127.0.0.1:${port}`;

  try {
    await store.resetForTests();
    await run(baseUrl);
  } finally {
    await new Promise((resolve, reject) => {
      server.close((error) => (error ? reject(error) : resolve()));
    });
    await store.close();
    fs.rmSync(communityFile, { force: true });
  }
}

async function postJson(baseUrl, path, body, headers = {}) {
  const response = await fetch(`${baseUrl}${path}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...headers,
    },
    body: JSON.stringify(body),
  });
  const payload = await response.json();
  return { response, payload };
}

async function getJson(baseUrl, path, headers = {}) {
  const response = await fetch(`${baseUrl}${path}`, { headers });
  const payload = await response.json();
  return { response, payload };
}

// Stands in for the Flutter client signing in with Supabase Auth: hits the
// NODE_ENV=development-only dev-session issuer (see api.js) rather than a
// real Supabase Auth token.
async function signIn(baseUrl, email) {
  const { response, payload } = await postJson(baseUrl, '/api/auth/dev-session', {
    email,
  });
  assert.equal(response.status, 200);
  return { user: payload.user, sessionToken: payload.sessionToken };
}

test(
  'postgres auth and subscription flow survives store reset',
  { skip: databaseUrl ? false : 'DATABASE_URL is not set' },
  async () => {
    await withPostgresServer(async (baseUrl) => {
      const { sessionToken: token } = await signIn(baseUrl, 'learner@aje.test');

      const checkout = await postJson(
        baseUrl,
        '/api/payments/checkout',
        {
          planTitle: 'Wiki 1',
          price: 'TSh 2,000',
          method: 'M-Pesa',
        },
        { Authorization: `Bearer ${token}` },
      );
      assert.equal(checkout.response.status, 200);

      const paid = await postJson(
        baseUrl,
        '/api/payments/webhook/development',
        {
          transactionId: checkout.payload.id,
          status: 'paid',
        },
        { 'x-aje-webhook-secret': 'test-webhook-secret' },
      );
      assert.equal(paid.response.status, 200);

      const profile = await getJson(baseUrl, '/api/users/me', {
        Authorization: `Bearer ${token}`,
      });
      assert.equal(profile.response.status, 200);
      assert.equal(profile.payload.user.subscriptionPlan, 'Wiki 1');
    });
  },
);

test(
  'postgres admin email allowlist maps session user role to admin',
  { skip: databaseUrl ? false : 'DATABASE_URL is not set' },
  async () => {
    await withPostgresServer(async (baseUrl) => {
      const { user } = await signIn(baseUrl, ADMIN_EMAIL);
      assert.equal(user.role, 'admin');
    });
  },
);
