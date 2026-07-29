import assert from 'node:assert/strict';
import test from 'node:test';

import { communityDisplayName } from '../store/utils.js';

test('community display name prefers a stored display name', () => {
  assert.equal(
    communityDisplayName({ displayName: 'Juma M.' }, 'user-1'),
    'Juma M.',
  );
});

test('community display name falls back to a pseudonymous handle', () => {
  const handle = communityDisplayName(null, 'user-1');

  assert.match(handle, /^Mkulima [0-9a-f]{4}$/);
  assert.equal(handle.includes('user-1'), false);
});

test('community display name is stable for the same user id', () => {
  const canonical = communityDisplayName(null, 'user-1');

  assert.equal(communityDisplayName(undefined, 'user-1'), canonical);
  assert.equal(communityDisplayName({}, 'user-1'), canonical);
});

test('community display name differs between users', () => {
  assert.notEqual(
    communityDisplayName(null, 'user-1'),
    communityDisplayName(null, 'user-2'),
  );
});

test('community display name ignores a blank stored display name', () => {
  assert.equal(
    communityDisplayName({ displayName: '   ' }, 'user-1'),
    communityDisplayName(null, 'user-1'),
  );
});
