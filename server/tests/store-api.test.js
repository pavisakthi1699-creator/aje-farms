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
    `aje-farms-test-${Date.now()}-${Math.random().toString(36).slice(2)}.json`,
  );
  fs.writeFileSync(filePath, '{}');
  return filePath;
}

async function withTestServer(run) {
  const dataFile = createTempDataFile();
  process.env.AJE_STORE = 'json';
  process.env.AJE_DATA_FILE = dataFile;
  process.env.AJE_ENABLE_DEBUG_OTP = 'true';
  process.env.AJE_DEV_PAYMENT_WEBHOOK_SECRET = 'test-webhook-secret';
  process.env.AJE_ADMIN_PHONE_NUMBERS = '+255799000111';
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
    headers: {
      'Content-Type': 'application/json',
      ...headers,
    },
    body: JSON.stringify(body),
  });
  const payload = await response.json();
  return { response, payload };
}

async function putJson(baseUrl, path, body, headers = {}) {
  const response = await fetch(`${baseUrl}${path}`, {
    method: 'PUT',
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

async function authHeaders(sessionToken) {
  return { Authorization: `Bearer ${sessionToken}` };
}

test('auth flow creates and restores a user session', async () => {
  await withTestServer(async (baseUrl) => {
    const phoneNumber = '+255712345678';
    const otpRequest = await postJson(baseUrl, '/api/auth/request-otp', {
      phoneNumber,
    });

    assert.equal(otpRequest.response.status, 200);
    assert.ok(typeof otpRequest.payload.challengeId === 'string');
    assert.ok(typeof otpRequest.payload.debugOtp === 'string');

    const verify = await postJson(baseUrl, '/api/auth/verify-otp', {
      phoneNumber,
      otp: otpRequest.payload.debugOtp,
      challengeId: otpRequest.payload.challengeId,
    });

    assert.equal(verify.response.status, 200);
    assert.equal(verify.payload.user.phoneNumber, phoneNumber);
    assert.equal(verify.payload.user.subscriptionPlan, null);
    assert.ok(typeof verify.payload.sessionToken === 'string');

    const profile = await getJson(
      baseUrl,
      `/api/users/by-phone/${encodeURIComponent(phoneNumber)}`,
      await authHeaders(verify.payload.sessionToken),
    );

    assert.equal(profile.response.status, 200);
    assert.equal(profile.payload.user.id, verify.payload.user.id);

    const deniedProfile = await getJson(
      baseUrl,
      `/api/users/by-phone/${encodeURIComponent(phoneNumber)}`,
    );
    assert.equal(deniedProfile.response.status, 401);
  });
});

test('health endpoint reports development readiness', async () => {
  await withTestServer(async (baseUrl) => {
    const health = await getJson(baseUrl, '/api/health');

    assert.equal(health.response.status, 200);
    assert.equal(health.payload.status, 'ok');
    assert.equal(health.payload.checks.store.mode, 'json');
    assert.equal(health.payload.checks.payments.provider, 'development');
  });
});

test('subscription cancel clears backend subscription state', async () => {
  await withTestServer(async (baseUrl) => {
    const phoneNumber = '+255798765432';
    const otpRequest = await postJson(baseUrl, '/api/auth/request-otp', {
      phoneNumber,
    });
    const verify = await postJson(baseUrl, '/api/auth/verify-otp', {
      phoneNumber,
      otp: otpRequest.payload.debugOtp,
      challengeId: otpRequest.payload.challengeId,
    });
    assert.equal(verify.response.status, 200);
    const token = verify.payload.sessionToken;
    assert.ok(typeof token === 'string');

    const checkout = await postJson(
      baseUrl,
      '/api/payments/checkout',
      {
        planTitle: 'Wiki 1',
        price: 'TSh 2,000',
        method: 'M-Pesa',
        phoneNumber,
      },
      await authHeaders(token),
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
    assert.equal(paid.payload.status, 'paid');
    assert.equal(paid.payload.subscriptionPlan, 'Wiki 1');

    const activeProfile = await getJson(
      baseUrl,
      `/api/users/by-phone/${encodeURIComponent(phoneNumber)}`,
      await authHeaders(token),
    );
    assert.equal(activeProfile.payload.user.subscriptionPlan, 'Wiki 1');

    const cancel = await postJson(
      baseUrl,
      `/api/users/by-phone/${encodeURIComponent(phoneNumber)}/subscription/cancel`,
      {},
      await authHeaders(token),
    );
    assert.equal(cancel.response.status, 200);
    assert.equal(cancel.payload.user.subscriptionPlan, null);

    const clearedProfile = await getJson(
      baseUrl,
      `/api/users/by-phone/${encodeURIComponent(phoneNumber)}`,
      await authHeaders(token),
    );
    assert.equal(clearedProfile.payload.user.subscriptionPlan, null);
  });
});

test('learning progress is authenticated and survives store restart', async () => {
  await withTestServer(async (baseUrl) => {
    const phoneNumber = '+255711222333';
    const otpRequest = await postJson(baseUrl, '/api/auth/request-otp', {
      phoneNumber,
    });
    const verify = await postJson(baseUrl, '/api/auth/verify-otp', {
      phoneNumber,
      otp: otpRequest.payload.debugOtp,
      challengeId: otpRequest.payload.challengeId,
    });
    const token = verify.payload.sessionToken;

    const catalog = await getJson(baseUrl, '/api/catalog');
    assert.equal(catalog.response.status, 200);
    assert.equal(catalog.payload.courses[0].progress, 0);
    assert.equal(catalog.payload.courses[0].lessons[0].id, 'maandalizi-ya-shamba');
    assert.equal(catalog.payload.courses[0].lessons[0].isCompleted, false);

    const marked = await postJson(
      baseUrl,
      `/api/users/by-phone/${encodeURIComponent(phoneNumber)}/progress/lessons`,
      {
        courseId: 'pasheni',
        lessonId: 'maandalizi-ya-shamba',
      },
      await authHeaders(token),
    );
    assert.equal(marked.response.status, 200);
    assert.equal(marked.payload.courseId, 'pasheni');

    const progress = await getJson(
      baseUrl,
      `/api/users/by-phone/${encodeURIComponent(phoneNumber)}/progress`,
      await authHeaders(token),
    );
    assert.equal(progress.response.status, 200);
    assert.deepEqual(progress.payload.completedLessons, [
      'pasheni:maandalizi-ya-shamba',
    ]);

    const saved = JSON.parse(fs.readFileSync(process.env.AJE_DATA_FILE, 'utf8'));
    assert.equal(saved.learningProgress.length, 1);
  });
});

test('community writes preserve users and payment data on disk', async () => {
  await withTestServer(async (baseUrl) => {
    const phoneNumber = '+255700111222';
    const otpRequest = await postJson(baseUrl, '/api/auth/request-otp', {
      phoneNumber,
    });
    const verify = await postJson(baseUrl, '/api/auth/verify-otp', {
      phoneNumber,
      otp: otpRequest.payload.debugOtp,
      challengeId: otpRequest.payload.challengeId,
    });
    const token = verify.payload.sessionToken;

    const checkout = await postJson(
      baseUrl,
      '/api/payments/checkout',
      {
        planTitle: 'Mwezi 1',
        price: 'TSh 5,000',
        method: 'M-Pesa',
        phoneNumber,
      },
      await authHeaders(token),
    );
    assert.equal(checkout.response.status, 200);

    const post = await postJson(
      baseUrl,
      '/api/community/posts',
      {
        author: 'Mkulima Test',
        content: 'Nimepanda mahindi na ninahitaji ushauri wa kudhibiti wadudu.',
        location: 'Morogoro',
        tags: ['Mahindi'],
      },
      await authHeaders(token),
    );
    assert.equal(post.response.status, 200);

    const saved = JSON.parse(fs.readFileSync(process.env.AJE_DATA_FILE, 'utf8'));
    assert.ok(Array.isArray(saved.users) && saved.users.length > 0);
    assert.ok(
      Array.isArray(saved.paymentTransactions) &&
        saved.paymentTransactions.length > 0,
    );
    assert.ok(
      Array.isArray(saved.communityPosts) && saved.communityPosts.length > 0,
    );
  });
});

test('admin moderation can review reports and hide a community post', async () => {
  await withTestServer(async (baseUrl) => {
    const farmerPhone = '+255700444555';
    const farmerOtp = await postJson(baseUrl, '/api/auth/request-otp', {
      phoneNumber: farmerPhone,
    });
    const farmerVerify = await postJson(baseUrl, '/api/auth/verify-otp', {
      phoneNumber: farmerPhone,
      otp: farmerOtp.payload.debugOtp,
      challengeId: farmerOtp.payload.challengeId,
    });
    const farmerToken = farmerVerify.payload.sessionToken;

    const post = await postJson(
      baseUrl,
      '/api/community/posts',
      {
        author: 'Mkulima Test',
        content: 'Nimeona tangazo lisilofaa kwenye majadiliano haya ya wakulima.',
        location: 'Iringa',
        tags: ['Tahadhari'],
      },
      await authHeaders(farmerToken),
    );
    assert.equal(post.response.status, 200);

    const report = await postJson(
      baseUrl,
      `/api/community/posts/${post.payload.id}/report`,
      {},
      await authHeaders(farmerToken),
    );
    assert.equal(report.response.status, 200);

    const adminPhone = '+255799000111';
    const adminOtp = await postJson(baseUrl, '/api/auth/request-otp', {
      phoneNumber: adminPhone,
    });
    const adminVerify = await postJson(baseUrl, '/api/auth/verify-otp', {
      phoneNumber: adminPhone,
      otp: adminOtp.payload.debugOtp,
      challengeId: adminOtp.payload.challengeId,
    });
    const adminToken = adminVerify.payload.sessionToken;

    const reports = await getJson(
      baseUrl,
      '/api/admin/moderation/reports',
      await authHeaders(adminToken),
    );
    assert.equal(reports.response.status, 200);
    assert.equal(reports.payload.reports.length, 1);
    assert.equal(reports.payload.reports[0].post.id, post.payload.id);

    const hidden = await postJson(
      baseUrl,
      `/api/admin/moderation/posts/${post.payload.id}/resolve`,
      { action: 'hide' },
      await authHeaders(adminToken),
    );
    assert.equal(hidden.response.status, 200);
    assert.equal(hidden.payload.post.moderationStatus, 'hidden');

    const community = await getJson(baseUrl, '/api/community/posts');
    assert.equal(
      community.payload.posts.some((item) => item.id === post.payload.id),
      false,
    );
  });
});

test('admin content courses can be drafted and published into catalog', async () => {
  await withTestServer(async (baseUrl) => {
    const adminPhone = '+255799000111';
    const adminOtp = await postJson(baseUrl, '/api/auth/request-otp', {
      phoneNumber: adminPhone,
    });
    const adminVerify = await postJson(baseUrl, '/api/auth/verify-otp', {
      phoneNumber: adminPhone,
      otp: adminOtp.payload.debugOtp,
      challengeId: adminOtp.payload.challengeId,
    });
    const adminHeaders = await authHeaders(adminVerify.payload.sessionToken);

    const catalog = await getJson(baseUrl, '/api/catalog');
    const pasheni = catalog.payload.courses.find(
      (course) => course.id === 'pasheni',
    );
    assert.ok(pasheni);

    const draft = await putJson(
      baseUrl,
      '/api/admin/content/courses/pasheni',
      {
        status: 'draft',
        course: {
          ...pasheni,
          title: 'Kilimo cha Pasheni Rasimu',
        },
      },
      adminHeaders,
    );
    assert.equal(draft.response.status, 200);
    assert.equal(draft.payload.course.status, 'draft');

    const catalogAfterDraft = await getJson(baseUrl, '/api/catalog');
    assert.equal(
      catalogAfterDraft.payload.courses.some(
        (course) => course.title === 'Kilimo cha Pasheni Rasimu',
      ),
      false,
    );

    const published = await putJson(
      baseUrl,
      '/api/admin/content/courses/pasheni',
      {
        status: 'approved',
        course: {
          ...pasheni,
          title: 'Kilimo cha Pasheni Kilichochapishwa',
        },
      },
      adminHeaders,
    );
    assert.equal(published.response.status, 200);

    const catalogAfterPublish = await getJson(baseUrl, '/api/catalog');
    assert.equal(
      catalogAfterPublish.payload.courses.find((course) => course.id === 'pasheni')
        .title,
      'Kilimo cha Pasheni Kilichochapishwa',
    );
  });
});

test('admin content documents can be drafted and published into catalog', async () => {
  await withTestServer(async (baseUrl) => {
    const adminPhone = '+255799000111';
    const adminOtp = await postJson(baseUrl, '/api/auth/request-otp', {
      phoneNumber: adminPhone,
    });
    const adminVerify = await postJson(baseUrl, '/api/auth/verify-otp', {
      phoneNumber: adminPhone,
      otp: adminOtp.payload.debugOtp,
      challengeId: adminOtp.payload.challengeId,
    });
    const adminHeaders = await authHeaders(adminVerify.payload.sessionToken);

    const catalog = await getJson(baseUrl, '/api/catalog');
    assert.equal(catalog.response.status, 200);
    assert.ok(Array.isArray(catalog.payload.documents));
    const document = catalog.payload.documents.find(
      (item) => item.id === 'mwongozo-mfupi-wa-pasheni',
    );
    assert.ok(document);

    const draft = await putJson(
      baseUrl,
      `/api/admin/content/documents/${encodeURIComponent(document.id)}`,
      {
        status: 'draft',
        document: {
          ...document,
          title: 'Mwongozo wa Pasheni Rasimu',
        },
      },
      adminHeaders,
    );
    assert.equal(draft.response.status, 200);
    assert.equal(draft.payload.document.status, 'draft');

    const catalogAfterDraft = await getJson(baseUrl, '/api/catalog');
    assert.equal(
      catalogAfterDraft.payload.documents.some(
        (item) => item.title === 'Mwongozo wa Pasheni Rasimu',
      ),
      false,
    );

    const published = await putJson(
      baseUrl,
      `/api/admin/content/documents/${encodeURIComponent(document.id)}`,
      {
        status: 'approved',
        document: {
          ...document,
          title: 'Mwongozo wa Pasheni Uliochapishwa',
        },
      },
      adminHeaders,
    );
    assert.equal(published.response.status, 200);

    const catalogAfterPublish = await getJson(baseUrl, '/api/catalog');
    assert.equal(
      catalogAfterPublish.payload.documents.find(
        (item) => item.id === document.id,
      ).title,
      'Mwongozo wa Pasheni Uliochapishwa',
    );
  });
});

test('notification settings, devices, inbox, and read state are backend backed', async () => {
  await withTestServer(async (baseUrl) => {
    const ownerPhone = '+255700555666';
    const ownerOtp = await postJson(baseUrl, '/api/auth/request-otp', {
      phoneNumber: ownerPhone,
    });
    const ownerVerify = await postJson(baseUrl, '/api/auth/verify-otp', {
      phoneNumber: ownerPhone,
      otp: ownerOtp.payload.debugOtp,
      challengeId: ownerOtp.payload.challengeId,
    });
    const ownerToken = ownerVerify.payload.sessionToken;

    const device = await postJson(
      baseUrl,
      `/api/users/by-phone/${encodeURIComponent(ownerPhone)}/notifications/devices`,
      { token: 'test-device-token', platform: 'android' },
      await authHeaders(ownerToken),
    );
    assert.equal(device.response.status, 200);
    assert.equal(device.payload.device.platform, 'android');

    const settings = await putJson(
      baseUrl,
      `/api/users/by-phone/${encodeURIComponent(ownerPhone)}/notifications/settings`,
      { learningReminders: false },
      await authHeaders(ownerToken),
    );
    assert.equal(settings.response.status, 200);
    assert.equal(settings.payload.settings.learningReminders, false);

    const post = await postJson(
      baseUrl,
      '/api/community/posts',
      {
        author: ownerPhone,
        content: 'Nahitaji ushauri kuhusu majani ya nyanya kubadilika rangi.',
        location: 'Mbeya',
        tags: ['Nyanya'],
      },
      await authHeaders(ownerToken),
    );

    const replyPhone = '+255700777888';
    const replyOtp = await postJson(baseUrl, '/api/auth/request-otp', {
      phoneNumber: replyPhone,
    });
    const replyVerify = await postJson(baseUrl, '/api/auth/verify-otp', {
      phoneNumber: replyPhone,
      otp: replyOtp.payload.debugOtp,
      challengeId: replyOtp.payload.challengeId,
    });
    await postJson(
      baseUrl,
      `/api/community/posts/${post.payload.id}/replies`,
      { author: 'Mtaalamu AJE', body: 'Angalia upande wa chini wa majani.' },
      await authHeaders(replyVerify.payload.sessionToken),
    );

    const inbox = await getJson(
      baseUrl,
      `/api/users/by-phone/${encodeURIComponent(ownerPhone)}/notifications`,
      await authHeaders(ownerToken),
    );
    assert.equal(inbox.response.status, 200);
    assert.equal(inbox.payload.notifications.length, 1);
    assert.equal(inbox.payload.notifications[0].type, 'community_reply');

    const read = await postJson(
      baseUrl,
      `/api/users/by-phone/${encodeURIComponent(ownerPhone)}/notifications/${inbox.payload.notifications[0].id}/read`,
      {},
      await authHeaders(ownerToken),
    );
    assert.equal(read.response.status, 200);
    assert.ok(read.payload.notification.readAt);
  });
});
