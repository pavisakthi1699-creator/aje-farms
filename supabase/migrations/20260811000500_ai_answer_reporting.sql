CREATE TABLE IF NOT EXISTS public.ai_answers (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  prompt TEXT NOT NULL,
  answer TEXT NOT NULL,
  source_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.ai_answer_reports (
  id TEXT PRIMARY KEY,
  answer_id TEXT NOT NULL REFERENCES public.ai_answers(id) ON DELETE CASCADE,
  reporter_user_id TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  details TEXT,
  status TEXT NOT NULL DEFAULT 'open'
    CHECK (status IN ('open', 'resolved', 'dismissed')),
  reported_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at TIMESTAMPTZ,
  resolved_by TEXT REFERENCES public.users(id),
  resolution_note TEXT
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_ai_answer_reports_open_reporter
  ON public.ai_answer_reports (answer_id, reporter_user_id)
  WHERE status = 'open';
CREATE INDEX IF NOT EXISTS idx_ai_answer_reports_queue
  ON public.ai_answer_reports (status, reported_at DESC);

ALTER TABLE public.ai_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_answer_reports ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.ai_answers FROM anon, authenticated;
REVOKE ALL ON TABLE public.ai_answer_reports FROM anon, authenticated;
DROP POLICY IF EXISTS deny_direct_client_access ON public.ai_answers;
CREATE POLICY deny_direct_client_access ON public.ai_answers
  FOR ALL TO public USING (false) WITH CHECK (false);
DROP POLICY IF EXISTS deny_direct_client_access ON public.ai_answer_reports;
CREATE POLICY deny_direct_client_access ON public.ai_answer_reports
  FOR ALL TO public USING (false) WITH CHECK (false);
