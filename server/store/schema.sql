CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  phone_number TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL DEFAULT 'learner',
  subscription_plan TEXT,
  subscription_started_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS otp_challenges (
  id TEXT PRIMARY KEY,
  phone_number TEXT NOT NULL,
  otp_hash TEXT NOT NULL,
  created_at BIGINT NOT NULL,
  expires_at BIGINT NOT NULL,
  delivery_provider TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_otp_challenges_phone
  ON otp_challenges (phone_number);

CREATE INDEX IF NOT EXISTS idx_otp_challenges_expires
  ON otp_challenges (expires_at);

CREATE TABLE IF NOT EXISTS payment_transactions (
  id TEXT PRIMARY KEY,
  plan_title TEXT NOT NULL,
  price TEXT NOT NULL,
  method TEXT NOT NULL,
  phone_number TEXT NOT NULL,
  status TEXT NOT NULL,
  message TEXT NOT NULL,
  receipt_number TEXT,
  provider TEXT NOT NULL,
  provider_reference TEXT NOT NULL,
  checkout_instructions TEXT NOT NULL,
  auto_confirm_at TIMESTAMPTZ,
  subscription_plan TEXT,
  subscription_started_at TIMESTAMPTZ
);

-- Guarded rather than a bare CREATE INDEX: once the identity migration below
-- renames phone_number to user_id, the literal column reference here would
-- fail to parse on every subsequent re-apply of this file. The index created
-- on a fresh table (while the column is still named phone_number) survives
-- the later rename automatically, so this only needs to run once.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = current_schema()
      AND table_name = 'payment_transactions' AND column_name = 'phone_number'
  ) THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_payment_transactions_phone
      ON payment_transactions (phone_number)';
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS auth_sessions (
  token TEXT PRIMARY KEY,
  phone_number TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL
);

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = current_schema()
      AND table_name = 'auth_sessions' AND column_name = 'phone_number'
  ) THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_auth_sessions_phone
      ON auth_sessions (phone_number)';
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_auth_sessions_expires
  ON auth_sessions (expires_at);

