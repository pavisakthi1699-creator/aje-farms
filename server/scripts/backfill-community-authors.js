import 'dotenv/config';

import pg from 'pg';

import { communityDisplayName } from '../store/utils.js';

// Moves phone numbers out of the public `author` label and into the private
// `author_phone` column. Idempotent: rows whose author no longer looks like a
// phone number are skipped, so a second run migrates nothing.
//
//   node server/scripts/backfill-community-authors.js            # dry run
//   node server/scripts/backfill-community-authors.js --apply

const apply = process.argv.includes('--apply');

async function backfillTable(client, table, usersByPhone) {
  const result = await client.query(
    `SELECT id, author FROM ${table} WHERE author LIKE '+%'`,
  );

  const migrations = result.rows.map((row) => ({
    id: row.id,
    authorPhone: row.author,
    author: communityDisplayName(usersByPhone.get(row.author), row.author),
  }));

  if (apply) {
    for (const migration of migrations) {
      await client.query(
        `UPDATE ${table}
         SET author = $2,
             author_phone = COALESCE(author_phone, $3)
         WHERE id = $1`,
        [migration.id, migration.author, migration.authorPhone],
      );
    }
  }

  return migrations;
}

async function main() {
  const databaseUrl =
    process.env.SUPABASE_DATABASE_URL ?? process.env.DATABASE_URL;
  if (!databaseUrl) {
    throw new Error(
      'SUPABASE_DATABASE_URL or DATABASE_URL is required to backfill authors.',
    );
  }

  const schema = process.env.AJE_DB_SCHEMA;
  const pool = new pg.Pool({
    connectionString: databaseUrl,
    ...(schema ? { options: `-c search_path=${schema},public` } : {}),
  });
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const users = await client.query(
      `SELECT phone_number, display_name FROM users`,
    );
    const usersByPhone = new Map(
      users.rows.map((row) => [
        row.phone_number,
        { displayName: row.display_name },
      ]),
    );

    const posts = await backfillTable(client, 'community_posts', usersByPhone);
    const replies = await backfillTable(
      client,
      'community_replies',
      usersByPhone,
    );

    if (apply) {
      await client.query('COMMIT');
    } else {
      await client.query('ROLLBACK');
    }

    for (const migration of [...posts, ...replies]) {
      console.log(`  ${migration.authorPhone} -> ${migration.author}`);
    }
    console.log(
      `${apply ? 'Migrated' : 'Would migrate'} ${posts.length} post(s) and ` +
        `${replies.length} reply/replies.`,
    );
    if (!apply) {
      console.log('Dry run only. Re-run with --apply to persist.');
    }
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
