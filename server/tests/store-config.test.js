import assert from 'node:assert/strict';
import test from 'node:test';

import { resolveStoreConfig } from '../store.js';

test('resolveStoreConfig supports dedicated Supabase database mode', () => {
  const config = resolveStoreConfig({
    AJE_STORE: 'supabase',
    SUPABASE_DATABASE_URL: 'postgresql://example.supabase.co/postgres',
  });

  assert.equal(config.mode, 'supabase');
  assert.equal(config.databaseUrl, 'postgresql://example.supabase.co/postgres');
  assert.equal(config.databaseUrlEnvName, 'SUPABASE_DATABASE_URL');
  assert.equal(config.schema, 'public');
});

test('resolveStoreConfig allows an explicit Supabase schema override', () => {
  const config = resolveStoreConfig({
    AJE_STORE: 'supabase',
    DATABASE_URL: 'postgresql://example.supabase.co/postgres',
    AJE_DB_SCHEMA: 'aje',
  });

  assert.equal(config.databaseUrl, 'postgresql://example.supabase.co/postgres');
  assert.equal(config.databaseUrlEnvName, 'DATABASE_URL');
  assert.equal(config.schema, 'aje');
});
