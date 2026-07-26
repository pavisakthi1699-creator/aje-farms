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

    const updatedProfile = await postJson(
      baseUrl,
      `/api/users/by-phone/${encodeURIComponent(phoneNumber)}/profile`,
      { displayName: 'Asha', preferredLocation: 'Morogoro' },
      await authHeaders(verify.payload.sessionToken),
    );

    assert.equal(updatedProfile.response.status, 200);
    assert.equal(updatedProfile.payload.user.displayName, 'Asha');
    assert.equal(updatedProfile.payload.user.preferredLocation, 'Morogoro');
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

test('liveness endpoint reports a running API independently of providers', async () => {
  await withTestServer(async (baseUrl) => {
    const health = await getJson(baseUrl, '/api/health/live');

    assert.equal(health.response.status, 200);
    assert.deepEqual(health.payload, { status: 'ok' });
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
    assert.equal(
      catalog.payload.courses[0].lessons[0].id,
      'kuchagua-eneo-la-shamba',
    );
    assert.equal(catalog.payload.courses[0].lessons[0].isCompleted, false);

    const marked = await postJson(
      baseUrl,
      `/api/users/by-phone/${encodeURIComponent(phoneNumber)}/progress/lessons`,
      {
        courseId: 'pasheni',
        lessonId: 'kuchagua-eneo-la-shamba',
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
      'pasheni:kuchagua-eneo-la-shamba',
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
    assert.equal(adminVerify.payload.user.role, 'admin');

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

    // `moderatedBy` holds a moderator phone number. Hidden posts are filtered
    // out of this feed today, so the field is not currently reachable here, but
    // the endpoint is unauthenticated and must never serialize it regardless.
    for (const item of community.payload.posts) {
      assert.equal(
        Object.hasOwn(item, 'moderatedBy'),
        false,
        'public community feed must not expose moderatedBy',
      );
      assert.equal(
        Object.hasOwn(item, 'moderatedAt'),
        false,
        'public community feed must not expose moderatedAt',
      );
    }

    // Admin moderation routes still need the fields the dashboard renders.
    assert.equal(hidden.payload.post.moderatedBy, adminPhone);
  });
});

test('lesson video endpoints require a session', async () => {
  await withTestServer(async (baseUrl) => {
    const anonymousUrl = await getJson(baseUrl, '/api/lessons/any-id/video-url');
    assert.equal(anonymousUrl.response.status, 401);

    const anonymousRedirect = await getJson(baseUrl, '/api/lessons/any-id/video');
    assert.equal(anonymousRedirect.response.status, 401);

    const phone = '+255700222333';
    const otp = await postJson(baseUrl, '/api/auth/request-otp', {
      phoneNumber: phone,
    });
    const verify = await postJson(baseUrl, '/api/auth/verify-otp', {
      phoneNumber: phone,
      otp: otp.payload.debugOtp,
      challengeId: otp.payload.challengeId,
    });

    // Authenticated but unknown lesson: past the auth gate, so not a 401.
    const authorized = await getJson(
      baseUrl,
      '/api/lessons/any-id/video-url',
      await authHeaders(verify.payload.sessionToken),
    );
    assert.notEqual(authorized.response.status, 401);
  });
});

test('community authorship is session-derived and never exposes phone numbers', async () => {
  await withTestServer(async (baseUrl) => {
    const farmerPhone = '+255700888999';
    const victimPhone = '+255799999999';
    const otp = await postJson(baseUrl, '/api/auth/request-otp', {
      phoneNumber: farmerPhone,
    });
    const verify = await postJson(baseUrl, '/api/auth/verify-otp', {
      phoneNumber: farmerPhone,
      otp: otp.payload.debugOtp,
      challengeId: otp.payload.challengeId,
    });
    const headers = await authHeaders(verify.payload.sessionToken);

    // A client-supplied author must be ignored, not trusted.
    const post = await postJson(
      baseUrl,
      '/api/community/posts',
      {
        author: victimPhone,
        content: 'Nina swali kuhusu kilimo cha mpunga katika msimu huu wa mvua.',
        location: 'Morogoro',
        tags: ['Mpunga'],
      },
      headers,
    );
    assert.equal(post.response.status, 200);
    assert.notEqual(post.payload.author, victimPhone);
    assert.notEqual(post.payload.author, farmerPhone);

    await postJson(
      baseUrl,
      `/api/community/posts/${post.payload.id}/replies`,
      { author: victimPhone, body: 'Jibu la majaribio.' },
      headers,
    );

    const community = await getJson(baseUrl, '/api/community/posts');
    assert.equal(community.response.status, 200);
    const serialized = JSON.stringify(community.payload);
    assert.equal(
      serialized.includes(farmerPhone),
      false,
      'public community feed must not expose the author phone number',
    );
    assert.equal(
      serialized.includes(victimPhone),
      false,
      'a spoofed author must never be persisted or served',
    );
    assert.equal(
      serialized.includes('authorPhone'),
      false,
      'the private authorship key must not be serialized',
    );
  });
});

test('community image uploads are unavailable outside Supabase-backed environments', async () => {
  await withTestServer(async (baseUrl) => {
    const phoneNumber = '+255700111222';
    const otp = await postJson(baseUrl, '/api/auth/request-otp', {
      phoneNumber,
    });
    const verify = await postJson(baseUrl, '/api/auth/verify-otp', {
      phoneNumber,
      otp: otp.payload.debugOtp,
      challengeId: otp.payload.challengeId,
    });
    const headers = await authHeaders(verify.payload.sessionToken);

    const response = await fetch(`${baseUrl}/api/community/posts/image`, {
      method: 'POST',
      headers: { ...headers, 'Content-Type': 'image/jpeg' },
      body: Buffer.from([0xff, 0xd8, 0xff, 0xd9]),
    });
    assert.equal(response.status, 501);

    const unauthenticated = await fetch(
      `${baseUrl}/api/community/posts/image`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'image/jpeg' },
        body: Buffer.from([0xff, 0xd8, 0xff, 0xd9]),
      },
    );
    assert.equal(unauthenticated.status, 401);
  });
});

