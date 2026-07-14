-- Bring the live curriculum schema up to the category-aware NotebookLM importer.
-- This is intentionally additive so it can run against the older live schema.

create extension if not exists pgcrypto;

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name_sw text not null,
  description_sw text,
  status public.content_status not null default 'draft',
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.courses
  add column if not exists category_id uuid references public.categories(id) on delete set null,
  add column if not exists summary_sw text,
  add column if not exists description_sw text,
  add column if not exists prerequisite_course_id uuid references public.courses(id) on delete restrict,
  add column if not exists published_at timestamptz,
  add column if not exists created_by uuid references auth.users(id) on delete set null,
  add column if not exists updated_by uuid references auth.users(id) on delete set null;

alter table public.course_modules
  add column if not exists summary_sw text,
  add column if not exists published_at timestamptz;

alter table public.lessons
  add column if not exists duration_minutes integer check (duration_minutes is null or duration_minutes > 0),
  add column if not exists published_at timestamptz;

alter table public.learning_paths
  add column if not exists description_sw text,
  add column if not exists import_source text not null default 'manual',
  add column if not exists external_id text,
  add column if not exists source_reference text,
  add column if not exists sort_order integer not null default 0,
  add column if not exists published_at timestamptz;

alter table public.learning_path_courses
  add column if not exists prerequisite_course_id uuid references public.courses(id) on delete restrict;

create unique index if not exists learning_paths_external_import_unique
  on public.learning_paths(import_source, external_id)
  where external_id is not null;

create or replace function public.current_app_role()
returns text
language sql
stable
as $$
  select coalesce(
    nullif((auth.jwt() -> 'app_metadata' ->> 'role'), ''),
    nullif((auth.jwt() -> 'app_metadata' ->> 'app_role'), ''),
    'learner'
  );
$$;

create or replace function public.is_content_editor()
returns boolean
language sql
stable
as $$
  select public.current_app_role() in ('editor', 'admin');
$$;

create or replace function public.validate_course_sources(course_id_input uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  report jsonb;
begin
  if not public.is_content_editor() then
    raise exception 'Only editors and admins can validate course sources' using errcode = '42501';
  end if;

  with course_scope as (
    select c.id as content_id, 'course'::text as content_type, c.title_sw as title, c.status, c.risk_level, c.source_link_status
    from public.courses c
    where c.id = course_id_input
    union all
    select m.id, 'module', m.title_sw, m.status, m.risk_level, m.source_link_status
    from public.course_modules m
    where m.course_id = course_id_input
    union all
    select l.id, 'lesson', l.title_sw, l.status, l.risk_level, l.source_link_status
    from public.lessons l
    join public.course_modules m on m.id = l.module_id
    where m.course_id = course_id_input
  ),
  checked as (
    select
      cs.*,
      exists (
        select 1
        from public.content_source_assets csa
        join public.source_documents sd on sd.id = csa.source_document_id
        where csa.content_type = cs.content_type
          and csa.content_id = cs.content_id
          and csa.link_status in ('pending_review', 'linked')
          and sd.processing_status in ('draft', 'needs_review', 'approved', 'published')
      ) as has_source_asset,
      exists (
        select 1
        from public.content_source_assets csa
        join public.source_documents sd on sd.id = csa.source_document_id
        where csa.content_type = cs.content_type
          and csa.content_id = cs.content_id
          and csa.link_status = 'linked'
          and sd.processing_status in ('approved', 'published')
      ) as has_publish_ready_source
    from course_scope cs
  ),
  missing as (
    select jsonb_agg(jsonb_build_object(
      'content_type', content_type,
      'content_id', content_id,
      'title', title,
      'source_link_status', source_link_status
    ) order by content_type, title) as items
    from checked
    where content_type in ('module', 'lesson')
      and not has_source_asset
  ),
  pending as (
    select jsonb_agg(jsonb_build_object(
      'content_type', content_type,
      'content_id', content_id,
      'title', title,
      'source_link_status', source_link_status
    ) order by content_type, title) as items
    from checked
    where content_type in ('module', 'lesson')
      and has_source_asset
      and not has_publish_ready_source
  ),
  high_risk as (
    select jsonb_agg(jsonb_build_object(
      'content_type', content_type,
      'content_id', content_id,
      'title', title,
      'status', status
    ) order by content_type, title) as items
    from checked
    where risk_level = 'high' and status in ('draft', 'needs_review')
  )
  select jsonb_build_object(
    'course_id', course_id_input,
    'valid', coalesce(jsonb_array_length(missing.items), 0) = 0 and coalesce(jsonb_array_length(high_risk.items), 0) = 0,
    'publish_ready', coalesce(jsonb_array_length(missing.items), 0) = 0 and coalesce(jsonb_array_length(pending.items), 0) = 0 and coalesce(jsonb_array_length(high_risk.items), 0) = 0,
    'missing_source_assets', coalesce(missing.items, '[]'::jsonb),
    'pending_source_review', coalesce(pending.items, '[]'::jsonb),
    'high_risk_needs_review', coalesce(high_risk.items, '[]'::jsonb)
  )
  into report
  from missing, pending, high_risk;

  return report;
end;
$$;

revoke all on function public.validate_course_sources(uuid) from public, anon;
grant execute on function public.validate_course_sources(uuid) to authenticated;

alter table public.categories enable row level security;
grant select on public.categories to anon, authenticated;
grant all on public.categories to authenticated;

drop policy if exists "Published categories are readable" on public.categories;
create policy "Published categories are readable" on public.categories
for select to anon, authenticated
using (status = 'published' or public.is_content_editor());

drop policy if exists "Editors manage categories" on public.categories;
create policy "Editors manage categories" on public.categories
for all to authenticated
using (public.is_content_editor())
with check (public.is_content_editor());
