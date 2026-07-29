import assert from 'node:assert/strict';
import test from 'node:test';

import { releasePreflight } from '../preflight.js';

const SUPABASE_AUTH_ENV = {
  SUPABASE_URL: 'https://project.supabase.co',
  SUPABASE_SERVICE_ROLE_KEY: 'service-role-key',
};

test('release preflight reports missing production blockers', () => {
  const result = releasePreflight({}, () => false);

  assert.equal(result.ok, false);
  assert.ok(result.blockers.includes('NODE_ENV is required for release.'));
  assert.ok(
    result.blockers.includes(
      'AJE_STORE must be "postgres" or "supabase" for release.',
    ),
  );
  assert.ok(
    result.blockers.includes(
      'aje_farms_mobile/android/key.properties is required to sign release builds.',
    ),
  );
});

test('release preflight accepts dedicated Supabase config', () => {
  const result = releasePreflight(
    {
      NODE_ENV: 'production',
      APP_URL: 'https://api.ajefarms.co.tz',
      AJE_STORE: 'supabase',
      SUPABASE_DATABASE_URL: 'postgresql://postgres.example:pass@db.example.supabase.co:5432/postgres',
      ...SUPABASE_AUTH_ENV,
      AJE_OTP_PEPPER: 'release-pepper-with-at-least-32-chars',
      AJE_ENABLE_DEBUG_OTP: 'false',
      AJE_ANDROID_API_BASE_URL: 'https://api.ajefarms.co.tz',
      AJE_WHATSAPP_EXPERT_PHONE: '255700000000',
      AJE_PUSH_PROVIDER: 'development',
    },
    (relativePath) => relativePath === 'aje_farms_mobile/android/key.properties',
  );

  assert.equal(result.ok, true);
  assert.equal(result.blockers.length, 0);
});

test('release preflight blocks Supabase video signing without storage credentials', () => {
  const result = releasePreflight(
    {
      NODE_ENV: 'production',
      APP_URL: 'https://api.ajefarms.co.tz',
      AJE_STORE: 'supabase',
      SUPABASE_DATABASE_URL:
        'postgresql://postgres.example:pass@db.example.supabase.co:5432/postgres',
      AJE_OTP_PEPPER: 'release-pepper-with-at-least-32-chars',
      AJE_ENABLE_DEBUG_OTP: 'false',
      AJE_ANDROID_API_BASE_URL: 'https://api.ajefarms.co.tz',
      AJE_WHATSAPP_EXPERT_PHONE: '255700000000',
      AJE_PUSH_PROVIDER: 'development',
    },
    (relativePath) =>
      relativePath === 'aje_farms_mobile/android/key.properties',
  );

  assert.equal(result.ok, false);
  assert.ok(
    result.blockers.includes('SUPABASE_URL is required for release.'),
  );
  assert.ok(
    result.blockers.includes(
      'SUPABASE_SERVICE_ROLE_KEY is required for release.',
    ),
  );
});

test('release preflight requires Supabase Auth config even for the postgres store mode', () => {
  const result = releasePreflight(
    {
      NODE_ENV: 'production',
      APP_URL: 'https://api.ajefarms.co.tz',
      AJE_STORE: 'postgres',
      DATABASE_URL: 'postgresql://user:pass@example.com:5432/aje',
      AJE_OTP_PEPPER: 'release-pepper-with-at-least-32-chars',
      AJE_ENABLE_DEBUG_OTP: 'false',
      AJE_ANDROID_API_BASE_URL: 'https://api.ajefarms.co.tz',
      AJE_WHATSAPP_EXPERT_PHONE: '255700000000',
      AJE_PUSH_PROVIDER: 'development',
    },
    (relativePath) => relativePath === 'aje_farms_mobile/android/key.properties',
  );

  assert.equal(result.ok, false);
  assert.ok(
    result.blockers.includes('SUPABASE_URL is required for release.'),
  );
  assert.ok(
    result.blockers.includes(
      'SUPABASE_SERVICE_ROLE_KEY is required for release.',
    ),
  );
});

test('release preflight passes core config and keeps deferred provider warnings', () => {
  const result = releasePreflight(
    {
      NODE_ENV: 'production',
      APP_URL: 'https://api.ajefarms.co.tz',
      AJE_STORE: 'postgres',
      DATABASE_URL: 'postgresql://user:pass@example.com:5432/aje',
      ...SUPABASE_AUTH_ENV,
      AJE_OTP_PEPPER: 'release-pepper-with-at-least-32-chars',
      AJE_ENABLE_DEBUG_OTP: 'false',
      AJE_ANDROID_API_BASE_URL: 'https://api.ajefarms.co.tz',
      AJE_WHATSAPP_EXPERT_PHONE: '255700000000',
      AJE_PUSH_PROVIDER: 'development',
    },
    (relativePath) => relativePath === 'aje_farms_mobile/android/key.properties',
  );

  assert.equal(result.ok, true);
  assert.equal(result.blockers.length, 0);
  assert.ok(result.warnings.some((warning) => warning.includes('AJE_ADMIN_EMAILS')));
  assert.ok(result.warnings.some((warning) => warning.includes('Push notifications')));
});

