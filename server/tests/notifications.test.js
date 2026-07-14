import assert from 'node:assert/strict';
import { generateKeyPairSync } from 'node:crypto';
import test from 'node:test';

import { createAndDispatchNotification } from '../api.js';
import { createNotificationProvider } from '../notifications.js';

function testPrivateKey() {
  const { privateKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
  return privateKey.export({ type: 'pkcs8', format: 'pem' });
}

test('notification provider defaults to development logging', () => {
  const provider = createNotificationProvider({}, async () => {
    throw new Error('development provider should not call fetch');
  });

  assert.equal(provider.name, 'development');
  assert.equal(provider.isProductionReady, false);
});

test('fcm notification provider sends one message per registered device', async () => {
  const requests = [];
  const fetchImpl = async (url, options) => {
    requests.push({ url, options });
    if (String(url).includes('oauth2.googleapis.com')) {
      return Response.json({ access_token: 'access-token', expires_in: 3600 });
    }
    return Response.json({ name: 'projects/aje/messages/1' });
  };

  const provider = createNotificationProvider(
    {
      AJE_PUSH_PROVIDER: 'fcm',
      FCM_PROJECT_ID: 'aje-farms',
      FCM_CLIENT_EMAIL: 'firebase-adminsdk@example.iam.gserviceaccount.com',
      FCM_PRIVATE_KEY: testPrivateKey(),
    },
    fetchImpl,
  );

  assert.equal(provider.name, 'fcm');
  assert.equal(provider.isProductionReady, true);

  await provider.send(
    {
      id: 'notification-1',
      type: 'community_reply',
      title: 'Jibu jipya',
      body: 'Mkulima amejibu post yako.',
      data: { postId: 'post-1' },
    },
    [
      {
        token: 'device-token-1',
        platform: 'android',
      },
      {
        token: 'device-token-2',
        platform: 'android',
      },
    ],
  );

  assert.equal(requests.length, 3);
  assert.equal(
    requests[0].url,
    'https://oauth2.googleapis.com/token',
  );
  assert.equal(
    requests[1].url,
    'https://fcm.googleapis.com/v1/projects/aje-farms/messages:send',
  );

  const firstMessage = JSON.parse(requests[1].options.body);
  assert.equal(firstMessage.message.token, 'device-token-1');
  assert.equal(firstMessage.message.notification.title, 'Jibu jipya');
  assert.equal(firstMessage.message.notification.body, 'Mkulima amejibu post yako.');
  assert.equal(firstMessage.message.data.type, 'community_reply');
  assert.equal(firstMessage.message.data.postId, 'post-1');
});

test('fcm notification provider treats malformed service account json as not ready', () => {
  const provider = createNotificationProvider({
    AJE_PUSH_PROVIDER: 'fcm',
    FCM_SERVICE_ACCOUNT_JSON: 'not-json',
  });

  assert.equal(provider.name, 'fcm');
  assert.equal(provider.isProductionReady, false);
});

test('notification dispatch contains provider failures after storing the notification', async () => {
  const storedNotification = {
    id: 'notification-1',
    phoneNumber: '+255700000000',
    type: 'community_reply',
    title: 'Jibu jipya',
    body: 'Mkulima amejibu post yako.',
  };
  const store = {
    async createNotification() {
      return storedNotification;
    },
    async notificationDevices() {
      return [{ token: 'device-token-1', platform: 'android' }];
    },
  };
  const notificationProvider = {
    async send() {
      throw new Error('FCM OAuth token request failed: unavailable');
    },
  };

  const originalConsoleError = console.error;
  console.error = () => {};
  try {
    const result = await createAndDispatchNotification({
      store,
      notificationProvider,
      phoneNumber: storedNotification.phoneNumber,
      type: storedNotification.type,
      title: storedNotification.title,
      body: storedNotification.body,
      data: {},
    });

    assert.equal(result, storedNotification);
  } finally {
    console.error = originalConsoleError;
  }
});
