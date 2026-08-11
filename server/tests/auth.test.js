import assert from 'node:assert/strict';
import test from 'node:test';

import { authVerificationFailureStatus } from '../auth.js';

test('auth verification rejects an explicitly invalid token', () => {
  assert.equal(authVerificationFailureStatus({ status: 401 }), 401);
  assert.equal(authVerificationFailureStatus({ statusCode: 403 }), 401);
});

test('auth verification treats provider failures as temporary outages', () => {
  assert.equal(authVerificationFailureStatus({ status: 429 }), 503);
  assert.equal(authVerificationFailureStatus({ status: 500 }), 503);
  assert.equal(authVerificationFailureStatus(new Error('network down')), 503);
});
