ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS terms_accepted_version TEXT;
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS terms_accepted_at TIMESTAMPTZ;
