import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';

import express from 'express';

import { registerApiRoutes } from '../api.js';

const ADMIN_EMAIL = 'admin@ajefarms.test';

function createTempDataFile() {
  const filePath = path.join(
    os.tmpdir(),
    `aje-admin-payments-${Date.now()}-${Math.random().toString(36).slice(2)}.json`,
  );
  fs.writeFileSync(filePath, '{}');
  return filePath;
}

async function withTestServer(run) {
  const dataFile = createTempDataFile();
  process.env.AJE_STORE = 'json';
  process.env.AJE_DATA_FILE = dataFile;
  process.env.AJE_ENABLE_DEBUG_OTP = 'true';
  process.env.AJE_ADMIN_EMAILS = ADMIN_EMAIL;
  process.env.NODE_ENV = 'development';

  const app = express();
  app.use(express.json());
  await registerApiRoutes(app);

  const server = await new Promise((resolve) => {
    const listener = app.listen(0, '127.0.0.1', () => resolve(listener));
  });
  const { port } = server.address();
  const baseUrl = `http://127.0.0.1:${port}`;

  try {
    await run(baseUrl);
  } finally {
    await new Promise((resolve, reject) => {
      server.close((error) => (error ? reject(error) : resolve()));
    });
    fs.rmSync(dataFile, { force: true });
  }
}

