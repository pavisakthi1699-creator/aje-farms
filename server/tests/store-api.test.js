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
  process.env.AJE_ENABLE_LEGACY_DEV_PAYMENTS = 'true';
  process.env.AJE_DEV_PAYMENT_WEBHOOK_SECRET = 'test-webhook-secret';
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

// Stands in for the Flutter client signing in with Supabase Auth: hits the
// NODE_ENV=development-only dev-session issuer (see api.js) rather than a
// real Supabase Auth token, so the server test suite can run without a
// configured Supabase project.
async function signIn(baseUrl, email) {
  const { response, payload } = await postJson(baseUrl, '/api/auth/dev-session', {
    email,
  });
  assert.equal(response.status, 200);
  return { user: payload.user, sessionToken: payload.sessionToken };
}

test('auth flow creates and restores a user session', async () => {
  await withTestServer(async (baseUrl) => {
    const email = 'farmer1@aje.test';
    const { user, sessionToken } = await signIn(baseUrl, email);

    assert.equal(user.email, email);
    assert.equal(user.subscriptionPlan, null);
    assert.ok(typeof sessionToken === 'string');

    const profile = await getJson(
      baseUrl,
      '/api/users/me',
      await authHeaders(sessionToken),
    );

    assert.equal(profile.response.status, 200);
    assert.equal(profile.payload.user.id, user.id);

    const deniedProfile = await getJson(baseUrl, '/api/users/me');
    assert.equal(deniedProfile.response.status, 401);

    const updatedProfile = await postJson(
      baseUrl,
      '/api/users/me/profile',
      { displayName: 'Asha', preferredLocation: 'Morogoro' },
      await authHeaders(sessionToken),
    );

    assert.equal(updatedProfile.response.status, 200);
    assert.equal(updatedProfile.payload.user.displayName, 'Asha');
    assert.equal(updatedProfile.payload.user.preferredLocation, 'Morogoro');
  });
});

test('learner can permanently delete account data from inside the app', async () => {
  await withTestServer(async (baseUrl) => {
    const email = 'delete-me@aje.test';
    const { sessionToken } = await signIn(baseUrl, email);
    const headers = await authHeaders(sessionToken);

    const post = await postJson(
      baseUrl,
      '/api/community/posts',
      {
        content: 'Hili ni chapisho la kufutwa pamoja na akaunti.',
        location: 'Arusha',
        tags: ['Mengineyo'],
      },
      headers,
    );
    assert.equal(post.response.status, 200);
    await postJson(
      baseUrl,
      '/api/users/me/notifications/devices',
      { token: 'delete-me-device', platform: 'android' },
      headers,
    );

    const missingConfirmation = await postJson(
      baseUrl,
      '/api/users/me/delete',
      {},
      headers,
    );
    assert.equal(missingConfirmation.response.status, 400);

    const deleted = await postJson(
      baseUrl,
      '/api/users/me/delete',
      { confirmation: 'DELETE' },
      headers,
    );
    assert.equal(deleted.response.status, 200);
    assert.equal(deleted.payload.status, 'deleted');

    const oldSession = await getJson(baseUrl, '/api/users/me', headers);
    assert.equal(oldSession.response.status, 401);

    const feed = await getJson(baseUrl, '/api/community/posts');
    assert.ok(!feed.payload.posts.some((item) => item.id === post.payload.id));

    const { sessionToken: adminToken } = await signIn(baseUrl, ADMIN_EMAIL);
    const users = await getJson(
      baseUrl,
      '/api/admin/users?search=delete-me%40aje.test',
      await authHeaders(adminToken),
    );
    assert.equal(users.response.status, 200);
    assert.equal(users.payload.total, 0);
  });
});

