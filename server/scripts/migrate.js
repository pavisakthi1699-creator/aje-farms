import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import pg from 'pg';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

async function main() {
  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) {
    throw new Error('DATABASE_URL is required to run migrations.');
  }

  const schemaPath = path.join(__dirname, '..', 'store', 'schema.sql');
  const sql = fs.readFileSync(schemaPath, 'utf8');
  const pool = new pg.Pool({ connectionString: databaseUrl });
  try {
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
