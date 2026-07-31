import 'dotenv/config';

import { randomBytes, randomUUID } from 'node:crypto';
import { spawn } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

import { createClient } from '@supabase/supabase-js';
import pg from 'pg';

const root = path.resolve(import.meta.dirname, '../..');
const mobileRoot = path.join(root, 'aje_farms_mobile');
const flutterBin = process.env.FLUTTER_BIN ?? 'flutter';
const device = process.env.AJE_E2E_DEVICE ?? 'emulator-5554';
const port = Number(process.env.AJE_E2E_BACKEND_PORT ?? 3100);
const apiBaseUrl = `http://10.0.2.2:${port}`;
const supabaseUrl = required('SUPABASE_URL');
const serviceRoleKey = required('SUPABASE_SERVICE_ROLE_KEY');
const databaseUrl =
  process.env.SUPABASE_DATABASE_URL ?? required('DATABASE_URL');
const publishableKey =
  process.env.SUPABASE_PUBLISHABLE_KEY ?? readMobilePublishableKey();
const suffix = `${Date.now()}-${randomUUID().slice(0, 8)}`;
const adminEmail = `aje-e2e-admin-${suffix}@example.com`;
const learnerEmail = `aje-e2e-learner-${suffix}@example.com`;
const password = `Aje!${randomBytes(18).toString('base64url')}9z`;
const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});
const pool = new pg.Pool({ connectionString: databaseUrl });
const createdAuthUserIds = [];
let backend;

try {
  createdAuthUserIds.push(
    await createConfirmedUser(adminEmail, password),
    await createConfirmedUser(learnerEmail, password),
  );
  backend = spawn(process.execPath, ['server/index.js'], {
    cwd: root,
    env: {
      ...process.env,
      PORT: String(port),
      NODE_ENV: 'production',
      AJE_ADMIN_EMAILS: adminEmail,
      AJE_ENABLE_DEBUG_OTP: 'false',
      AJE_ENABLE_LEGACY_DEV_PAYMENTS: 'false',
    },
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  backend.stdout.on('data', (chunk) => process.stdout.write(`[backend] ${chunk}`));
  backend.stderr.on('data', (chunk) => process.stderr.write(`[backend] ${chunk}`));
  await waitForHealthyBackend(`http://127.0.0.1:${port}/api/health/live`);
  await verifyAdminBoundary(adminEmail, password);

  const exitCode = await run(flutterBin, [
    'test',
    'integration_test/admin_and_standard_login_e2e_test.dart',
    '-d',
    device,
    `--dart-define=AJE_API_BASE_URL=${apiBaseUrl}`,
    `--dart-define=SUPABASE_URL=${supabaseUrl}`,
    `--dart-define=SUPABASE_PUBLISHABLE_KEY=${publishableKey}`,
    `--dart-define=AJE_E2E_STANDARD_EMAIL=${learnerEmail}`,
    `--dart-define=AJE_E2E_STANDARD_PASSWORD=${password}`,
    `--dart-define=AJE_E2E_ADMIN_EMAIL=${adminEmail}`,
    `--dart-define=AJE_E2E_ADMIN_PASSWORD=${password}`,
  ]);
  if (exitCode !== 0) process.exitCode = exitCode;
} finally {
  backend?.kill('SIGTERM');
  await cleanupApplicationUsers(createdAuthUserIds).catch((error) => {
    console.error('E2E database cleanup failed:', error.message);
    process.exitCode = 1;
  });
  for (const authUserId of createdAuthUserIds) {
    const { error } = await supabase.auth.admin.deleteUser(authUserId);
    if (error) {
      console.error('E2E Supabase Auth cleanup failed:', error.message);
      process.exitCode = 1;
    }
  }
  await pool.end();
}

async function createConfirmedUser(email, userPassword) {
  const { data, error } = await supabase.auth.admin.createUser({
    email,
    password: userPassword,
    email_confirm: true,
  });
  if (error || !data.user) {
    throw new Error(`Could not create E2E user: ${error?.message ?? 'unknown error'}`);
  }
  return data.user.id;
}

async function waitForHealthyBackend(url) {
  for (let attempt = 0; attempt < 40; attempt += 1) {
    if (backend?.exitCode != null) {
      throw new Error(`Backend exited before E2E test (code ${backend.exitCode}).`);
    }
    try {
      const response = await fetch(url);
      if (response.ok) return;
    } catch {
      // The server is still starting.
    }
    await new Promise((resolve) => setTimeout(resolve, 250));
  }
  throw new Error('Timed out waiting for the E2E backend.');
}

async function verifyAdminBoundary(email, userPassword) {
  const publicClient = createClient(supabaseUrl, publishableKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await publicClient.auth.signInWithPassword({
    email,
    password: userPassword,
  });
  if (error || !data.session) {
    throw new Error(`E2E admin sign-in failed: ${error?.message ?? 'no session'}`);
  }
  const response = await fetch(`http://127.0.0.1:${port}/api/auth/whoami`, {
    headers: { Authorization: `Bearer ${data.session.access_token}` },
  });
  const payload = await response.json();
  if (!response.ok || payload.role !== 'admin' || payload.hasAdminAccess !== true) {
    throw new Error(
      `E2E admin boundary failed: HTTP ${response.status}, role=${payload.role}.`,
    );
  }
}

function run(command, args) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      cwd: mobileRoot,
      env: process.env,
      stdio: 'inherit',
    });
    child.once('error', reject);
    child.once('exit', (code) => resolve(code ?? 1));
  });
}

async function cleanupApplicationUsers(authUserIds) {
  if (authUserIds.length === 0) return;
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const users = await client.query(
      'SELECT id FROM users WHERE auth_user_id = ANY($1::text[])',
      [authUserIds],
    );
    const userIds = users.rows.map((row) => row.id);
    if (userIds.length === 0) {
      await client.query('COMMIT');
      return;
    }
    const payments = await client.query(
      `SELECT id FROM payment_records
       WHERE user_id = ANY($1::text[])
          OR recorded_by = ANY($1::text[])
          OR approved_by = ANY($1::text[])
          OR reversed_by = ANY($1::text[])`,
      [userIds],
    );
    const paymentIds = payments.rows.map((row) => row.id);
    await client.query(
      `DELETE FROM audit_events
       WHERE actor_user_id = ANY($1::text[])
          OR target_id = ANY($2::text[])`,
      [userIds, paymentIds],
    );
    await client.query(
      'DELETE FROM entitlements WHERE user_id = ANY($1::text[])',
      [userIds],
    );
    await client.query(
      `DELETE FROM payment_records
       WHERE user_id = ANY($1::text[])
          OR recorded_by = ANY($1::text[])
          OR approved_by = ANY($1::text[])
          OR reversed_by = ANY($1::text[])`,
      [userIds],
    );
    await client.query('DELETE FROM users WHERE id = ANY($1::text[])', [userIds]);
    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

function readMobilePublishableKey() {
  const source = fs.readFileSync(path.join(mobileRoot, 'lib/main.dart'), 'utf8');
  const match = source.match(
    /SUPABASE_PUBLISHABLE_KEY[\s\S]*?defaultValue:\s*'([^']+)'/,
  );
  if (!match) throw new Error('SUPABASE_PUBLISHABLE_KEY is required.');
  return match[1];
}

function required(name) {
  const value = String(process.env[name] ?? '').trim();
  if (!value) throw new Error(`${name} is required.`);
  return value;
}
