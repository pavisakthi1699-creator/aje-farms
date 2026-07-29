import crypto from 'node:crypto';

const FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
const OAUTH_TOKEN_URL = 'https://oauth2.googleapis.com/token';

export function createNotificationProvider(
  env = process.env,
  fetchImpl = globalThis.fetch,
) {
  const provider = String(env.AJE_PUSH_PROVIDER ?? 'development').toLowerCase();
  if (provider === 'fcm') {
    return new FcmNotificationProvider(env, fetchImpl);
  }
  return new DevelopmentNotificationProvider();
}

class DevelopmentNotificationProvider {
  name = 'development';
  isProductionReady = false;

  async send(notification, devices = []) {
    if (devices.length === 0) return;
    if (process.env.NODE_ENV !== 'production') {
      console.log(
        `[AJE notification] ${notification.userId}: ${notification.title}`,
      );
    }
  }
}

class FcmNotificationProvider {
  name = 'fcm';

  constructor(env, fetchImpl) {
    const serviceAccount = parseServiceAccount(env);
    this.projectId = serviceAccount.projectId;
    this.clientEmail = serviceAccount.clientEmail;
    this.privateKey = serviceAccount.privateKey;
    this.fetch = fetchImpl;
    this.accessToken = null;
    this.accessTokenExpiresAt = 0;
  }

  get isProductionReady() {
    return Boolean(this.projectId && this.clientEmail && this.privateKey);
  }

  async send(notification, devices = []) {
    if (!this.isProductionReady) {
      throw new Error(
        'FCM push provider is missing project id, client email, or private key.',
      );
    }
    if (devices.length === 0) return;

    const accessToken = await this.#accessToken();
    const endpoint = `https://fcm.googleapis.com/v1/projects/${this.projectId}/messages:send`;
    await Promise.all(
      devices.map(async (device) => {
        try {
          const response = await this.fetch(endpoint, {
            method: 'POST',
            headers: {
              Authorization: `Bearer ${accessToken}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              message: {
                token: device.token,
                notification: {
                  title: notification.title,
                  body: notification.body,
                },
                data: stringifyData({
                  notificationId: notification.id,
                  type: notification.type,
                  ...(notification.data ?? {}),
                }),
                android: {
                  priority: 'HIGH',
                },
              },
            }),
          });
          if (!response.ok) {
            const text = await response.text();
            console.error(`FCM push failed for ${device.platform}: ${text}`);
          }
        } catch (error) {
          console.error(
            `FCM push failed for ${device.platform}:`,
            error instanceof Error ? error.message : error,
          );
        }
      }),
    );
  }

  async #accessToken() {
    const now = Math.floor(Date.now() / 1000);
    if (this.accessToken && this.accessTokenExpiresAt - 60 > now) {
      return this.accessToken;
    }

    const response = await this.fetch(OAUTH_TOKEN_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: createServiceAccountJwt({
          clientEmail: this.clientEmail,
          privateKey: this.privateKey,
          scope: FCM_SCOPE,
          now,
        }),
      }),
    });
    if (!response.ok) {
      const text = await response.text();
      throw new Error(`FCM OAuth token request failed: ${text}`);
    }

    const payload = await response.json();
    this.accessToken = payload.access_token;
    this.accessTokenExpiresAt = now + Number(payload.expires_in ?? 3600);
    return this.accessToken;
  }
}

function parseServiceAccount(env) {
  if (env.FCM_SERVICE_ACCOUNT_JSON) {
    try {
      const parsed = JSON.parse(env.FCM_SERVICE_ACCOUNT_JSON);
      return {
        projectId: parsed.project_id,
        clientEmail: parsed.client_email,
        privateKey: normalizePrivateKey(parsed.private_key),
      };
    } catch {
      return {};
    }
  }

  return {
    projectId: env.FCM_PROJECT_ID,
    clientEmail: env.FCM_CLIENT_EMAIL,
    privateKey: normalizePrivateKey(env.FCM_PRIVATE_KEY),
  };
}

function normalizePrivateKey(privateKey) {
  return privateKey?.replace(/\\n/g, '\n');
}

function createServiceAccountJwt({ clientEmail, privateKey, scope, now }) {
  const header = base64UrlJson({ alg: 'RS256', typ: 'JWT' });
  const payload = base64UrlJson({
    iss: clientEmail,
    scope,
    aud: OAUTH_TOKEN_URL,
    iat: now,
    exp: now + 3600,
  });
  const unsigned = `${header}.${payload}`;
  const signature = crypto
    .createSign('RSA-SHA256')
    .update(unsigned)
    .sign(privateKey);
  return `${unsigned}.${base64Url(signature)}`;
}

function base64UrlJson(value) {
  return base64Url(Buffer.from(JSON.stringify(value)));
}

function base64Url(value) {
  return Buffer.from(value)
    .toString('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}

function stringifyData(data) {
  return Object.fromEntries(
    Object.entries(data)
      .filter(([, value]) => value !== undefined && value !== null)
      .map(([key, value]) => [key, String(value)]),
  );
}