test('public privacy and account-deletion pages accept a support request', async () => {
  await withTestServer(async (baseUrl) => {
    const { sessionToken: deletionTargetToken } = await signIn(
      baseUrl,
      'web-delete@aje.test',
    );
    const privacy = await fetch(`${baseUrl}/privacy`);
    assert.equal(privacy.status, 200);
    assert.match(privacy.headers.get('content-type'), /text\/html/);
    assert.match(await privacy.text(), /Sera ya Faragha ya AJE Farms/);

    const deletionPage = await fetch(`${baseUrl}/delete-account`);
    assert.equal(deletionPage.status, 200);
    assert.match(await deletionPage.text(), /Tuma ombi la ufutaji/);

    const submitted = await fetch(`${baseUrl}/delete-account/requests`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ email: 'web-delete@aje.test' }),
    });
    assert.equal(submitted.status, 202);
    assert.match(await submitted.text(), /Ombi limepokelewa/);

    const { sessionToken: adminToken } = await signIn(baseUrl, ADMIN_EMAIL);
    const queue = await getJson(
      baseUrl,
      '/api/admin/account-deletion-requests',
      await authHeaders(adminToken),
    );
    assert.equal(queue.response.status, 200);
    const request = queue.payload.requests.find(
      (item) => item.email === 'web-delete@aje.test',
    );
    assert.equal(request.status, 'pending');

    const resolved = await putJson(
      baseUrl,
      `/api/admin/account-deletion-requests/${request.id}`,
      { status: 'completed', note: 'Identity verified by support.' },
      await authHeaders(adminToken),
    );
    assert.equal(resolved.response.status, 200);
    assert.equal(resolved.payload.request.status, 'completed');
    assert.equal(resolved.payload.deletedAccount, true);
    const deletedSession = await getJson(
      baseUrl,
      '/api/users/me',
      await authHeaders(deletionTargetToken),
    );
    assert.equal(deletedSession.response.status, 401);
  });
});

test('health endpoint reports development readiness', async () => {
  await withTestServer(async (baseUrl) => {
    const health = await getJson(baseUrl, '/api/health');

    assert.equal(health.response.status, 200);
    assert.equal(health.payload.status, 'ok');
    assert.equal(health.payload.checks.store.mode, 'json');
    assert.equal(health.payload.checks.payments.provider, 'manual');
  });
});

test('admin can change learner home topics and catalog returns the update', async () => {
  await withTestServer(async (baseUrl) => {
    const learner = await signIn(baseUrl, 'learner-topics@aje.test');
    const denied = await getJson(
      baseUrl,
      '/api/admin/settings/home-topics',
      await authHeaders(learner.sessionToken),
    );
    assert.equal(denied.response.status, 403);
    const deniedUpdate = await putJson(
      baseUrl,
      '/api/admin/settings/home-topics',
      { topics: ['Mazao', 'Biashara', 'Ufugaji', 'Teknolojia'] },
      await authHeaders(learner.sessionToken),
    );
    assert.equal(deniedUpdate.response.status, 403);
    const deniedV2Update = await putJson(
      baseUrl,
      '/api/admin/settings/home-topics-v2',
      { topics: ['Mazao', 'Biashara', 'Ufugaji', 'Teknolojia'] },
      await authHeaders(learner.sessionToken),
    );
    assert.equal(deniedV2Update.response.status, 403);

    const admin = await signIn(baseUrl, ADMIN_EMAIL);
    const headers = await authHeaders(admin.sessionToken);
    const initial = await getJson(
      baseUrl,
      '/api/admin/settings/home-topics',
      headers,
    );
    assert.equal(initial.response.status, 200);
    assert.deepEqual(initial.payload.topics, [
      'Matunda na Mbogamboga',
      'Nafaka',
      'Mifugo',
      'Mengineyo',
    ]);
    assert.deepEqual(initial.payload.topicsV2, initial.payload.topics);

    const invalid = await putJson(
      baseUrl,
      '/api/admin/settings/home-topics-v2',
      { topics: [] },
      headers,
    );
    assert.equal(invalid.response.status, 400);

    const nonText = await putJson(
      baseUrl,
      '/api/admin/settings/home-topics-v2',
      { topics: ['Mazao', 12, 'Ufugaji', 'Teknolojia'] },
      headers,
    );
    assert.equal(nonText.response.status, 400);

    const tooMany = await putJson(
      baseUrl,
      '/api/admin/settings/home-topics-v2',
      { topics: Array.from({ length: 13 }, (_, index) => `Mada ${index}`) },
      headers,
    );
    assert.equal(tooMany.response.status, 400);

    for (const boundaryTopics of [
      ['Mada moja'],
      Array.from({ length: 12 }, (_, index) => `Mada ${index + 1}`),
    ]) {
      const accepted = await putJson(
        baseUrl,
        '/api/admin/settings/home-topics-v2',
        { topics: boundaryTopics },
        headers,
      );
      assert.equal(accepted.response.status, 200);
      assert.deepEqual(accepted.payload.topicsV2, boundaryTopics);
      assert.equal(accepted.payload.topics.length, 4);

      const legacyRoundTrip = await putJson(
        baseUrl,
        '/api/admin/settings/home-topics',
        { topics: accepted.payload.topics },
        headers,
      );
      assert.equal(legacyRoundTrip.response.status, 200);
      assert.deepEqual(legacyRoundTrip.payload.topicsV2, boundaryTopics);

      if (boundaryTopics.length === 1) {
        const editedProjection = [...accepted.payload.topics];
        editedProjection[1] = 'Mada mbili';
        const legacyExpanded = await putJson(
          baseUrl,
          '/api/admin/settings/home-topics',
          { topics: editedProjection },
          headers,
        );
        assert.equal(legacyExpanded.response.status, 200);
        assert.deepEqual(legacyExpanded.payload.topicsV2, [
          boundaryTopics[0],
          'Mada mbili',
        ]);
      }
    }

    for (const invalidTopics of [
      ['Mazao', 'Biashara', 'Ufugaji', ' '],
      ['M'.repeat(41), 'Biashara', 'Ufugaji', 'Teknolojia'],
      ['Nafaka', ' nafaka ', 'Ufugaji', 'Teknolojia'],
    ]) {
      const rejected = await putJson(
        baseUrl,
        '/api/admin/settings/home-topics-v2',
        { topics: invalidTopics },
        headers,
      );
      assert.equal(rejected.response.status, 400);
    }

    const topics = [
      'Mazao',
      'Biashara',
      'Ufugaji',
      'Teknolojia',
      'Kilimo Hai',
    ];
    const updated = await putJson(
      baseUrl,
      '/api/admin/settings/home-topics-v2',
      { topics },
      headers,
    );
    assert.equal(updated.response.status, 200);
    assert.deepEqual(updated.payload.topics, topics.slice(0, 4));
    assert.deepEqual(updated.payload.topicsV2, topics);

    const conflictingLegacyEdit = await putJson(
      baseUrl,
      '/api/admin/settings/home-topics',
      { topics: ['Kilimo Hai', 'Biashara', 'Ufugaji', 'Teknolojia'] },
      headers,
    );
    assert.equal(conflictingLegacyEdit.response.status, 409);

    const legacyEdit = ['Mazao mapya', 'Biashara', 'Ufugaji', 'Teknolojia'];
    const legacyUpdated = await putJson(
      baseUrl,
      '/api/admin/settings/home-topics',
      { topics: legacyEdit },
      headers,
    );
    assert.equal(legacyUpdated.response.status, 200);
    assert.deepEqual(legacyUpdated.payload.topicsV2, [
      ...legacyEdit,
      'Kilimo Hai',
    ]);

    const catalog = await getJson(baseUrl, '/api/catalog', headers);
    assert.equal(catalog.response.status, 200);
    assert.deepEqual(catalog.payload.homeTopics, legacyEdit);
    assert.deepEqual(catalog.payload.homeTopicsV2, [
      ...legacyEdit,
      'Kilimo Hai',
    ]);
  });
});

