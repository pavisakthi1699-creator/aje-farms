-- AJE Farms learner content is either video or text.
-- NotebookLM facts are grounding drafts until linked to reviewed source evidence.

alter table if exists public.courses
  add column if not exists delivery_type text not null default 'text';
alter table if exists public.source_documents
  add column if not exists page_count integer;
alter table if exists public.source_documents
  drop constraint if exists source_documents_page_count_check;
alter table if exists public.source_documents
  add constraint source_documents_page_count_check
  check (page_count is null or page_count > 0);
alter table if exists public.courses
  drop constraint if exists courses_delivery_type_check;
alter table if exists public.courses
  add constraint courses_delivery_type_check
  check (delivery_type in ('video', 'text'));
create table if not exists public.source_segments (
  id uuid primary key default gen_random_uuid(),
  source_document_id uuid not null references public.source_documents(id) on delete cascade,
  page_start integer,
  page_end integer,
  time_start_seconds integer,
  time_end_seconds integer,
  section_title text,
  segment_order integer not null default 1 check (segment_order > 0),
  content_sw text not null,
  content_hash text not null,
  extraction_method text not null default 'manual',
  review_status public.content_status not null default 'needs_review',
  risk_level public.content_risk_level not null default 'normal',
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (source_document_id, content_hash),
  unique (source_document_id, segment_order)
);
alter table public.source_segments
  alter column page_start drop not null,
  alter column page_end drop not null;
alter table public.source_segments
  add column if not exists time_start_seconds integer,
  add column if not exists time_end_seconds integer;
alter table public.source_segments
  drop constraint if exists source_segments_location_check;
alter table public.source_segments
  add constraint source_segments_location_check check (
    (
      page_start is not null
      and page_start > 0
      and page_end is not null
      and page_end >= page_start
      and time_start_seconds is null
      and time_end_seconds is null
    )
    or (
      time_start_seconds is not null
      and time_start_seconds >= 0
      and time_end_seconds is not null
      and time_end_seconds >= time_start_seconds
      and page_start is null
      and page_end is null
    )
  );
create table if not exists public.content_source_links (
  id uuid primary key default gen_random_uuid(),
  content_type text not null,
  content_id uuid not null,
  source_segment_id uuid not null references public.source_segments(id) on delete restrict,
  source_document_id uuid not null references public.source_documents(id) on delete restrict,
  link_status public.source_link_status not null default 'pending_review',
  evidence_note text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (content_type, content_id, source_segment_id)
);
create table if not exists public.grounding_facts (
  id uuid primary key default gen_random_uuid(),
  course_id uuid references public.courses(id) on delete cascade,
  module_id uuid references public.course_modules(id) on delete cascade,
  lesson_id uuid references public.lessons(id) on delete cascade,
  source_segment_id uuid not null references public.source_segments(id) on delete restrict,
  code text not null,
  fact_sw text not null,
  question_sw text,
  status public.content_status not null default 'needs_review',
  risk_level public.content_risk_level not null default 'normal',
  import_source text not null default 'notebooklm',
  external_id text,
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (course_id is not null or module_id is not null or lesson_id is not null),
  unique (source_segment_id, code)
);
create unique index if not exists grounding_facts_external_import_unique
  on public.grounding_facts(import_source, external_id)
  where external_id is not null;
create index if not exists grounding_facts_course_status_idx
  on public.grounding_facts(course_id, status, risk_level);
create index if not exists grounding_facts_lesson_status_idx
  on public.grounding_facts(lesson_id, status, risk_level);
create table if not exists public.content_course_revisions (
  id uuid primary key default gen_random_uuid(),
  course_id text not null,
  previous_status text not null,
  previous_payload jsonb not null,
  reason text not null,
  created_at timestamptz not null default now()
);
alter table public.source_segments enable row level security;
alter table public.content_source_links enable row level security;
alter table public.grounding_facts enable row level security;
alter table public.content_course_revisions enable row level security;
drop policy if exists "Editors manage source segments" on public.source_segments;
create policy "Editors manage source segments" on public.source_segments
for all to authenticated
using (public.is_content_editor())
with check (public.is_content_editor());
drop policy if exists "Editors manage content source links" on public.content_source_links;
create policy "Editors manage content source links" on public.content_source_links
for all to authenticated
using (public.is_content_editor())
with check (public.is_content_editor());
drop policy if exists "Editors manage grounding facts" on public.grounding_facts;
create policy "Editors manage grounding facts" on public.grounding_facts
for all to authenticated
using (public.is_content_editor())
with check (public.is_content_editor());
drop policy if exists "Published grounding facts are readable" on public.grounding_facts;
create policy "Published grounding facts are readable" on public.grounding_facts
for select to anon, authenticated
using (
  status = 'published'
  and risk_level <> 'high'
  and exists (
    select 1
    from public.source_segments ss
    join public.source_documents sd on sd.id = ss.source_document_id
    where ss.id = source_segment_id
      and ss.review_status in ('approved', 'published')
      and sd.processing_status in ('approved', 'published')
  )
  or public.is_content_editor()
);
drop policy if exists "Editors manage content course revisions" on public.content_course_revisions;
create policy "Editors manage content course revisions" on public.content_course_revisions
for all to authenticated
using (public.is_content_editor())
with check (public.is_content_editor());
grant select on public.grounding_facts to anon, authenticated;
grant all on public.source_segments, public.content_source_links, public.grounding_facts, public.content_course_revisions to authenticated;
comment on table public.grounding_facts is
  'Reviewed factual statements used to ground Mwalimu AI. Every fact must cite one reviewed PDF page segment or video transcript time segment.';
comment on table public.content_course_revisions is
  'Reversible snapshots of learner catalogue payloads before automated cleanup or replacement.';
insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'source-documents',
  'source-documents',
  false,
  104857600,
  array[
    'application/pdf',
    'video/mp4',
    'text/plain',
    'text/markdown',
    'application/json',
    'text/csv'
  ]
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;
drop policy if exists "Editors upload source documents" on storage.objects;
create policy "Editors upload source documents"
on storage.objects for insert to authenticated
with check (bucket_id = 'source-documents' and public.is_content_editor());
drop policy if exists "Editors read source documents" on storage.objects;
create policy "Editors read source documents"
on storage.objects for select to authenticated
using (bucket_id = 'source-documents' and public.is_content_editor());
drop policy if exists "Editors update source documents" on storage.objects;
create policy "Editors update source documents"
on storage.objects for update to authenticated
using (bucket_id = 'source-documents' and public.is_content_editor())
with check (bucket_id = 'source-documents' and public.is_content_editor());
drop policy if exists "Admins delete source documents" on storage.objects;
create policy "Admins delete source documents"
on storage.objects for delete to authenticated
using (
  bucket_id = 'source-documents'
  and coalesce(
    auth.jwt()->'app_metadata'->>'role',
    auth.jwt()->'app_metadata'->>'app_role'
  ) = 'admin'
);
