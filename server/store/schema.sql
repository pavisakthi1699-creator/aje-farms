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

CREATE INDEX IF NOT EXISTS idx_payment_transactions_phone
  ON payment_transactions (phone_number);

CREATE TABLE IF NOT EXISTS auth_sessions (
  token TEXT PRIMARY KEY,
  phone_number TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_auth_sessions_phone
  ON auth_sessions (phone_number);

CREATE INDEX IF NOT EXISTS idx_auth_sessions_expires
  ON auth_sessions (expires_at);

CREATE TABLE IF NOT EXISTS learning_progress (
  phone_number TEXT NOT NULL,
  course_id TEXT NOT NULL,
  lesson_id TEXT NOT NULL,
  completed_at TIMESTAMPTZ NOT NULL,
  PRIMARY KEY (phone_number, course_id, lesson_id)
);

CREATE INDEX IF NOT EXISTS idx_learning_progress_phone
  ON learning_progress (phone_number);

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

CREATE INDEX IF NOT EXISTS idx_notification_devices_phone
  ON notification_devices (phone_number);

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

CREATE INDEX IF NOT EXISTS idx_notifications_phone_created
  ON notifications (phone_number, created_at DESC);

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
