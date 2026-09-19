CREATE TABLE IF NOT EXISTS public.community_reports (
  id TEXT PRIMARY KEY,
  post_id TEXT NOT NULL REFERENCES public.community_posts(id) ON DELETE CASCADE,
  reporter_user_id TEXT REFERENCES public.users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  details TEXT,
  status TEXT NOT NULL DEFAULT 'open'
    CHECK (status IN ('open', 'resolved', 'dismissed')),
  reported_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at TIMESTAMPTZ,
  resolved_by TEXT REFERENCES public.users(id),
  resolution TEXT
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_community_reports_open_reporter
  ON public.community_reports (post_id, reporter_user_id)
  WHERE status = 'open';
CREATE INDEX IF NOT EXISTS idx_community_reports_queue
  ON public.community_reports (status, reported_at DESC);

INSERT INTO public.community_reports (
  id, post_id, reporter_user_id, reason, status, reported_at
)
SELECT
  'legacy-report-' || md5(r.post_id),
  r.post_id,
  NULL,
  'other',
  'open',
  r.reported_at
FROM public.reported_community_posts r
ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS public.community_user_blocks (
  blocker_user_id TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  blocked_user_id TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  source_post_id TEXT REFERENCES public.community_posts(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (blocker_user_id, blocked_user_id),
  CHECK (blocker_user_id <> blocked_user_id)
);

ALTER TABLE public.community_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_user_blocks ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.community_reports FROM anon, authenticated;
REVOKE ALL ON TABLE public.community_user_blocks FROM anon, authenticated;
DROP POLICY IF EXISTS deny_direct_client_access ON public.community_reports;
CREATE POLICY deny_direct_client_access ON public.community_reports
  FOR ALL TO public USING (false) WITH CHECK (false);
DROP POLICY IF EXISTS deny_direct_client_access ON public.community_user_blocks;
CREATE POLICY deny_direct_client_access ON public.community_user_blocks
  FOR ALL TO public USING (false) WITH CHECK (false);
