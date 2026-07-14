-- Stage-first curriculum import pipeline.
-- Imports are written to staging rows, then explicitly promoted into catalogue tables.

create table if not exists public.curriculum_staging_rows (
  id uuid primary key default gen_random_uuid(),
  batch_id uuid not null references public.curriculum_import_batches(id) on delete cascade,
  row_number integer not null check (row_number > 0),
  external_row_id text,
  item_type text not null,
  row_data jsonb not null default '{}'::jsonb,
  validation_status text not null default 'valid' check (validation_status in ('valid', 'invalid', 'promoted')),
  error_code text,
  error_message text,
  promoted_content_type text,
  promoted_content_id uuid,
  promoted_at timestamptz,
  promotion_result jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (batch_id, row_number)
);

create index if not exists curriculum_staging_rows_batch_status_idx
  on public.curriculum_staging_rows (batch_id, validation_status, row_number);

create index if not exists curriculum_staging_rows_external_row_idx
  on public.curriculum_staging_rows (external_row_id)
  where external_row_id is not null;

drop trigger if exists set_curriculum_staging_rows_updated_at on public.curriculum_staging_rows;
create trigger set_curriculum_staging_rows_updated_at
before update on public.curriculum_staging_rows
for each row execute function public.set_updated_at();

alter table public.curriculum_staging_rows enable row level security;

grant all on public.curriculum_staging_rows to authenticated;

drop policy if exists "Editors manage curriculum staging rows" on public.curriculum_staging_rows;
create policy "Editors manage curriculum staging rows" on public.curriculum_staging_rows
for all to authenticated
using (public.is_content_editor())
with check (public.is_content_editor());
