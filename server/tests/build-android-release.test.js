import assert from 'node:assert/strict';
import test from 'node:test';

import {
  internalTestingDartDefines,
  PRODUCTION_API_BASE_URL,
  releaseDartDefines,
} from '../android-release.js';

test('release dart defines never forward the internal-build flag', () => {
  const defines = releaseDartDefines({
    AJE_ANDROID_API_BASE_URL: 'https://api.ajefarms.co.tz',
    AJE_WHATSAPP_EXPERT_PHONE: '255700000000',
    AJE_INTERNAL_BUILD: 'true',
  });

  assert.deepEqual(defines, [
    '--dart-define=AJE_API_BASE_URL=https://api.ajefarms.co.tz',
    '--dart-define=AJE_WHATSAPP_EXPERT_PHONE=255700000000',
  ]);
  assert.ok(!defines.some((define) => define.includes('AJE_INTERNAL_BUILD')));
});

test('internal APK keeps the production API and only enables test diagnostics', () => {
  const env = {
    AJE_ANDROID_API_BASE_URL: PRODUCTION_API_BASE_URL,
    AJE_WHATSAPP_EXPERT_PHONE: '255743812853',
  };

  const productionDefines = releaseDartDefines(env);
  const internalDefines = internalTestingDartDefines(env);

  assert.deepEqual(internalDefines.slice(0, 2), productionDefines);
  assert.deepEqual(internalDefines.slice(2), [
    '--dart-define=AJE_INTERNAL_BUILD=true',
  ]);
});

test('internal APK build rejects a staging API URL', () => {
  assert.throws(
    () =>
      internalTestingDartDefines({
        AJE_ANDROID_API_BASE_URL:
          'https://aje-farms-api-staging-production.up.railway.app',
        AJE_WHATSAPP_EXPERT_PHONE: '255743812853',
      }),
    /must use the production API/,
  );
});