test('a post referencing an invalid image path is rejected', async () => {
  await withTestServer(async (baseUrl) => {
    const phoneNumber = '+255700111333';
    const otp = await postJson(baseUrl, '/api/auth/request-otp', {
      phoneNumber,
    });
    const verify = await postJson(baseUrl, '/api/auth/verify-otp', {
      phoneNumber,
      otp: otp.payload.debugOtp,
      challengeId: otp.payload.challengeId,
    });
    const headers = await authHeaders(verify.payload.sessionToken);

    const post = await postJson(
      baseUrl,
      '/api/community/posts',
      {
        content: 'Nina swali kuhusu magonjwa ya nyanya wakati wa mvua.',
        location: 'Arusha',
        tags: ['Nyanya'],
        imagePath: '../../etc/passwd',
      },
      headers,
    );
    assert.equal(post.response.status, 400);
  });
});

test('admin-authored posts and replies are flagged as expert content', async () => {
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

    const farmerPhone = '+255700111444';
    const farmerOtp = await postJson(baseUrl, '/api/auth/request-otp', {
      phoneNumber: farmerPhone,
    });
    const farmerVerify = await postJson(baseUrl, '/api/auth/verify-otp', {
      phoneNumber: farmerPhone,
      otp: farmerOtp.payload.debugOtp,
      challengeId: farmerOtp.payload.challengeId,
    });
    const farmerHeaders = await authHeaders(farmerVerify.payload.sessionToken);

    const adminPost = await postJson(
      baseUrl,
      '/api/community/posts',
      {
        content: 'Ushauri wa kitaalamu kuhusu udhibiti wa wadudu waharibifu.',
        location: 'Dodoma',
        tags: ['Wadudu'],
      },
      adminHeaders,
    );
    assert.equal(adminPost.response.status, 200);
    assert.equal(adminPost.payload.isExpert, true);

    const farmerPost = await postJson(
      baseUrl,
      '/api/community/posts',
      {
        content: 'Swali kuhusu udhibiti wa wadudu kwenye shamba langu.',
        location: 'Singida',
        tags: ['Wadudu'],
      },
      farmerHeaders,
    );
    assert.equal(farmerPost.response.status, 200);
    assert.equal(farmerPost.payload.isExpert, false);

    const adminReply = await postJson(
      baseUrl,
      `/api/community/posts/${farmerPost.payload.id}/replies`,
      { body: 'Jaribu kutumia dawa ya asili kwanza.' },
      adminHeaders,
    );
    assert.equal(adminReply.response.status, 200);
    assert.equal(adminReply.payload.isExpert, true);

    const community = await getJson(baseUrl, '/api/community/posts');
    const updatedFarmerPost = community.payload.posts.find(
      (item) => item.id === farmerPost.payload.id,
    );
    assert.equal(updatedFarmerPost.replies[0].isExpert, true);
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

    const duplicate = await putJson(
      baseUrl,
      '/api/admin/content/courses/pasheni',
      {
        status: 'draft',
        createOnly: true,
        course: pasheni,
      },
      adminHeaders,
    );
    assert.equal(duplicate.response.status, 409);

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
    const document = {
      id: 'admin-document-test',
      title: 'Nyaraka ya Majaribio',
      courseId: 'pasheni',
      courseTitle: 'Kilimo cha Pasheni',
      description: 'Nyaraka ya kuthibitisha mzunguko wa uhariri.',
      type: 'pdf',
      sizeLabel: 'PDF',
      isPremium: false,
    };

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

test('admin users endpoint is role-gated', async () => {
  await withTestServer(async (baseUrl) => {
    const learnerPhone = '+255700333444';
    const learnerOtp = await postJson(baseUrl, '/api/auth/request-otp', {
      phoneNumber: learnerPhone,
    });
    const learnerVerify = await postJson(baseUrl, '/api/auth/verify-otp', {
      phoneNumber: learnerPhone,
      otp: learnerOtp.payload.debugOtp,
      challengeId: learnerOtp.payload.challengeId,
    });
    const learnerToken = learnerVerify.payload.sessionToken;

    const forbidden = await getJson(
      baseUrl,
      '/api/admin/users',
      await authHeaders(learnerToken),
    );
    assert.equal(forbidden.response.status, 403);
  });
});

test('admin source review routes enforce authorization and validation', async () => {
  await withTestServer(async (baseUrl) => {
    const anonymous = await getJson(
      baseUrl,
      '/api/admin/content/source-segments',
    );
    assert.equal(anonymous.response.status, 401);

    const learnerPhone = '+255700333445';
    const learnerOtp = await postJson(baseUrl, '/api/auth/request-otp', {
      phoneNumber: learnerPhone,
    });
    const learnerVerify = await postJson(baseUrl, '/api/auth/verify-otp', {
      phoneNumber: learnerPhone,
      otp: learnerOtp.payload.debugOtp,
      challengeId: learnerOtp.payload.challengeId,
    });
    const forbidden = await getJson(
      baseUrl,
      '/api/admin/content/source-segments',
      await authHeaders(learnerVerify.payload.sessionToken),
    );
    assert.equal(forbidden.response.status, 403);

    const adminPhone = '+255799000111';
    const adminOtp = await postJson(baseUrl, '/api/auth/request-otp', {
      phoneNumber: adminPhone,
    });
    const adminVerify = await postJson(baseUrl, '/api/auth/verify-otp', {
      phoneNumber: adminPhone,
      otp: adminOtp.payload.debugOtp,
      challengeId: adminOtp.payload.challengeId,
    });
    const adminHeaders = await authHeaders(
      adminVerify.payload.sessionToken,
    );
    const segments = await getJson(
      baseUrl,
      '/api/admin/content/source-segments?search=maharage',
      adminHeaders,
    );
    assert.equal(segments.response.status, 200);
    assert.deepEqual(segments.payload.segments, []);

    const invalid = await postJson(
      baseUrl,
      '/api/admin/content/lessons/lesson-1/source-review',
      {},
      adminHeaders,
    );
    assert.equal(invalid.response.status, 400);

    const unsupported = await postJson(
      baseUrl,
      '/api/admin/content/lessons/lesson-1/source-review',
      {
        sourceSegmentId: 'segment-1',
        evidenceNote: 'Ushahidi',
        groundingFact: 'Ukweli',
      },
      adminHeaders,
    );
    assert.equal(unsupported.response.status, 501);
  });
});

test('whoami exposes safe admin access diagnostics', async () => {
  await withTestServer(async (baseUrl) => {
    const learnerPhone = '+255700123456';
    const learnerOtp = await postJson(baseUrl, '/api/auth/request-otp', {
      phoneNumber: learnerPhone,
    });
    const learnerVerify = await postJson(baseUrl, '/api/auth/verify-otp', {
      phoneNumber: learnerPhone,
      otp: learnerOtp.payload.debugOtp,
      challengeId: learnerOtp.payload.challengeId,
    });
    const learnerWhoAmI = await getJson(
      baseUrl,
      '/api/auth/whoami',
      await authHeaders(learnerVerify.payload.sessionToken),
    );
    assert.equal(learnerWhoAmI.response.status, 200);
    assert.equal(learnerWhoAmI.payload.phoneNumber, learnerPhone);
    assert.equal(learnerWhoAmI.payload.role, 'learner');
    assert.equal(learnerWhoAmI.payload.hasAdminAccess, false);
    assert.equal(learnerWhoAmI.payload.allowlistedAdmin, false);
    assert.equal(learnerWhoAmI.payload.source, 'learner');

    const adminPhone = '+255799000111';
    const adminOtp = await postJson(baseUrl, '/api/auth/request-otp', {
      phoneNumber: adminPhone,
    });
    const adminVerify = await postJson(baseUrl, '/api/auth/verify-otp', {
      phoneNumber: adminPhone,
      otp: adminOtp.payload.debugOtp,
      challengeId: adminOtp.payload.challengeId,
    });
    const adminWhoAmI = await getJson(
      baseUrl,
      '/api/auth/whoami',
      await authHeaders(adminVerify.payload.sessionToken),
    );
    assert.equal(adminWhoAmI.response.status, 200);
    assert.equal(adminWhoAmI.payload.phoneNumber, adminPhone);
    assert.equal(adminWhoAmI.payload.role, 'admin');
    assert.equal(adminWhoAmI.payload.hasAdminAccess, true);
    assert.equal(adminWhoAmI.payload.allowlistedAdmin, true);
    assert.equal(adminWhoAmI.payload.source, 'phone_allowlist');

    process.env.AJE_ADMIN_PHONE_NUMBERS = '';
    const revokedWhoAmI = await getJson(
      baseUrl,
      '/api/auth/whoami',
      await authHeaders(adminVerify.payload.sessionToken),
    );
    assert.equal(revokedWhoAmI.response.status, 200);
    assert.equal(revokedWhoAmI.payload.role, 'learner');
    assert.equal(revokedWhoAmI.payload.hasAdminAccess, false);
    assert.equal(revokedWhoAmI.payload.allowlistedAdmin, false);
    assert.equal(revokedWhoAmI.payload.source, 'learner');

    const revokedAdminRequest = await getJson(
      baseUrl,
      '/api/admin/users',
      await authHeaders(adminVerify.payload.sessionToken),
    );
    assert.equal(revokedAdminRequest.response.status, 403);
  });
});

test('admin users endpoint returns monitoring summaries with search', async () => {
  await withTestServer(async (baseUrl) => {
    const learnerPhone = '+255700111222';
    const learnerOtp = await postJson(baseUrl, '/api/auth/request-otp', {
      phoneNumber: learnerPhone,
    });
    const learnerVerify = await postJson(baseUrl, '/api/auth/verify-otp', {
      phoneNumber: learnerPhone,
      otp: learnerOtp.payload.debugOtp,
      challengeId: learnerOtp.payload.challengeId,
    });
    const learnerToken = learnerVerify.payload.sessionToken;

    const checkout = await postJson(
      baseUrl,
      '/api/payments/checkout',
      {
        planTitle: 'Wiki 1',
        price: 'TSh 2,000',
        method: 'M-Pesa',
        phoneNumber: learnerPhone,
      },
      await authHeaders(learnerToken),
    );
    assert.equal(checkout.response.status, 200);

    const completed = await postJson(
      baseUrl,
      `/api/users/by-phone/${encodeURIComponent(learnerPhone)}/progress/lessons`,
      {
        courseId: 'pasheni',
        lessonId: 'kuchagua-eneo-la-shamba',
      },
      await authHeaders(learnerToken),
    );
    assert.equal(completed.response.status, 200);

    const community = await postJson(
      baseUrl,
      '/api/community/posts',
      {
        author: learnerPhone,
        content: 'Ninaomba ushauri kuhusu afya ya pasheni wiki hii.',
        location: 'Morogoro',
        tags: ['Pasheni'],
      },
      await authHeaders(learnerToken),
    );
    assert.equal(community.response.status, 200);

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
    assert.equal(adminVerify.payload.user.role, 'admin');

    const list = await getJson(
      baseUrl,
      `/api/admin/users?search=${encodeURIComponent('255700111222')}&limit=10&offset=0`,
      await authHeaders(adminToken),
    );
    assert.equal(list.response.status, 200);
    assert.ok(typeof list.payload.total === 'number');
    assert.ok(Array.isArray(list.payload.users));
    assert.ok(list.payload.users.length >= 1);
    const user = list.payload.users.find(
      (entry) => entry.phoneNumber === learnerPhone,
    );
    assert.ok(user);
    assert.equal(user.learningProgressCount, 1);
    assert.equal(user.paymentTransactionsCount, 1);
    assert.equal(user.communityPostsCount, 1);
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
