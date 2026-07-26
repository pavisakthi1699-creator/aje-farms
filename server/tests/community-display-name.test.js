import assert from 'node:assert/strict';
import test from 'node:test';

import { communityDisplayName } from '../store/utils.js';

test('community display name prefers a stored display name', () => {
  assert.equal(
    communityDisplayName({ displayName: 'Juma M.' }, '+255712345678'),
    'Juma M.',
  );
});

test('community display name falls back to a pseudonymous handle', () => {
  const handle = communityDisplayName(null, '+255712345678');

  assert.match(handle, /^Mkulima [0-9a-f]{4}$/);
  assert.equal(handle.includes('712345678'), false);
});

test('community display name is stable across phone number formats', () => {
  const canonical = communityDisplayName(null, '+255712345678');

  assert.equal(communityDisplayName(null, '0712345678'), canonical);
  assert.equal(communityDisplayName(undefined, '712345678'), canonical);
  assert.equal(communityDisplayName({}, '255712345678'), canonical);
});

test('community display name differs between users', () => {
  assert.notEqual(
    communityDisplayName(null, '+255712345678'),
    communityDisplayName(null, '+255712345679'),
  );
});

test('community display name ignores a blank stored display name', () => {
  assert.equal(
    communityDisplayName({ displayName: '   ' }, '+255712345678'),
    communityDisplayName(null, '+255712345678'),
  );
});
