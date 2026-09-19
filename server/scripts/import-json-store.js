import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import pg from 'pg';

import { importJsonStoreToPostgres } from '../store/postgres-store.js';
import { jsonDataFilePath } from '../store/json-store.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

async function main() {
  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) {
    throw new Error('DATABASE_URL is required to import JSON store data.');
  }

  const sourcePath = process.argv[2] ?? jsonDataFilePath();
  if (!fs.existsSync(sourcePath)) {
    throw new Error(`JSON store file not found: ${sourcePath}`);
  }

  const rawState = JSON.parse(fs.readFileSync(sourcePath, 'utf8'));
  const pool = new pg.Pool({ connectionString: databaseUrl });
  try {
    await importJsonStoreToPostgres(pool, rawState);
    console.log(
      `Imported ${rawState.users?.length ?? 0} users and ${rawState.paymentTransactions?.length ?? 0} payment transactions from ${sourcePath}.`,
    );
  } finally {
    await pool.end();
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
