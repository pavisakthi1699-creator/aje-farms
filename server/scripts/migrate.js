import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import pg from 'pg';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

async function main() {
  const databaseUrl = process.env.SUPABASE_DATABASE_URL ?? process.env.DATABASE_URL;
  if (!databaseUrl) {
    throw new Error(
      'SUPABASE_DATABASE_URL or DATABASE_URL is required to run migrations.',
    );
  }

  const schema = process.env.AJE_DB_SCHEMA;
  const schemaPath = path.join(__dirname, '..', 'store', 'schema.sql');
  const sql = fs.readFileSync(schemaPath, 'utf8');
  const pool = new pg.Pool({
    connectionString: databaseUrl,
    ...(schema ? { options: `-c search_path=${schema},public` } : {}),
  });
  try {
    if (schema && schema !== 'public') {
      if (!/^[a-z_][a-z0-9_]*$/.test(schema)) {
        throw new Error('AJE_DB_SCHEMA must be a valid PostgreSQL identifier.');
      }
      await pool.query(`CREATE SCHEMA IF NOT EXISTS ${schema}`);
    }
    await pool.query(sql);
    console.log('AJE Farms database schema applied.');
  } finally {
    await pool.end();
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