test('release preflight blocks internal Android release builds', () => {
  const result = releasePreflight(
    {
      NODE_ENV: 'production',
      APP_URL: 'https://api.ajefarms.co.tz',
      AJE_STORE: 'postgres',
      DATABASE_URL: 'postgresql://user:pass@example.com:5432/aje',
      ...SUPABASE_AUTH_ENV,
      AJE_OTP_PEPPER: 'release-pepper-with-at-least-32-chars',
      AJE_ENABLE_DEBUG_OTP: 'false',
      AJE_INTERNAL_BUILD: 'true',
      AJE_ANDROID_API_BASE_URL: 'https://api.ajefarms.co.tz',
      AJE_WHATSAPP_EXPERT_PHONE: '255700000000',
      AJE_PUSH_PROVIDER: 'development',
    },
    (relativePath) =>
      relativePath === 'aje_farms_mobile/android/key.properties',
  );

  assert.equal(result.ok, false);
  assert.ok(
    result.blockers.includes(
      'AJE_INTERNAL_BUILD must not be true for release.',
    ),
  );
});

test('release preflight blocks debug OTP disclosure', () => {
  const result = releasePreflight(
    {
      NODE_ENV: 'production',
      APP_URL: 'https://api.ajefarms.co.tz',
      AJE_STORE: 'postgres',
      DATABASE_URL: 'postgresql://user:pass@example.com:5432/aje',
      ...SUPABASE_AUTH_ENV,
      AJE_OTP_PEPPER: 'release-pepper-with-at-least-32-chars',
      AJE_ENABLE_DEBUG_OTP: 'true',
      AJE_ANDROID_API_BASE_URL: 'https://api.ajefarms.co.tz',
      AJE_WHATSAPP_EXPERT_PHONE: '255700000000',
      AJE_PUSH_PROVIDER: 'development',
    },
    (relativePath) =>
      relativePath === 'aje_farms_mobile/android/key.properties',
  );

  assert.equal(result.ok, false);
  assert.ok(
    result.blockers.includes(
      'AJE_ENABLE_DEBUG_OTP must not be true for release.',
    ),
  );
});

test('release preflight warns when no admin email allowlist is configured', () => {
  const result = releasePreflight(
    {
      NODE_ENV: 'production',
      APP_URL: 'https://api.ajefarms.co.tz',
      AJE_STORE: 'postgres',
      DATABASE_URL: 'postgresql://user:pass@example.com:5432/aje',
      ...SUPABASE_AUTH_ENV,
      AJE_OTP_PEPPER: 'release-pepper-with-at-least-32-chars',
      AJE_ENABLE_DEBUG_OTP: 'false',
      AJE_ANDROID_API_BASE_URL: 'https://api.ajefarms.co.tz',
      AJE_WHATSAPP_EXPERT_PHONE: '255700000000',
      AJE_PUSH_PROVIDER: 'development',
    },
    (relativePath) =>
      relativePath === 'aje_farms_mobile/android/key.properties',
  );

  assert.equal(result.ok, true);
  assert.ok(
    result.warnings.some((warning) => warning.includes('AJE_ADMIN_EMAILS')),
  );
});

test('release preflight accepts configured FCM push provider', () => {
  const result = releasePreflight(
    {
      NODE_ENV: 'production',
      APP_URL: 'https://api.ajefarms.co.tz',
      AJE_STORE: 'postgres',
      DATABASE_URL: 'postgresql://user:pass@example.com:5432/aje',
      ...SUPABASE_AUTH_ENV,
      AJE_OTP_PEPPER: 'release-pepper-with-at-least-32-chars',
      AJE_ENABLE_DEBUG_OTP: 'false',
      AJE_ANDROID_API_BASE_URL: 'https://api.ajefarms.co.tz',
      AJE_WHATSAPP_EXPERT_PHONE: '255700000000',
      AJE_PUSH_PROVIDER: 'fcm',
      FCM_PROJECT_ID: 'aje-farms',
      FCM_CLIENT_EMAIL: 'firebase-adminsdk@example.iam.gserviceaccount.com',
      FCM_PRIVATE_KEY: '-----BEGIN PRIVATE KEY-----\\nkey\\n-----END PRIVATE KEY-----',
    },
    (relativePath) => relativePath === 'aje_farms_mobile/android/key.properties',
  );

  assert.equal(result.ok, true);
  assert.equal(result.blockers.length, 0);
  assert.ok(!result.warnings.some((warning) => warning.includes('Push notifications')));
});

