import assert from 'node:assert/strict';
import test from 'node:test';

import { releaseDartDefines } from '../android-release.js';

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
