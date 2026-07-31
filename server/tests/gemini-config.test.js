import assert from 'node:assert/strict';
import test from 'node:test';

import { configuredGeminiApiKey, hasConfiguredGeminiApiKey } from '../gemini-config.js';

test('GEMINI_API is the canonical setting even when the legacy key is also present', () => {
  const env = {
    GEMINI_API: 'railway-gemini-key',
    GEMINI_API_KEY: 'stale-legacy-key',
  };

  assert.equal(configuredGeminiApiKey(env), 'railway-gemini-key');
  assert.equal(hasConfiguredGeminiApiKey(env), true);
});

test('blank variables are ignored and GEMINI_API_KEY remains a compatibility fallback', () => {
  assert.equal(
    configuredGeminiApiKey({ GEMINI_API: '   ', GEMINI_API_KEY: 'legacy-key' }),
    'legacy-key',
  );
  assert.equal(configuredGeminiApiKey({ GEMINI_API: '  ', GEMINI_API_KEY: '\n' }), null);
  assert.equal(hasConfiguredGeminiApiKey({ GEMINI_API: '\t' }), false);
});
