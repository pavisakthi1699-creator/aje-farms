import pg from 'pg';

const databaseUrl =
  process.env.SUPABASE_DATABASE_URL ??
  process.env.DATABASE_URL ??
  'postgresql://aje:aje@localhost:5432/aje_farms';
const timeoutMs = Number(process.env.AJE_POSTGRES_WAIT_MS ?? 30000);
const startedAt = Date.now();

async function waitForPostgres() {
  while (Date.now() - startedAt < timeoutMs) {
    const pool = new pg.Pool({ connectionString: databaseUrl });
    try {
      await pool.query('SELECT 1');
      console.log('Postgres is ready.');
      return;
    } catch {
      await new Promise((resolve) => setTimeout(resolve, 1000));
    } finally {
      await pool.end();
    }
  }

  throw new Error(`Postgres was not ready within ${timeoutMs}ms.`);
}

waitForPostgres().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
