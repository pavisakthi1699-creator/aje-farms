import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

test('Supabase migration versions are unique', () => {
  const testDir = path.dirname(fileURLToPath(import.meta.url));
  const migrationDir = path.resolve(testDir, '../../supabase/migrations');
  const migrations = fs
    .readdirSync(migrationDir)
    .filter((name) => name.endsWith('.sql'));
  const byVersion = new Map();

  for (const migration of migrations) {
    const version = migration.split('_', 1)[0];
    const matches = byVersion.get(version) ?? [];
    matches.push(migration);
    byVersion.set(version, matches);
  }

  const duplicates = [...byVersion.values()].filter(
    (matches) => matches.length > 1,
  );
  assert.deepEqual(
    duplicates,
    [],
    `Duplicate Supabase migration versions: ${JSON.stringify(duplicates)}`,
  );
});