CREATE TABLE IF NOT EXISTS learning_progress (
  phone_number TEXT NOT NULL,
  course_id TEXT NOT NULL,
  lesson_id TEXT NOT NULL,
  completed_at TIMESTAMPTZ NOT NULL,
  PRIMARY KEY (phone_number, course_id, lesson_id)
);

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = current_schema()
      AND table_name = 'learning_progress' AND column_name = 'phone_number'
  ) THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_learning_progress_phone
      ON learning_progress (phone_number)';
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS notification_settings (
  phone_number TEXT PRIMARY KEY,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  community_replies BOOLEAN NOT NULL DEFAULT TRUE,
  moderation_updates BOOLEAN NOT NULL DEFAULT TRUE,
  learning_reminders BOOLEAN NOT NULL DEFAULT TRUE,
  updated_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS notification_devices (
  id TEXT PRIMARY KEY,
  phone_number TEXT NOT NULL,
  token TEXT NOT NULL UNIQUE,
  platform TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = current_schema()
      AND table_name = 'notification_devices' AND column_name = 'phone_number'
  ) THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_notification_devices_phone
      ON notification_devices (phone_number)';
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS notifications (
  id TEXT PRIMARY KEY,
  phone_number TEXT NOT NULL,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL
);

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = current_schema()
      AND table_name = 'notifications' AND column_name = 'phone_number'
  ) THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_notifications_phone_created
      ON notifications (phone_number, created_at DESC)';
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS content_courses (
  id TEXT PRIMARY KEY,
  status TEXT NOT NULL DEFAULT 'approved',
  payload JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_content_courses_status
  ON content_courses (status);

CREATE TABLE IF NOT EXISTS content_documents (
  id TEXT PRIMARY KEY,
  status TEXT NOT NULL DEFAULT 'approved',
  payload JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_content_documents_status
  ON content_documents (status);

CREATE TABLE IF NOT EXISTS community_posts (
  id TEXT PRIMARY KEY,
  author TEXT NOT NULL,
  location TEXT NOT NULL,
  time_label TEXT NOT NULL,
  content TEXT NOT NULL,
  likes INTEGER NOT NULL DEFAULT 0,
  comments INTEGER NOT NULL DEFAULT 0,
  tags JSONB NOT NULL DEFAULT '[]'::jsonb,
  related_topic TEXT,
  has_image BOOLEAN NOT NULL DEFAULT FALSE,
  is_expert BOOLEAN NOT NULL DEFAULT FALSE,
  is_urgent BOOLEAN NOT NULL DEFAULT FALSE,
  moderation_status TEXT NOT NULL DEFAULT 'visible',
  moderated_at TIMESTAMPTZ,
  moderated_by TEXT,
  created_at TIMESTAMPTZ NOT NULL
);

ALTER TABLE community_posts
  ADD COLUMN IF NOT EXISTS moderation_status TEXT NOT NULL DEFAULT 'visible';

ALTER TABLE community_posts
  ADD COLUMN IF NOT EXISTS moderated_at TIMESTAMPTZ;

ALTER TABLE community_posts
  ADD COLUMN IF NOT EXISTS moderated_by TEXT;

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS display_name TEXT;

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS preferred_location TEXT;

CREATE INDEX IF NOT EXISTS idx_community_posts_created
  ON community_posts (created_at DESC);

CREATE TABLE IF NOT EXISTS community_replies (
  id TEXT PRIMARY KEY,
  post_id TEXT NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  author TEXT NOT NULL,
  body TEXT NOT NULL,
  time_label TEXT NOT NULL,
  is_expert BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_community_replies_post
  ON community_replies (post_id);

CREATE TABLE IF NOT EXISTS reported_community_posts (
  post_id TEXT PRIMARY KEY REFERENCES community_posts(id) ON DELETE CASCADE,
  reported_at TIMESTAMPTZ NOT NULL
);

-- Private authorship key. `author` is a public display label served by the
-- unauthenticated community feed and must never hold a phone number.
ALTER TABLE community_posts
  ADD COLUMN IF NOT EXISTS author_phone TEXT;

ALTER TABLE community_replies
  ADD COLUMN IF NOT EXISTS author_phone TEXT;

CREATE INDEX IF NOT EXISTS idx_community_posts_author_phone
  ON community_posts (author_phone);

-- Storage object path in the public `community-post-images` bucket. The path
-- is a bare generated filename (no phone number or other identifier) since
-- the bucket is public and the path is embedded in the returned image URL.
ALTER TABLE community_posts
  ADD COLUMN IF NOT EXISTS image_path TEXT;

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE otp_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE auth_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE learning_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_replies ENABLE ROW LEVEL SECURITY;
ALTER TABLE reported_community_posts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_direct_client_access ON users;
CREATE POLICY deny_direct_client_access ON users
  FOR ALL TO public
  USING (false)
  WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON otp_challenges;
CREATE POLICY deny_direct_client_access ON otp_challenges
  FOR ALL TO public
  USING (false)
  WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON payment_transactions;
CREATE POLICY deny_direct_client_access ON payment_transactions
  FOR ALL TO public
  USING (false)
  WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON auth_sessions;
CREATE POLICY deny_direct_client_access ON auth_sessions
  FOR ALL TO public
  USING (false)
  WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON learning_progress;
CREATE POLICY deny_direct_client_access ON learning_progress
  FOR ALL TO public
  USING (false)
  WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON notification_settings;
CREATE POLICY deny_direct_client_access ON notification_settings
  FOR ALL TO public
  USING (false)
  WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON notification_devices;
CREATE POLICY deny_direct_client_access ON notification_devices
  FOR ALL TO public
  USING (false)
  WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON notifications;
CREATE POLICY deny_direct_client_access ON notifications
  FOR ALL TO public
  USING (false)
  WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON content_courses;
CREATE POLICY deny_direct_client_access ON content_courses
  FOR ALL TO public
  USING (false)
  WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON content_documents;
CREATE POLICY deny_direct_client_access ON content_documents
  FOR ALL TO public
  USING (false)
  WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON community_posts;
CREATE POLICY deny_direct_client_access ON community_posts
  FOR ALL TO public
  USING (false)
  WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON community_replies;
CREATE POLICY deny_direct_client_access ON community_replies
  FOR ALL TO public
  USING (false)
  WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON reported_community_posts;
CREATE POLICY deny_direct_client_access ON reported_community_posts
  FOR ALL TO public
  USING (false)
  WITH CHECK (false);

-- =========================================================================
-- Email/password identity (replaces phone + OTP).
--
-- Identity moves from `users.phone_number` to the pre-existing internal
-- `users.id` primary key. `auth_user_id` is only a unique link out to the
-- Supabase Auth user; nothing else joins on it, so accounts that predate
-- Supabase Auth keep their `id` and therefore keep every row that points at
-- them. Phone becomes optional contact information.
--
-- Every re-key below is a backfill joined on `users.phone_number`. Nothing
-- here truncates or deletes: this file is re-applied on every migrate, and
-- existing accounts (including admin content-editor accounts) must keep
-- their community posts, moderation history, and every other row intact.
-- =========================================================================

-- TEXT rather than UUID: Supabase Auth user ids are UUIDs in production, but
-- the NODE_ENV=development dev-session issuer (see api.js) mints a readable
-- `dev-<email>` id instead of fabricating a fake UUID, matching every other
-- id column in this schema.
ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_user_id TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS account_status TEXT NOT NULL
  DEFAULT 'pending_activation';

-- Phone is no longer how a learner signs in, so it must be droppable.
ALTER TABLE users ALTER COLUMN phone_number DROP NOT NULL;

-- Partial unique indexes: many rows may have no email/auth link yet, and
-- the email match must be case-insensitive.
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

-- Re-key per-user tables from phone_number to user_id. The rename is guarded
-- so re-running is a no-op; the backfill matches nothing once it has run.
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

-- Community authorship. `author` stays the public display label; only the
-- private key changes. `moderated_by` also held a moderator phone number.
ALTER TABLE community_posts ADD COLUMN IF NOT EXISTS author_user_id TEXT;
ALTER TABLE community_replies ADD COLUMN IF NOT EXISTS author_user_id TEXT;

UPDATE community_posts p SET author_user_id = u.id
  FROM users u WHERE p.author_user_id IS NULL AND p.author_phone = u.phone_number;

UPDATE community_replies r SET author_user_id = u.id
  FROM users u WHERE r.author_user_id IS NULL AND r.author_phone = u.phone_number;

-- Only rewrite moderator values that actually match a user, so non-phone
-- sentinels such as 'content-readiness-migration' are left intact.
UPDATE community_posts p SET moderated_by = u.id
  FROM users u WHERE p.moderated_by = u.phone_number;

CREATE INDEX IF NOT EXISTS idx_community_posts_author_user_id
  ON community_posts (author_user_id);

-- =========================================================================
-- Plan catalog, entitlements, payment records, audit trail.
--
-- Staff record a cash/bank-transfer payment against a real `plans.id`; they
-- cannot type an arbitrary price. Approving a payment_record is the only
-- thing that ever creates an entitlement, and it happens inside one
-- transaction (see PostgresStore#approvePaymentRecord) so an approval can
-- never leave a payment approved without a matching entitlement or vice
-- versa. Every state change — activation, reversal, role change — writes an
-- audit_events row that is never updated or deleted.
-- =========================================================================

CREATE TABLE IF NOT EXISTS plans (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  subtitle TEXT,
  price_tzs INTEGER NOT NULL CHECK (price_tzs >= 0),
  duration_days INTEGER NOT NULL CHECK (duration_days > 0),
  icon TEXT,
  recommended BOOLEAN NOT NULL DEFAULT FALSE,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO plans (id, title, subtitle, price_tzs, duration_days, icon, recommended, sort_order)
VALUES
  ('wiki-1', 'Wiki 1', 'Ufikiaji wa haraka', 3000, 7, 'calendar_month', FALSE, 1),
  ('mwezi-1', 'Mwezi 1', 'Thamani bora zaidi', 10000, 30, 'star', TRUE, 2),
  ('mwaka-1', 'Mwaka 1', 'Okoa TZS 20,000', 100000, 365, 'trending_up', FALSE, 3)
ON CONFLICT (id) DO NOTHING;

-- pending: recorded, not yet reviewed. approved: entitlement granted.
-- reversed: a previously approved payment was undone (refund, error, fraud).
CREATE TABLE IF NOT EXISTS payment_records (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  plan_id TEXT NOT NULL REFERENCES plans(id),
  method TEXT NOT NULL CHECK (method IN ('cash', 'bank_transfer')),
  amount_tzs INTEGER NOT NULL CHECK (amount_tzs >= 0),
  currency TEXT NOT NULL DEFAULT 'TZS',
  reference TEXT,
  note TEXT,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'reversed')),
  recorded_by TEXT NOT NULL REFERENCES users(id),
  approved_by TEXT REFERENCES users(id),
  approved_at TIMESTAMPTZ,
  reversed_by TEXT REFERENCES users(id),
  reversed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_payment_records_user
  ON payment_records (user_id);

-- Idempotency guard: a receipt/reference number, when staff record one, can
-- only ever back a single payment record — the same reference cannot be
-- entered twice and separately approved into two entitlements.
CREATE UNIQUE INDEX IF NOT EXISTS idx_payment_records_reference
  ON payment_records (reference) WHERE reference IS NOT NULL;

CREATE TABLE IF NOT EXISTS entitlements (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  plan_id TEXT NOT NULL REFERENCES plans(id),
  payment_record_id TEXT NOT NULL REFERENCES payment_records(id),
  status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'revoked', 'expired')),
  granted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- One entitlement per payment record: this is what makes approval
-- idempotent. A second approval attempt on the same payment_record_id hits
-- this constraint instead of minting a second grant of access.
CREATE UNIQUE INDEX IF NOT EXISTS idx_entitlements_payment_record
  ON entitlements (payment_record_id);

CREATE INDEX IF NOT EXISTS idx_entitlements_user_status
  ON entitlements (user_id, status);

-- Immutable: rows are only ever inserted, never updated or deleted. This is
-- the audit trail for every activation, reversal, and role change referenced
-- in the go-live design (who did it, when, previous status, new status, why).
CREATE TABLE IF NOT EXISTS audit_events (
  id TEXT PRIMARY KEY,
  actor_user_id TEXT REFERENCES users(id),
  action TEXT NOT NULL,
  target_type TEXT NOT NULL,
  target_id TEXT NOT NULL,
  previous_status TEXT,
  new_status TEXT,
  reason TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_audit_events_target
  ON audit_events (target_type, target_id, created_at DESC);

ALTER TABLE plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE entitlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_direct_client_access ON plans;
CREATE POLICY deny_direct_client_access ON plans
  FOR ALL TO public USING (false) WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON payment_records;
CREATE POLICY deny_direct_client_access ON payment_records
  FOR ALL TO public USING (false) WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON entitlements;
CREATE POLICY deny_direct_client_access ON entitlements
  FOR ALL TO public USING (false) WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON audit_events;
CREATE POLICY deny_direct_client_access ON audit_events
  FOR ALL TO public USING (false) WITH CHECK (false);
