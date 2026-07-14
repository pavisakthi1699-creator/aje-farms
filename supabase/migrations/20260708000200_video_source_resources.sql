-- Video/transcript source support for staged curriculum promotion.

alter table public.source_documents
  add column if not exists source_kind text not null default 'document'
  check (source_kind in ('video', 'transcript', 'pdf', 'document', 'audio', 'image'));

update public.source_documents
set source_kind = case
  when lower(source_type) like '%video%' then 'video'
  when lower(source_type) like '%transcript%' then 'transcript'
  when lower(source_type) like '%pdf%' then 'pdf'
  when lower(source_type) like '%audio%' then 'audio'
  when lower(source_type) like '%image%' then 'image'
  else 'document'
end
where source_kind is null or source_kind = 'document';

create table if not exists public.content_source_assets (
  id uuid primary key default gen_random_uuid(),
  content_type text not null check (content_type in ('course', 'module', 'lesson', 'checklist', 'quiz_question', 'faq_entry')),
  content_id uuid not null,
  source_document_id uuid not null references public.source_documents(id) on delete restrict,
  link_status public.source_link_status not null default 'pending_review',
  evidence_note text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (content_type, content_id, source_document_id)
);

create index if not exists content_source_assets_content_idx
  on public.content_source_assets (content_type, content_id, link_status);

create index if not exists content_source_assets_document_idx
  on public.content_source_assets (source_document_id);

drop trigger if exists set_content_source_assets_updated_at on public.content_source_assets;
create trigger set_content_source_assets_updated_at
before update on public.content_source_assets
for each row execute function public.set_updated_at();

create table if not exists public.lesson_resources (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  resource_type text not null check (resource_type in ('video', 'transcript', 'pdf', 'audio', 'image')),
  storage_path text,
  external_url text,
  title_sw text not null,
  duration_seconds integer check (duration_seconds is null or duration_seconds > 0),
  transcript_source_document_id uuid references public.source_documents(id) on delete set null,
  status public.content_status not null default 'draft',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (lesson_id, resource_type, title_sw)
);

create index if not exists lesson_resources_lesson_idx
  on public.lesson_resources (lesson_id, resource_type, status);

drop trigger if exists set_lesson_resources_updated_at on public.lesson_resources;
create trigger set_lesson_resources_updated_at
before update on public.lesson_resources
for each row execute function public.set_updated_at();

alter table public.content_source_assets enable row level security;
alter table public.lesson_resources enable row level security;

grant all on public.content_source_assets, public.lesson_resources to authenticated;
grant select on public.lesson_resources to anon;

drop policy if exists "Editors manage source assets" on public.content_source_assets;
create policy "Editors manage source assets" on public.content_source_assets
for all to authenticated
using (public.is_content_editor())
with check (public.is_content_editor());

drop policy if exists "Published lesson resources are readable" on public.lesson_resources;
create policy "Published lesson resources are readable" on public.lesson_resources
for select to anon, authenticated
using (
  status = 'published'
  and exists (
    select 1
    from public.lessons l
    join public.course_modules m on m.id = l.module_id
    join public.courses c on c.id = m.course_id
    where l.id = lesson_id and l.status = 'published' and m.status = 'published' and c.status = 'published'
  )
  or public.is_content_editor()
);

drop policy if exists "Editors manage lesson resources" on public.lesson_resources;
create policy "Editors manage lesson resources" on public.lesson_resources
for all to authenticated
using (public.is_content_editor())
with check (public.is_content_editor());
