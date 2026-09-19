-- TEXT rather than UUID: Supabase Auth user ids are UUIDs in production, but
-- the NODE_ENV=development dev-session issuer (see api.js) mints a readable
-- `dev-<email>` id instead of fabricating a fake UUID, matching every other
-- id column in this schema.
ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_user_id TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS account_status TEXT NOT NULL
  DEFAULT 'pending_activation';

ALTER TABLE users ALTER COLUMN phone_number DROP NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_auth_user_id
  ON users (auth_user_id) WHERE auth_user_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_lower
  ON users (lower(email)) WHERE email IS NOT NULL;

ALTER TABLE users DROP CONSTRAINT IF EXISTS users_account_status_check;
ALTER TABLE users ADD CONSTRAINT users_account_status_check
  CHECK (account_status IN ('pending_activation', 'active', 'suspended'));

ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE users ADD CONSTRAINT users_role_check
  CHECK (role IN ('learner', 'support_agent', 'finance_reviewer', 'admin'));

DO $$
DECLARE
  target_table TEXT;
BEGIN
  FOREACH target_table IN ARRAY ARRAY[
    'learning_progress',
    'notification_settings',
    'notification_devices',
    'notifications',
    'payment_transactions',
    'auth_sessions'
  ]
  LOOP
    IF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = current_schema()
        AND table_name = target_table
        AND column_name = 'phone_number'
    ) THEN
      EXECUTE format(
        'ALTER TABLE %I RENAME COLUMN phone_number TO user_id', target_table);
    END IF;

    EXECUTE format(
      'UPDATE %I t SET user_id = u.id FROM users u
        WHERE t.user_id = u.phone_number', target_table);
  END LOOP;
END $$;

ALTER TABLE community_posts ADD COLUMN IF NOT EXISTS author_user_id TEXT;
ALTER TABLE community_replies ADD COLUMN IF NOT EXISTS author_user_id TEXT;

UPDATE community_posts p SET author_user_id = u.id
  FROM users u WHERE p.author_user_id IS NULL AND p.author_phone = u.phone_number;

UPDATE community_replies r SET author_user_id = u.id
  FROM users u WHERE r.author_user_id IS NULL AND r.author_phone = u.phone_number;

UPDATE community_posts p SET moderated_by = u.id
  FROM users u WHERE p.moderated_by = u.phone_number;

CREATE INDEX IF NOT EXISTS idx_community_posts_author_user_id
  ON community_posts (author_user_id);
;