test('release preflight blocks incomplete FCM push provider config', () => {
  const result = releasePreflight(
    {
      NODE_ENV: 'production',
      APP_URL: 'https://api.ajefarms.co.tz',
      AJE_STORE: 'postgres',
      DATABASE_URL: 'postgresql://user:pass@example.com:5432/aje',
      ...SUPABASE_AUTH_ENV,
      AJE_OTP_PEPPER: 'release-pepper-with-at-least-32-chars',
      AJE_ENABLE_DEBUG_OTP: 'false',
      AJE_ANDROID_API_BASE_URL: 'https://api.ajefarms.co.tz',
      AJE_WHATSAPP_EXPERT_PHONE: '255700000000',
      AJE_PUSH_PROVIDER: 'fcm',
      FCM_PROJECT_ID: 'aje-farms',
    },
    (relativePath) => relativePath === 'aje_farms_mobile/android/key.properties',
  );

  assert.equal(result.ok, false);
  assert.ok(
    result.blockers.includes(
      'FCM push provider requires FCM_SERVICE_ACCOUNT_JSON or FCM_PROJECT_ID, FCM_CLIENT_EMAIL, and FCM_PRIVATE_KEY.',
    ),
  );
});

test('release preflight blocks malformed FCM service account json', () => {
  const result = releasePreflight(
    {
      NODE_ENV: 'production',
      APP_URL: 'https://api.ajefarms.co.tz',
      AJE_STORE: 'postgres',
      DATABASE_URL: 'postgresql://user:pass@example.com:5432/aje',
      ...SUPABASE_AUTH_ENV,
      AJE_OTP_PEPPER: 'release-pepper-with-at-least-32-chars',
      AJE_ENABLE_DEBUG_OTP: 'false',
      AJE_ANDROID_API_BASE_URL: 'https://api.ajefarms.co.tz',
      AJE_WHATSAPP_EXPERT_PHONE: '255700000000',
      AJE_PUSH_PROVIDER: 'fcm',
      FCM_SERVICE_ACCOUNT_JSON: 'not-json',
    },
    (relativePath) => relativePath === 'aje_farms_mobile/android/key.properties',
  );

  assert.equal(result.ok, false);
  assert.ok(
    result.blockers.includes(
      'FCM push provider requires FCM_SERVICE_ACCOUNT_JSON or FCM_PROJECT_ID, FCM_CLIENT_EMAIL, and FCM_PRIVATE_KEY.',
    ),
  );
});

test('release preflight blocks weak release secrets and insecure urls', () => {
  const result = releasePreflight(
    {
      NODE_ENV: 'production',
      APP_URL: 'http://api.ajefarms.co.tz',
      AJE_STORE: 'postgres',
      DATABASE_URL: 'postgresql://user:pass@example.com:5432/aje',
      AJE_OTP_PEPPER: 'short',
      AJE_ENABLE_DEBUG_OTP: 'false',
      AJE_ANDROID_API_BASE_URL: 'http://api.ajefarms.co.tz',
      AJE_WHATSAPP_EXPERT_PHONE: '+255700000000',
    },
    (relativePath) => relativePath === 'aje_farms_mobile/android/key.properties',
  );

  assert.equal(result.ok, false);
  assert.ok(result.blockers.includes('APP_URL must use HTTPS for release.'));
  assert.ok(
    result.blockers.includes(
      'AJE_OTP_PEPPER must be at least 32 characters for release.',
    ),
  );
  assert.ok(
    result.blockers.includes(
      'AJE_ANDROID_API_BASE_URL must be an HTTPS production API URL.',
    ),
  );
  assert.ok(
    result.blockers.includes(
      'AJE_WHATSAPP_EXPERT_PHONE must be digits only.',
    ),
  );
});

test('release preflight rejects placeholder production hosts', () => {
  const result = releasePreflight(
    {
      NODE_ENV: 'production',
      APP_URL: 'https://api.example.com',
      AJE_STORE: 'supabase',
      SUPABASE_DATABASE_URL:
        'postgresql://postgres.example:pass@db.example.supabase.co:5432/postgres',
      AJE_OTP_PEPPER: 'release-pepper-with-at-least-32-chars',
      AJE_ENABLE_DEBUG_OTP: 'false',
      AJE_ANDROID_API_BASE_URL: 'https://api.example.com',
      AJE_WHATSAPP_EXPERT_PHONE: '255700000000',
      AJE_PUSH_PROVIDER: 'development',
    },
    (relativePath) =>
      relativePath === 'aje_farms_mobile/android/key.properties',
  );

  assert.equal(result.ok, false);
  assert.ok(
    result.blockers.includes(
      'APP_URL must not use a placeholder or reserved hostname.',
    ),
  );
  assert.ok(
    result.blockers.includes(
      'AJE_ANDROID_API_BASE_URL must not use a placeholder or reserved hostname.',
    ),
  );
});
