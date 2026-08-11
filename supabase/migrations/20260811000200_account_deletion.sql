-- Account deletion support. Personal account data is removed by the trusted
-- backend; this table holds public web requests until support verifies them.
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

CREATE TABLE IF NOT EXISTS public.account_deletion_requests (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'completed', 'rejected')),
  requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  processed_at TIMESTAMPTZ,
  processed_by TEXT REFERENCES public.users(id),
  resolution_note TEXT
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_account_deletion_pending_email
  ON public.account_deletion_requests (lower(email))
  WHERE status = 'pending';

ALTER TABLE public.account_deletion_requests ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.account_deletion_requests FROM anon, authenticated;
DROP POLICY IF EXISTS deny_direct_client_access
  ON public.account_deletion_requests;
CREATE POLICY deny_direct_client_access
  ON public.account_deletion_requests
  FOR ALL TO public
  USING (false)
  WITH CHECK (false);
