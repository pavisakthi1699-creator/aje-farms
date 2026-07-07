import assert from 'node:assert/strict';
import test from 'node:test';

import { releasePreflight } from '../preflight.js';

test('release preflight reports missing production blockers', () => {
  const result = releasePreflight({}, () => false);

  assert.equal(result.ok, false);
  assert.ok(result.blockers.includes('NODE_ENV is required for release.'));
  assert.ok(result.blockers.includes('AJE_STORE must be "postgres" for release.'));
  assert.ok(
    result.blockers.includes(
      'aje_farms_mobile/android/key.properties is required to sign release builds.',
    ),
  );
});

test('release preflight passes core config and keeps deferred provider warnings', () => {
  const result = releasePreflight(
    {
      NODE_ENV: 'production',
      APP_URL: 'https://api.ajefarms.example',
      AJE_STORE: 'postgres',
      DATABASE_URL: 'postgresql://user:pass@example.com:5432/aje',
      AJE_OTP_PEPPER: 'release-pepper-with-at-least-32-chars',
      AJE_ENABLE_DEBUG_OTP: 'false',
      AJE_ANDROID_API_BASE_URL: 'https://api.ajefarms.example',
      AJE_WHATSAPP_EXPERT_PHONE: '255700000000',
      AJE_PUSH_PROVIDER: 'development',
    },
    (relativePath) => relativePath === 'aje_farms_mobile/android/key.properties',
  );

  assert.equal(result.ok, true);
  assert.equal(result.blockers.length, 0);
  assert.ok(result.warnings.some((warning) => warning.includes('SMS OTP')));
  assert.ok(result.warnings.some((warning) => warning.includes('Payment provider')));
  assert.ok(result.warnings.some((warning) => warning.includes('Push notifications')));
});

test('release preflight blocks weak release secrets and insecure urls', () => {
  const result = releasePreflight(
    {
      NODE_ENV: 'production',
      APP_URL: 'http://api.ajefarms.example',
      AJE_STORE: 'postgres',
      DATABASE_URL: 'postgresql://user:pass@example.com:5432/aje',
      AJE_OTP_PEPPER: 'short',
      AJE_ENABLE_DEBUG_OTP: 'false',
      AJE_ANDROID_API_BASE_URL: 'http://api.ajefarms.example',
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
