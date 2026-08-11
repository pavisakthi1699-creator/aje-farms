CREATE TABLE IF NOT EXISTS plans (
  id TEXT PRIMARY KEY, title TEXT NOT NULL, subtitle TEXT,
  price_tzs INTEGER NOT NULL CHECK (price_tzs >= 0),
  duration_days INTEGER NOT NULL CHECK (duration_days > 0),
  icon TEXT, recommended BOOLEAN NOT NULL DEFAULT FALSE,
  enabled BOOLEAN NOT NULL DEFAULT TRUE, sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
INSERT INTO plans (id, title, subtitle, price_tzs, duration_days, icon, recommended, sort_order)
VALUES
  ('wiki-1', 'Wiki 1', 'Ufikiaji wa haraka', 3000, 7, 'calendar_month', FALSE, 1),
  ('mwezi-1', 'Mwezi 1', 'Thamani bora zaidi', 10000, 30, 'star', TRUE, 2),
  ('mwaka-1', 'Mwaka 1', 'Okoa TZS 20,000', 100000, 365, 'trending_up', FALSE, 3)
ON CONFLICT (id) DO NOTHING;
CREATE TABLE IF NOT EXISTS payment_records (
  id TEXT PRIMARY KEY, user_id TEXT NOT NULL REFERENCES users(id),
  plan_id TEXT NOT NULL REFERENCES plans(id),
  method TEXT NOT NULL CHECK (method IN ('cash', 'bank_transfer')),
  amount_tzs INTEGER NOT NULL CHECK (amount_tzs >= 0), currency TEXT NOT NULL DEFAULT 'TZS',
  reference TEXT, note TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'reversed')),
  recorded_by TEXT NOT NULL REFERENCES users(id), approved_by TEXT REFERENCES users(id),
  approved_at TIMESTAMPTZ, reversed_by TEXT REFERENCES users(id), reversed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_payment_records_user ON payment_records (user_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_payment_records_reference ON payment_records (reference) WHERE reference IS NOT NULL;
CREATE TABLE IF NOT EXISTS entitlements (
  id TEXT PRIMARY KEY, user_id TEXT NOT NULL REFERENCES users(id),
  plan_id TEXT NOT NULL REFERENCES plans(id),
  payment_record_id TEXT NOT NULL REFERENCES payment_records(id),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'revoked', 'expired')),
  granted_at TIMESTAMPTZ NOT NULL DEFAULT now(), expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ, created_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_entitlements_payment_record ON entitlements (payment_record_id);
CREATE INDEX IF NOT EXISTS idx_entitlements_user_status ON entitlements (user_id, status);
CREATE TABLE IF NOT EXISTS audit_events (
  id TEXT PRIMARY KEY, actor_user_id TEXT REFERENCES users(id), action TEXT NOT NULL,
  target_type TEXT NOT NULL, target_id TEXT NOT NULL, previous_status TEXT, new_status TEXT,
  reason TEXT, metadata JSONB NOT NULL DEFAULT '{}'::jsonb, created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_audit_events_target ON audit_events (target_type, target_id, created_at DESC);
ALTER TABLE plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE entitlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_events ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS deny_direct_client_access ON plans;
CREATE POLICY deny_direct_client_access ON plans FOR ALL TO public USING (false) WITH CHECK (false);
DROP POLICY IF EXISTS deny_direct_client_access ON payment_records;
CREATE POLICY deny_direct_client_access ON payment_records FOR ALL TO public USING (false) WITH CHECK (false);
DROP POLICY IF EXISTS deny_direct_client_access ON entitlements;
CREATE POLICY deny_direct_client_access ON entitlements FOR ALL TO public USING (false) WITH CHECK (false);
DROP POLICY IF EXISTS deny_direct_client_access ON audit_events;
CREATE POLICY deny_direct_client_access ON audit_events FOR ALL TO public USING (false) WITH CHECK (false);
;
