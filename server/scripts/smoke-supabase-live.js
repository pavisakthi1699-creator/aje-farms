import pg from 'pg';

const requiredTables = [
  'auth_sessions',
  'community_posts',
  'community_replies',
  'content_courses',
  'content_documents',
  'learning_progress',
  'notification_devices',
  'notification_settings',
  'notifications',
  'otp_challenges',
  'payment_transactions',
  'reported_community_posts',
  'users',
];

const databaseUrl = process.env.SUPABASE_DATABASE_URL ?? process.env.DATABASE_URL;
const schema = process.env.AJE_DB_SCHEMA ?? 'public';

if (!databaseUrl) {
  console.error('SUPABASE_DATABASE_URL or DATABASE_URL is required.');
  process.exit(1);
}

if (!/^[a-z_][a-z0-9_]*$/.test(schema)) {
  console.error('AJE_DB_SCHEMA must be a valid PostgreSQL identifier.');
  process.exit(1);
}

const pool = new pg.Pool({
  connectionString: databaseUrl,
  options: `-c search_path=${schema},public`,
});

try {
  await pool.query('SELECT 1');

  const tables = await pool.query(
    `SELECT c.relname AS table_name,
            c.relrowsecurity AS rls_enabled,
            COUNT(p.polname)::int AS policy_count
     FROM pg_class c
     JOIN pg_namespace n ON n.oid = c.relnamespace
     LEFT JOIN pg_policy p ON p.polrelid = c.oid
     WHERE n.nspname = $1
       AND c.relkind = 'r'
       AND c.relname = ANY($2)
     GROUP BY c.relname, c.relrowsecurity
     ORDER BY c.relname`,
    [schema, requiredTables],
  );

  const tableMap = new Map(tables.rows.map((row) => [row.table_name, row]));
  const missing = requiredTables.filter((table) => !tableMap.has(table));
  if (missing.length > 0) {
    throw new Error(`Missing required tables: ${missing.join(', ')}`);
  }

  const withoutRls = tables.rows
    .filter((row) => !row.rls_enabled)
    .map((row) => row.table_name);
  if (withoutRls.length > 0) {
    throw new Error(`RLS is disabled on: ${withoutRls.join(', ')}`);
  }

  const withoutPolicies = tables.rows
    .filter((row) => row.policy_count < 1)
    .map((row) => row.table_name);
  if (withoutPolicies.length > 0) {
    throw new Error(`No RLS policy found on: ${withoutPolicies.join(', ')}`);
  }

  const rowCounts = await pool.query(
    requiredTables
      .map(
        (table, index) =>
          `SELECT '${table}' AS table_name, COUNT(*)::int AS row_count FROM ${schema}.${table}`,
      )
      .join(' UNION ALL '),
  );

  console.log('Supabase live smoke passed.');
  console.log(`Schema: ${schema}`);
  for (const row of rowCounts.rows.sort((left, right) =>
    left.table_name.localeCompare(right.table_name),
  )) {
    console.log(`${row.table_name}: ${row.row_count}`);
  }
} catch (error) {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
} finally {
  await pool.end();
}
