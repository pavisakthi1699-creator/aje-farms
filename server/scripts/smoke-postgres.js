import { spawnSync } from 'node:child_process';

const defaultDatabaseUrl = 'postgresql://aje:aje@localhost:5432/aje_farms';

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    stdio: 'inherit',
    env: { ...process.env, ...options.env },
  });
  if (result.error) {
    throw result.error;
  }
  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}

function hasCommand(command) {
  const result = spawnSync('which', [command], { stdio: 'ignore' });
  return result.status === 0;
}

const databaseUrl =
  process.env.SUPABASE_DATABASE_URL ?? process.env.DATABASE_URL ?? defaultDatabaseUrl;

if (!process.env.SUPABASE_DATABASE_URL && !process.env.DATABASE_URL) {
  if (!hasCommand('docker')) {
    console.error(
      [
        'Postgres smoke needs DATABASE_URL or Docker.',
        '',
        'Options:',
        '  1. Install Docker Desktop/Colima and rerun npm run smoke:postgres.',
        '  2. Set DATABASE_URL to a reachable Postgres database and rerun.',
        '',
        `Default local URL when Docker is available: ${defaultDatabaseUrl}`,
      ].join('\n'),
    );
    process.exit(1);
  }
  run('docker', ['compose', 'up', '-d', 'postgres']);
}

const env = {
  DATABASE_URL: databaseUrl,
  AJE_STORE: process.env.AJE_STORE ?? 'postgres',
  ...(process.env.SUPABASE_DATABASE_URL
    ? { SUPABASE_DATABASE_URL: process.env.SUPABASE_DATABASE_URL }
    : {}),
  ...(process.env.AJE_DB_SCHEMA ? { AJE_DB_SCHEMA: process.env.AJE_DB_SCHEMA } : {}),
};

run('node', ['server/scripts/wait-for-postgres.js'], { env });
run('node', ['server/scripts/migrate.js'], { env });
run('node', ['--test', 'server/tests/store-api-postgres.test.js'], { env });