async function postJson(baseUrl, path, body, headers = {}) {
  const response = await fetch(`${baseUrl}${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...headers },
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

async function authHeaders(sessionToken) {
  return { Authorization: `Bearer ${sessionToken}` };
}

async function signIn(baseUrl, email) {
  const { response, payload } = await postJson(baseUrl, '/api/auth/dev-session', {
    email,
  });
  assert.equal(response.status, 200);
  return { user: payload.user, sessionToken: payload.sessionToken };
}

test('a non-admin cannot see or record payments', async () => {
  await withTestServer(async (baseUrl) => {
    const { sessionToken } = await signIn(baseUrl, 'learner@aje.test');

    const list = await getJson(
      baseUrl,
      '/api/admin/payments',
      await authHeaders(sessionToken),
    );
    assert.equal(list.response.status, 403);

    const record = await postJson(
      baseUrl,
      '/api/admin/payments',
      { userId: 'anyone', planId: 'wiki-1', method: 'cash', amountTzs: 3000 },
      await authHeaders(sessionToken),
    );
    assert.equal(record.response.status, 403);
  });
});

test('admin plan catalog exposes server-owned prices, not free text', async () => {
  await withTestServer(async (baseUrl) => {
    const { sessionToken } = await signIn(baseUrl, ADMIN_EMAIL);

    const plans = await getJson(
      baseUrl,
      '/api/admin/plans',
      await authHeaders(sessionToken),
    );
    assert.equal(plans.response.status, 200);
    const monthly = plans.payload.plans.find((plan) => plan.id === 'mwezi-1');
    assert.equal(monthly.priceTzs, 10000);
    assert.equal(monthly.durationDays, 30);
  });
});

test('full flow: record a cash payment, approve it, learner gains access', async () => {
  await withTestServer(async (baseUrl) => {
    const { sessionToken: adminToken } = await signIn(baseUrl, ADMIN_EMAIL);
    const adminHeaders = await authHeaders(adminToken);
    const { user: learner } = await signIn(baseUrl, 'learner1@aje.test');

    const recorded = await postJson(
      baseUrl,
      '/api/admin/payments',
      {
        userId: learner.id,
        planId: 'wiki-1',
        method: 'cash',
        amountTzs: 3000,
        note: 'Paid at the office',
      },
      adminHeaders,
    );
    assert.equal(recorded.response.status, 200);
    assert.equal(recorded.payload.paymentRecord.status, 'pending');

    const pendingList = await getJson(
      baseUrl,
      '/api/admin/payments?status=pending',
      adminHeaders,
    );
    assert.equal(pendingList.response.status, 200);
    assert.equal(pendingList.payload.records.length, 1);
    assert.equal(pendingList.payload.records[0].userEmail, 'learner1@aje.test');

    const paymentRecordId = recorded.payload.paymentRecord.id;
    const approved = await postJson(
      baseUrl,
      `/api/admin/payments/${paymentRecordId}/approve`,
      { reason: 'Cash counted and confirmed' },
      adminHeaders,
    );
    assert.equal(approved.response.status, 200);
    assert.equal(approved.payload.paymentRecord.status, 'approved');
    assert.equal(approved.payload.entitlement.status, 'active');

    // Approving twice must not create a second entitlement.
    const approvedAgain = await postJson(
      baseUrl,
      `/api/admin/payments/${paymentRecordId}/approve`,
      {},
      adminHeaders,
    );
    assert.equal(approvedAgain.payload.entitlement.id, approved.payload.entitlement.id);

    const audit = await getJson(
      baseUrl,
      `/api/admin/payments/${paymentRecordId}/audit`,
      adminHeaders,
    );
    assert.equal(audit.response.status, 200);
    assert.equal(audit.payload.events.length, 1);
    assert.equal(audit.payload.events[0].action, 'payment_approved');
    assert.equal(audit.payload.events[0].reason, 'Cash counted and confirmed');

    const learnerProfile = await getJson(
      baseUrl,
      '/api/users/me',
      await authHeaders((await signIn(baseUrl, 'learner1@aje.test')).sessionToken),
    );
    assert.equal(learnerProfile.payload.user.accountStatus, 'active');
    assert.equal(learnerProfile.payload.user.subscriptionPlan, 'Wiki 1');
  });
});

test('reversing an approved payment revokes access', async () => {
  await withTestServer(async (baseUrl) => {
    const { sessionToken: adminToken } = await signIn(baseUrl, ADMIN_EMAIL);
    const adminHeaders = await authHeaders(adminToken);
    const { user: learner } = await signIn(baseUrl, 'learner2@aje.test');

    const recorded = await postJson(
      baseUrl,
      '/api/admin/payments',
      { userId: learner.id, planId: 'mwezi-1', method: 'bank_transfer', amountTzs: 10000 },
      adminHeaders,
    );
    const paymentRecordId = recorded.payload.paymentRecord.id;
    await postJson(
      baseUrl,
      `/api/admin/payments/${paymentRecordId}/approve`,
      {},
      adminHeaders,
    );

    const reversed = await postJson(
      baseUrl,
      `/api/admin/payments/${paymentRecordId}/reverse`,
      { reason: 'Duplicate entry' },
      adminHeaders,
    );
    assert.equal(reversed.response.status, 200);
    assert.equal(reversed.payload.paymentRecord.status, 'reversed');
    assert.equal(reversed.payload.entitlement.status, 'revoked');

    const audit = await getJson(
      baseUrl,
      `/api/admin/payments/${paymentRecordId}/audit`,
      adminHeaders,
    );
    assert.equal(audit.payload.events.length, 2);
    assert.equal(audit.payload.events[0].action, 'payment_reversed');
  });
});

test('a duplicate reference is rejected with 409', async () => {
  await withTestServer(async (baseUrl) => {
    const { sessionToken: adminToken } = await signIn(baseUrl, ADMIN_EMAIL);
    const adminHeaders = await authHeaders(adminToken);
    const { user: learner } = await signIn(baseUrl, 'learner3@aje.test');

    await postJson(
      baseUrl,
      '/api/admin/payments',
      {
        userId: learner.id,
        planId: 'wiki-1',
        method: 'bank_transfer',
        amountTzs: 3000,
        reference: 'DUP-1',
      },
      adminHeaders,
    );
    const duplicate = await postJson(
      baseUrl,
      '/api/admin/payments',
      {
        userId: learner.id,
        planId: 'wiki-1',
        method: 'bank_transfer',
        amountTzs: 3000,
        reference: 'DUP-1',
      },
      adminHeaders,
    );
    assert.equal(duplicate.response.status, 409);
  });
});

test('recording a payment against a disabled or unknown plan is rejected', async () => {
  await withTestServer(async (baseUrl) => {
    const { sessionToken: adminToken } = await signIn(baseUrl, ADMIN_EMAIL);
    const adminHeaders = await authHeaders(adminToken);
    const { user: learner } = await signIn(baseUrl, 'learner4@aje.test');

    const invalid = await postJson(
      baseUrl,
      '/api/admin/payments',
      { userId: learner.id, planId: 'not-a-plan', method: 'cash', amountTzs: 3000 },
      adminHeaders,
    );
    assert.equal(invalid.response.status, 400);
  });
});

test('a payment must exactly match the server-owned plan price in TZS', async () => {
  await withTestServer(async (baseUrl) => {
    const { sessionToken: adminToken } = await signIn(baseUrl, ADMIN_EMAIL);
    const adminHeaders = await authHeaders(adminToken);
    const { user: learner } = await signIn(baseUrl, 'learner-price@aje.test');

    for (const body of [
      {
        userId: learner.id,
        planId: 'wiki-1',
        method: 'cash',
        amountTzs: 0,
      },
      {
        userId: learner.id,
        planId: 'wiki-1',
        method: 'cash',
        amountTzs: 2999,
      },
      {
        userId: learner.id,
        planId: 'wiki-1',
        method: 'cash',
        amountTzs: 3000,
        currency: 'USD',
      },
    ]) {
      const result = await postJson(
        baseUrl,
        '/api/admin/payments',
        body,
        adminHeaders,
      );
      assert.equal(result.response.status, 422);
    }

    const pending = await getJson(
      baseUrl,
      '/api/admin/payments?status=pending',
      adminHeaders,
    );
    assert.equal(pending.payload.records.length, 0);
  });
});