test('admin can change community topics and catalog returns the update', async () => {
  await withTestServer(async (baseUrl) => {
    const learner = await signIn(baseUrl, 'learner-community@aje.test');
    const denied = await getJson(
      baseUrl,
      '/api/admin/settings/community-topics',
      await authHeaders(learner.sessionToken),
    );
    assert.equal(denied.response.status, 403);

    const admin = await signIn(baseUrl, ADMIN_EMAIL);
    const headers = await authHeaders(admin.sessionToken);
    const topics = ['Matunda', 'Mifugo', 'Teknolojia'];
    const updated = await putJson(
      baseUrl,
      '/api/admin/settings/community-topics',
      { topics },
      headers,
    );
    assert.equal(updated.response.status, 200);
    assert.deepEqual(updated.payload.topics, topics);

    const catalog = await getJson(baseUrl, '/api/catalog', headers);
    assert.equal(catalog.response.status, 200);
    assert.deepEqual(catalog.payload.communityTopics, topics);

    const reserved = await putJson(
      baseUrl,
      '/api/admin/settings/community-topics',
      { topics: ['Zote'] },
      headers,
    );
    assert.equal(reserved.response.status, 400);
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
    const { sessionToken: token } = await signIn(baseUrl, 'farmer2@aje.test');

    const checkout = await postJson(
      baseUrl,
      '/api/payments/checkout',
      {
        planTitle: 'Wiki 1',
        price: 'TSh 2,000',
        method: 'M-Pesa',
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
      '/api/users/me',
      await authHeaders(token),
    );
    assert.equal(activeProfile.payload.user.subscriptionPlan, 'Wiki 1');

    const cancel = await postJson(
      baseUrl,
      '/api/users/me/subscription/cancel',
      {},
      await authHeaders(token),
    );
    assert.equal(cancel.response.status, 200);
    assert.equal(cancel.payload.user.subscriptionPlan, null);

    const clearedProfile = await getJson(
      baseUrl,
      '/api/users/me',
      await authHeaders(token),
    );
    assert.equal(clearedProfile.payload.user.subscriptionPlan, null);
  });
});

test('learning progress is authenticated and survives store restart', async () => {
  await withTestServer(async (baseUrl) => {
    const { sessionToken: token } = await signIn(baseUrl, ADMIN_EMAIL);

    const catalog = await getJson(baseUrl, '/api/catalog', await authHeaders(token));
    assert.equal(catalog.response.status, 200);
    assert.equal(catalog.payload.courses[0].progress, 0);
    assert.equal(
      catalog.payload.courses[0].lessons[0].id,
      'kuchagua-eneo-la-shamba',
    );
    assert.equal(catalog.payload.courses[0].lessons[0].isCompleted, false);

    const marked = await postJson(
      baseUrl,
      '/api/users/me/progress/lessons',
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
      '/api/users/me/progress',
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
    const { sessionToken: token } = await signIn(baseUrl, 'farmer4@aje.test');

    const checkout = await postJson(
      baseUrl,
      '/api/payments/checkout',
      {
        planTitle: 'Mwezi 1',
        price: 'TSh 5,000',
        method: 'M-Pesa',
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
    const { sessionToken: farmerToken } = await signIn(
      baseUrl,
      'farmer5@aje.test',
    );

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
      { reason: 'misinformation' },
      await authHeaders(farmerToken),
    );
    assert.equal(report.response.status, 200);

    const { user: adminUser, sessionToken: adminToken } = await signIn(
      baseUrl,
      ADMIN_EMAIL,
    );
    assert.equal(adminUser.role, 'admin');

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

    const hiddenQueue = await getJson(
      baseUrl,
      '/api/admin/moderation/reports',
      await authHeaders(adminToken),
    );
    assert.equal(hiddenQueue.payload.reports.length, 1);
    assert.equal(hiddenQueue.payload.reports[0].report.status, 'hidden');

    const community = await getJson(baseUrl, '/api/community/posts');
    assert.equal(
      community.payload.posts.some((item) => item.id === post.payload.id),
      false,
    );

    // `moderatedBy` holds a moderator's internal user id. Hidden posts are
    // filtered out of this feed today, so the field is not currently
    // reachable here, but the endpoint is unauthenticated and must never
    // serialize it regardless.
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
    assert.equal(hidden.payload.post.moderatedBy, adminUser.id);

    const restored = await postJson(
      baseUrl,
      `/api/admin/moderation/posts/${post.payload.id}/resolve`,
      { action: 'restore' },
      await authHeaders(adminToken),
    );
    assert.equal(restored.response.status, 200);
    assert.equal(restored.payload.post.moderationStatus, 'visible');
    const communityAfterRestore = await getJson(baseUrl, '/api/community/posts');
    assert.equal(
      communityAfterRestore.payload.posts.some(
        (item) => item.id === post.payload.id,
      ),
      true,
    );
  });
});

test('learners can report users and block their posts from the authenticated feed', async () => {
  await withTestServer(async (baseUrl) => {
    const { sessionToken: authorToken } = await signIn(
      baseUrl,
      'community-author@aje.test',
    );
    const post = await postJson(
      baseUrl,
      '/api/community/posts',
      {
        content: 'Chapisho la kupima usalama wa jamii na kuzuia mtumiaji.',
        location: 'Dodoma',
        tags: ['Mengineyo'],
      },
      await authHeaders(authorToken),
    );
    assert.equal(post.response.status, 200);

    const { sessionToken: viewerToken } = await signIn(
      baseUrl,
      'community-viewer@aje.test',
    );
    const reported = await postJson(
      baseUrl,
      `/api/community/posts/${post.payload.id}/report-author`,
      { reason: 'harassment' },
      await authHeaders(viewerToken),
    );
    assert.equal(reported.response.status, 200);

    const blocked = await postJson(
      baseUrl,
      `/api/community/posts/${post.payload.id}/block-author`,
      {},
      await authHeaders(viewerToken),
    );
    assert.equal(blocked.response.status, 200);

    const viewerCatalog = await getJson(
      baseUrl,
      '/api/catalog',
      await authHeaders(viewerToken),
    );
    assert.equal(
      viewerCatalog.payload.communityPosts.some(
        (item) => item.id === post.payload.id,
      ),
      false,
    );

    const authorCatalog = await getJson(
      baseUrl,
      '/api/catalog',
      await authHeaders(authorToken),
    );
    assert.equal(
      authorCatalog.payload.communityPosts.some(
        (item) => item.id === post.payload.id,
      ),
      true,
    );

    const { sessionToken: adminToken } = await signIn(baseUrl, ADMIN_EMAIL);
    const queue = await getJson(
      baseUrl,
      '/api/admin/moderation/reports',
      await authHeaders(adminToken),
    );
    const entry = queue.payload.reports.find(
      (item) => item.post.id === post.payload.id,
    );
    assert.equal(entry.report.count, 1);
    assert.deepEqual(entry.report.reasons, ['user_harassment']);
  });
});

test('lesson video endpoints require a session', async () => {
  await withTestServer(async (baseUrl) => {
    const anonymousUrl = await getJson(baseUrl, '/api/lessons/any-id/video-url');
    assert.equal(anonymousUrl.response.status, 401);

    const anonymousRedirect = await getJson(baseUrl, '/api/lessons/any-id/video');
    assert.equal(anonymousRedirect.response.status, 401);

    const { sessionToken } = await signIn(baseUrl, 'farmer6@aje.test');

    // Authenticated but unknown lesson: past the auth gate, so not a 401.
    const authorized = await getJson(
      baseUrl,
      '/api/lessons/any-id/video-url',
      await authHeaders(sessionToken),
    );
    assert.notEqual(authorized.response.status, 401);
  });
});

test('course content is withheld until a staff-approved entitlement is active', async () => {
  await withTestServer(async (baseUrl) => {
    const anonymousCatalog = await getJson(baseUrl, '/api/catalog');
    assert.equal(anonymousCatalog.response.status, 401);

    const { user, sessionToken } = await signIn(
      baseUrl,
      'farmer-entitlement@aje.test',
    );
    const catalog = await getJson(
      baseUrl,
      '/api/catalog',
      await authHeaders(sessionToken),
    );

    assert.equal(catalog.response.status, 200);
    assert.ok(catalog.payload.courses.length > 0);
    for (const course of catalog.payload.courses) {
      for (const lesson of course.lessons) {
        assert.equal(lesson.isPremium, true);
        assert.equal(lesson.description, '');
        assert.equal(lesson.resourceUrl, null);
      }
    }

    const videoLesson = catalog.payload.courses
      .flatMap((course) => course.lessons)
      .find((lesson) => lesson.type === 'video');
    if (videoLesson) {
      const video = await getJson(
        baseUrl,
        `/api/lessons/${videoLesson.id}/video-url`,
        await authHeaders(sessionToken),
      );
      assert.equal(video.response.status, 403);
    }

    const { sessionToken: adminToken } = await signIn(baseUrl, ADMIN_EMAIL);
    const plans = await getJson(
      baseUrl,
      '/api/admin/plans',
      await authHeaders(adminToken),
    );
    const plan = plans.payload.plans[0];
    const recordedPayment = await postJson(
      baseUrl,
      '/api/admin/payments',
      {
        userId: user.id,
        planId: plan.id,
        method: 'cash',
        amountTzs: plan.priceTzs,
        currency: 'TZS',
      },
      await authHeaders(adminToken),
    );
    assert.equal(recordedPayment.response.status, 200);
    const approval = await postJson(
      baseUrl,
      `/api/admin/payments/${recordedPayment.payload.paymentRecord.id}/approve`,
      {},
      await authHeaders(adminToken),
    );
    assert.equal(approval.response.status, 200);

    const unlockedCatalog = await getJson(
      baseUrl,
      '/api/catalog',
      await authHeaders(sessionToken),
    );
    assert.equal(unlockedCatalog.response.status, 200);
    assert.ok(
      unlockedCatalog.payload.courses
        .flatMap((course) => course.lessons)
        .some((lesson) => lesson.description.length > 0),
    );
  });
});

test('community authorship is session-derived and never exposes internal ids', async () => {
  await withTestServer(async (baseUrl) => {
    const farmerEmail = 'farmer7@aje.test';
    const victimEmail = 'victim@aje.test';
    const { sessionToken } = await signIn(baseUrl, farmerEmail);
    const headers = await authHeaders(sessionToken);

    // A client-supplied author must be ignored, not trusted.
    const post = await postJson(
      baseUrl,
      '/api/community/posts',
      {
        author: victimEmail,
        content: 'Nina swali kuhusu kilimo cha mpunga katika msimu huu wa mvua.',
        location: 'Morogoro',
        tags: ['Mpunga'],
      },
      headers,
    );
    assert.equal(post.response.status, 200);
    assert.notEqual(post.payload.author, victimEmail);
    assert.notEqual(post.payload.author, farmerEmail);

    await postJson(
      baseUrl,
      `/api/community/posts/${post.payload.id}/replies`,
      { author: victimEmail, body: 'Jibu la majaribio.' },
      headers,
    );

    const community = await getJson(baseUrl, '/api/community/posts');
    assert.equal(community.response.status, 200);
    const serialized = JSON.stringify(community.payload);
    assert.equal(
      serialized.includes(farmerEmail),
      false,
      'public community feed must not expose the author email',
    );
    assert.equal(
      serialized.includes(victimEmail),
      false,
      'a spoofed author must never be persisted or served',
    );
    assert.equal(
      serialized.includes('authorUserId'),
      false,
      'the private authorship key must not be serialized',
    );
  });
});

test('community image uploads are unavailable outside Supabase-backed environments', async () => {
  await withTestServer(async (baseUrl) => {
    const { sessionToken } = await signIn(baseUrl, 'farmer8@aje.test');
    const headers = await authHeaders(sessionToken);

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
    const { sessionToken } = await signIn(baseUrl, 'farmer9@aje.test');
    const headers = await authHeaders(sessionToken);

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
    const { sessionToken: adminSessionToken } = await signIn(baseUrl, ADMIN_EMAIL);
    const adminHeaders = await authHeaders(adminSessionToken);

    const { sessionToken: farmerSessionToken } = await signIn(
      baseUrl,
      'farmer10@aje.test',
    );
    const farmerHeaders = await authHeaders(farmerSessionToken);

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
    const { sessionToken: adminSessionToken } = await signIn(baseUrl, ADMIN_EMAIL);
    const adminHeaders = await authHeaders(adminSessionToken);

    const catalog = await getJson(baseUrl, '/api/catalog', adminHeaders);
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

    const catalogAfterDraft = await getJson(
      baseUrl,
      '/api/catalog',
      adminHeaders,
    );
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

    const catalogAfterPublish = await getJson(
      baseUrl,
      '/api/catalog',
      adminHeaders,
    );
    assert.equal(
      catalogAfterPublish.payload.courses.find((course) => course.id === 'pasheni')
        .title,
      'Kilimo cha Pasheni Kilichochapishwa',
    );
  });
});

test('admin content documents can be drafted and published into catalog', async () => {
  await withTestServer(async (baseUrl) => {
    const { sessionToken: adminSessionToken } = await signIn(baseUrl, ADMIN_EMAIL);
    const adminHeaders = await authHeaders(adminSessionToken);

    const catalog = await getJson(baseUrl, '/api/catalog', adminHeaders);
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

    const catalogAfterDraft = await getJson(
      baseUrl,
      '/api/catalog',
      adminHeaders,
    );
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

    const catalogAfterPublish = await getJson(
      baseUrl,
      '/api/catalog',
      adminHeaders,
    );
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
    const { sessionToken: learnerToken } = await signIn(
      baseUrl,
      'learner1@aje.test',
    );

    const forbidden = await getJson(
      baseUrl,
      '/api/admin/users',
      await authHeaders(learnerToken),
    );
    assert.equal(forbidden.response.status, 403);
  });
});

test('admin can suspend learner access and reset the learner to pending', async () => {
  await withTestServer(async (baseUrl) => {
    const { user: learner, sessionToken: learnerToken } = await signIn(
      baseUrl,
      'moderated-learner@aje.test',
    );
    const { user: admin, sessionToken: adminToken } = await signIn(
      baseUrl,
      ADMIN_EMAIL,
    );
    const adminHeaders = await authHeaders(adminToken);

    const plans = await getJson(baseUrl, '/api/admin/plans', adminHeaders);
    const plan = plans.payload.plans[0];
    const payment = await postJson(
      baseUrl,
      '/api/admin/payments',
      {
        userId: learner.id,
        planId: plan.id,
        method: 'cash',
        amountTzs: plan.priceTzs,
      },
      adminHeaders,
    );
    const paymentId = payment.payload.paymentRecord.id;
    const approved = await postJson(
      baseUrl,
      `/api/admin/payments/${paymentId}/approve`,
      {},
      adminHeaders,
    );
    assert.equal(approved.response.status, 200);
    assert.equal(approved.payload.paymentRecord.status, 'approved');

    const unlocked = await getJson(
      baseUrl,
      '/api/catalog',
      await authHeaders(learnerToken),
    );
    assert.ok(
      unlocked.payload.courses
        .flatMap((course) => course.lessons)
        .some((lesson) => lesson.description.length > 0),
    );

    const forbidden = await putJson(
      baseUrl,
      `/api/admin/users/${learner.id}/access`,
      { action: 'suspend' },
      await authHeaders(learnerToken),
    );
    assert.equal(forbidden.response.status, 403);

    const protectedAdmin = await putJson(
      baseUrl,
      `/api/admin/users/${admin.id}/access`,
      { action: 'suspend' },
      adminHeaders,
    );
    assert.equal(protectedAdmin.response.status, 409);

    const suspended = await putJson(
      baseUrl,
      `/api/admin/users/${learner.id}/access`,
      { action: 'suspend', reason: 'Community safety review' },
      adminHeaders,
    );
    assert.equal(suspended.response.status, 200);
    assert.equal(suspended.payload.user.accountStatus, 'suspended');

    const paymentsAfterSuspension = await getJson(
      baseUrl,
      `/api/admin/payments?userId=${learner.id}`,
      adminHeaders,
    );
    assert.equal(
      paymentsAfterSuspension.payload.records.find(
        (record) => record.id === paymentId,
      ).status,
      'reversed',
    );
    const locked = await getJson(
      baseUrl,
      '/api/catalog',
      await authHeaders(learnerToken),
    );
    for (const lesson of locked.payload.courses.flatMap(
      (course) => course.lessons,
    )) {
      assert.equal(lesson.description, '');
      assert.equal(lesson.resourceUrl, null);
    }

    const blockedPayment = await postJson(
      baseUrl,
      '/api/admin/payments',
      {
        userId: learner.id,
        planId: plan.id,
        method: 'cash',
        amountTzs: plan.priceTzs,
      },
      adminHeaders,
    );
    const blockedApproval = await postJson(
      baseUrl,
      `/api/admin/payments/${blockedPayment.payload.paymentRecord.id}/approve`,
      {},
      adminHeaders,
    );
    assert.equal(blockedApproval.response.status, 409);

    const reset = await putJson(
      baseUrl,
      `/api/admin/users/${learner.id}/access`,
      { action: 'reset_pending' },
      adminHeaders,
    );
    assert.equal(reset.response.status, 200);
    assert.equal(reset.payload.user.accountStatus, 'pending_activation');
  });
});

test('admin source review routes enforce authorization and validation', async () => {
  await withTestServer(async (baseUrl) => {
    const anonymous = await getJson(
      baseUrl,
      '/api/admin/content/source-segments',
    );
    assert.equal(anonymous.response.status, 401);

    const { sessionToken: learnerToken } = await signIn(
      baseUrl,
      'learner2@aje.test',
    );
    const forbidden = await getJson(
      baseUrl,
      '/api/admin/content/source-segments',
      await authHeaders(learnerToken),
    );
    assert.equal(forbidden.response.status, 403);

    const { sessionToken: adminSessionToken } = await signIn(baseUrl, ADMIN_EMAIL);
    const adminHeaders = await authHeaders(adminSessionToken);
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
    const learnerEmail = 'learner3@aje.test';
    const { sessionToken: learnerSessionToken } = await signIn(
      baseUrl,
      learnerEmail,
    );
    const learnerWhoAmI = await getJson(
      baseUrl,
      '/api/auth/whoami',
      await authHeaders(learnerSessionToken),
    );
    assert.equal(learnerWhoAmI.response.status, 200);
    assert.equal(learnerWhoAmI.payload.user.email, learnerEmail);
    assert.equal(learnerWhoAmI.payload.role, 'learner');
    assert.equal(learnerWhoAmI.payload.hasAdminAccess, false);
    assert.equal(learnerWhoAmI.payload.allowlistedAdmin, false);
    assert.equal(learnerWhoAmI.payload.source, 'learner');

    const { sessionToken: adminSessionToken } = await signIn(baseUrl, ADMIN_EMAIL);
    const adminWhoAmI = await getJson(
      baseUrl,
      '/api/auth/whoami',
      await authHeaders(adminSessionToken),
    );
    assert.equal(adminWhoAmI.response.status, 200);
    assert.equal(adminWhoAmI.payload.user.email, ADMIN_EMAIL);
    assert.equal(adminWhoAmI.payload.role, 'admin');
    assert.equal(adminWhoAmI.payload.hasAdminAccess, true);
    assert.equal(adminWhoAmI.payload.allowlistedAdmin, true);
    assert.equal(adminWhoAmI.payload.source, 'email_allowlist');

    process.env.AJE_ADMIN_EMAILS = '';
    const revokedWhoAmI = await getJson(
      baseUrl,
      '/api/auth/whoami',
      await authHeaders(adminSessionToken),
    );
    assert.equal(revokedWhoAmI.response.status, 200);
    assert.equal(revokedWhoAmI.payload.role, 'learner');
    assert.equal(revokedWhoAmI.payload.hasAdminAccess, false);
    assert.equal(revokedWhoAmI.payload.allowlistedAdmin, false);
    assert.equal(revokedWhoAmI.payload.source, 'learner');

    const revokedAdminRequest = await getJson(
      baseUrl,
      '/api/admin/users',
      await authHeaders(adminSessionToken),
    );
    assert.equal(revokedAdminRequest.response.status, 403);
  });
});

test('admin users endpoint returns monitoring summaries with search', async () => {
  await withTestServer(async (baseUrl) => {
    const learnerEmail = 'learner4@aje.test';
    const { user: learner, sessionToken: learnerToken } = await signIn(
      baseUrl,
      learnerEmail,
    );
    const { sessionToken: adminToken } = await signIn(baseUrl, ADMIN_EMAIL);
    const adminHeaders = await authHeaders(adminToken);
    const plans = await getJson(baseUrl, '/api/admin/plans', adminHeaders);
    const plan = plans.payload.plans[0];
    const payment = await postJson(
      baseUrl,
      '/api/admin/payments',
      {
        userId: learner.id,
        planId: plan.id,
        method: 'cash',
        amountTzs: plan.priceTzs,
        currency: 'TZS',
      },
      adminHeaders,
    );
    assert.equal(payment.response.status, 200);
    const approval = await postJson(
      baseUrl,
      `/api/admin/payments/${payment.payload.paymentRecord.id}/approve`,
      {},
      adminHeaders,
    );
    assert.equal(approval.response.status, 200);

    const completed = await postJson(
      baseUrl,
      '/api/users/me/progress/lessons',
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
        author: learnerEmail,
        content: 'Ninaomba ushauri kuhusu afya ya pasheni wiki hii.',
        location: 'Morogoro',
        tags: ['Pasheni'],
      },
      await authHeaders(learnerToken),
    );
    assert.equal(community.response.status, 200);

    const list = await getJson(
      baseUrl,
      `/api/admin/users?search=${encodeURIComponent(learnerEmail)}&limit=10&offset=0`,
      adminHeaders,
    );
    assert.equal(list.response.status, 200);
    assert.ok(typeof list.payload.total === 'number');
    assert.ok(Array.isArray(list.payload.users));
    assert.ok(list.payload.users.length >= 1);
    const user = list.payload.users.find(
      (entry) => entry.email === learnerEmail,
    );
    assert.ok(user);
    assert.equal(user.learningProgressCount, 1);
    assert.equal(user.paymentTransactionsCount, 1);
    assert.equal(user.communityPostsCount, 1);
  });
});

test('notification settings, devices, inbox, and read state are backend backed', async () => {
  await withTestServer(async (baseUrl) => {
    const ownerEmail = 'owner@aje.test';
    const { sessionToken: ownerToken } = await signIn(baseUrl, ownerEmail);

    const device = await postJson(
      baseUrl,
      '/api/users/me/notifications/devices',
      { token: 'test-device-token', platform: 'android' },
      await authHeaders(ownerToken),
    );
    assert.equal(device.response.status, 200);
    assert.equal(device.payload.device.platform, 'android');

    const settings = await putJson(
      baseUrl,
      '/api/users/me/notifications/settings',
      { learningReminders: false },
      await authHeaders(ownerToken),
    );
    assert.equal(settings.response.status, 200);
    assert.equal(settings.payload.settings.learningReminders, false);

    const post = await postJson(
      baseUrl,
      '/api/community/posts',
      {
        author: ownerEmail,
        content: 'Nahitaji ushauri kuhusu majani ya nyanya kubadilika rangi.',
        location: 'Mbeya',
        tags: ['Nyanya'],
      },
      await authHeaders(ownerToken),
    );

    const { sessionToken: replySessionToken } = await signIn(
      baseUrl,
      'replier@aje.test',
    );
    await postJson(
      baseUrl,
      `/api/community/posts/${post.payload.id}/replies`,
      { author: 'Mtaalamu AJE', body: 'Angalia upande wa chini wa majani.' },
      await authHeaders(replySessionToken),
    );

    const inbox = await getJson(
      baseUrl,
      '/api/users/me/notifications',
      await authHeaders(ownerToken),
    );
    assert.equal(inbox.response.status, 200);
    assert.equal(inbox.payload.notifications.length, 1);
    assert.equal(inbox.payload.notifications[0].type, 'community_reply');

    const read = await postJson(
      baseUrl,
      `/api/users/me/notifications/${inbox.payload.notifications[0].id}/read`,
      {},
      await authHeaders(ownerToken),
    );
    assert.equal(read.response.status, 200);
    assert.ok(read.payload.notification.readAt);
  });
});
