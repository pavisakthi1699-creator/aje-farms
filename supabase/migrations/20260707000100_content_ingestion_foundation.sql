-- AJE Farms content ingestion and course catalogue foundation.
-- PDF source documents are authoritative evidence. NotebookLM imports are drafts
-- until linked to reviewed source_segments and explicitly published.

create extension if not exists pgcrypto;
do $$
begin
  create type public.content_status as enum ('draft', 'needs_review', 'approved', 'published', 'archived', 'failed');
exception when duplicate_object then null;
end $$;
do $$
begin
  create type public.content_risk_level as enum ('normal', 'medium', 'high');
exception when duplicate_object then null;
end $$;
do $$
begin
  create type public.lesson_type as enum ('reading', 'video', 'pdf', 'checklist', 'quiz', 'practical_task', 'audio');
exception when duplicate_object then null;
end $$;
do $$
begin
  create type public.import_source as enum ('manual', 'notebooklm', 'gemini_api', 'csv_import');
exception when duplicate_object then null;
end $$;
do $$
begin
  create type public.source_link_status as enum ('linked', 'source_missing', 'pending_review');
exception when duplicate_object then null;
end $$;
do $$
begin
  create type public.ingestion_job_status as enum ('queued', 'running', 'completed', 'failed', 'cancelled');
exception when duplicate_object then null;
end $$;
do $$
begin
  create type public.ingestion_job_type as enum ('extract_source_segments', 'generate_course_draft');
exception when duplicate_object then null;
end $$;
create table if not exists public.source_documents (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  language_code text not null default 'sw',
  source_type text not null,
  storage_bucket text not null default 'source-documents',
  storage_path text not null,
  file_name text not null,
  checksum text not null,
  page_count integer check (page_count is null or page_count > 0),
  version_number integer not null default 1 check (version_number > 0),
  processing_status public.content_status not null default 'draft',
  uploaded_by uuid references auth.users(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (storage_bucket, storage_path),
  unique (checksum, version_number)
);
create table if not exists public.source_segments (
  id uuid primary key default gen_random_uuid(),
  source_document_id uuid not null references public.source_documents(id) on delete cascade,
  page_start integer not null check (page_start > 0),
  page_end integer not null check (page_end >= page_start),
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
create table if not exists public.ingestion_jobs (
  id uuid primary key default gen_random_uuid(),
  source_document_id uuid not null references public.source_documents(id) on delete cascade,
  job_type public.ingestion_job_type not null default 'extract_source_segments',
  status public.ingestion_job_status not null default 'queued',
  idempotency_key text not null,
  requested_by uuid references auth.users(id) on delete set null,
  started_at timestamptz,
  completed_at timestamptz,
  error_message text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (idempotency_key)
);
create unique index if not exists ingestion_jobs_one_active_per_document_type
  on public.ingestion_jobs (source_document_id, job_type)
  where status in ('queued', 'running');
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
create table if not exists public.courses (
  id uuid primary key default gen_random_uuid(),
  category_id uuid references public.categories(id) on delete set null,
  code text not null unique,
  title_sw text not null,
  summary_sw text,
  description_sw text,
  language_code text not null default 'sw',
  status public.content_status not null default 'draft',
  risk_level public.content_risk_level not null default 'normal',
  import_source public.import_source not null default 'manual',
  external_id text,
  source_reference text,
  source_link_status public.source_link_status not null default 'pending_review',
  prerequisite_course_id uuid references public.courses(id) on delete restrict,
  sort_order integer not null default 0,
  published_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index if not exists courses_external_import_unique
  on public.courses(import_source, external_id)
  where external_id is not null;
create table if not exists public.course_modules (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  code text not null,
  title_sw text not null,
  summary_sw text,
  status public.content_status not null default 'draft',
  risk_level public.content_risk_level not null default 'normal',
  import_source public.import_source not null default 'manual',
  external_id text,
  source_reference text,
  source_link_status public.source_link_status not null default 'pending_review',
  sort_order integer not null default 0,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (course_id, code)
);
create unique index if not exists modules_external_import_unique
  on public.course_modules(import_source, external_id)
  where external_id is not null;
create table if not exists public.lessons (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references public.course_modules(id) on delete cascade,
  code text not null,
  title_sw text not null,
  body_sw text,
  lesson_type public.lesson_type not null default 'reading',
  duration_minutes integer check (duration_minutes is null or duration_minutes > 0),
  status public.content_status not null default 'draft',
  risk_level public.content_risk_level not null default 'normal',
  import_source public.import_source not null default 'manual',
  external_id text,
  source_reference text,
  source_link_status public.source_link_status not null default 'pending_review',
  sort_order integer not null default 0,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (module_id, code)
);
create unique index if not exists lessons_external_import_unique
  on public.lessons(import_source, external_id)
  where external_id is not null;
create table if not exists public.checklists (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid references public.lessons(id) on delete cascade,
  course_id uuid references public.courses(id) on delete cascade,
  code text not null,
  title_sw text not null,
  items_sw jsonb not null default '[]'::jsonb,
  status public.content_status not null default 'draft',
  risk_level public.content_risk_level not null default 'normal',
  import_source public.import_source not null default 'manual',
  external_id text,
  source_reference text,
  source_link_status public.source_link_status not null default 'pending_review',
  sort_order integer not null default 0,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (lesson_id is not null or course_id is not null)
);
create unique index if not exists checklists_lesson_code_unique
  on public.checklists(lesson_id, code)
  where lesson_id is not null;
create unique index if not exists checklists_course_code_unique
  on public.checklists(course_id, code)
  where course_id is not null;
create unique index if not exists checklists_external_import_unique
  on public.checklists(import_source, external_id)
  where external_id is not null;
create table if not exists public.quiz_questions (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid references public.lessons(id) on delete cascade,
  course_id uuid references public.courses(id) on delete cascade,
  code text not null,
  question_sw text not null,
  options_sw jsonb not null default '[]'::jsonb,
  correct_answer text,
  explanation_sw text,
  status public.content_status not null default 'draft',
  risk_level public.content_risk_level not null default 'normal',
  import_source public.import_source not null default 'manual',
  external_id text,
  source_reference text,
  source_link_status public.source_link_status not null default 'pending_review',
  sort_order integer not null default 0,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (lesson_id is not null or course_id is not null)
);
create unique index if not exists quiz_questions_lesson_code_unique
  on public.quiz_questions(lesson_id, code)
  where lesson_id is not null;
create unique index if not exists quiz_questions_course_code_unique
  on public.quiz_questions(course_id, code)
  where course_id is not null;
create unique index if not exists quiz_external_import_unique
  on public.quiz_questions(import_source, external_id)
  where external_id is not null;
create table if not exists public.faq_entries (
  id uuid primary key default gen_random_uuid(),
  course_id uuid references public.courses(id) on delete cascade,
  lesson_id uuid references public.lessons(id) on delete cascade,
  code text not null,
  question_sw text not null,
  answer_sw text not null,
  status public.content_status not null default 'draft',
  risk_level public.content_risk_level not null default 'normal',
  import_source public.import_source not null default 'manual',
  external_id text,
  source_reference text,
  source_link_status public.source_link_status not null default 'pending_review',
  sort_order integer not null default 0,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (lesson_id is not null or course_id is not null)
);
create unique index if not exists faq_lesson_code_unique
  on public.faq_entries(lesson_id, code)
  where lesson_id is not null;
create unique index if not exists faq_course_code_unique
  on public.faq_entries(course_id, code)
  where course_id is not null;
create unique index if not exists faq_external_import_unique
  on public.faq_entries(import_source, external_id)
  where external_id is not null;
create table if not exists public.content_gaps (
  id uuid primary key default gen_random_uuid(),
  course_id uuid references public.courses(id) on delete cascade,
  module_id uuid references public.course_modules(id) on delete cascade,
  lesson_id uuid references public.lessons(id) on delete cascade,
  code text not null,
  title_sw text not null,
  description_sw text,
  priority text not null default 'medium',
  status public.content_status not null default 'draft',
  import_source public.import_source not null default 'manual',
  external_id text,
  source_reference text,
  source_link_status public.source_link_status not null default 'source_missing',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index if not exists content_gaps_external_import_unique
  on public.content_gaps(import_source, external_id)
  where external_id is not null;
create table if not exists public.learning_paths (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  title_sw text not null,
  description_sw text,
  status public.content_status not null default 'draft',
  import_source public.import_source not null default 'manual',
  external_id text,
  source_reference text,
  sort_order integer not null default 0,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index if not exists learning_paths_external_import_unique
  on public.learning_paths(import_source, external_id)
  where external_id is not null;
create table if not exists public.learning_path_courses (
  id uuid primary key default gen_random_uuid(),
  learning_path_id uuid not null references public.learning_paths(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  prerequisite_course_id uuid references public.courses(id) on delete restrict,
  sort_order integer not null default 0,
  required boolean not null default true,
  created_at timestamptz not null default now(),
  unique (learning_path_id, course_id)
);
create table if not exists public.content_source_links (
  id uuid primary key default gen_random_uuid(),
  content_type text not null check (content_type in ('course', 'module', 'lesson', 'checklist', 'quiz_question', 'faq_entry')),
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
create table if not exists public.content_reviews (
  id uuid primary key default gen_random_uuid(),
  content_type text not null check (content_type in ('course', 'module', 'lesson', 'checklist', 'quiz_question', 'faq_entry', 'source_segment')),
  content_id uuid not null,
  status public.content_status not null,
  risk_level public.content_risk_level not null default 'normal',
  notes text,
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);
create table if not exists public.content_change_log (
  id uuid primary key default gen_random_uuid(),
  content_type text not null,
  content_id uuid not null,
  action text not null,
  changed_by uuid references auth.users(id) on delete set null,
  before_data jsonb,
  after_data jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create table if not exists public.curriculum_import_batches (
  id uuid primary key default gen_random_uuid(),
  import_source public.import_source not null default 'notebooklm',
  batch_hash text not null unique,
  file_name text,
  row_count integer not null default 0,
  valid_count integer not null default 0,
  error_count integer not null default 0,
  status public.content_status not null default 'draft',
  imported_by uuid references auth.users(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);
create table if not exists public.curriculum_import_errors (
  id uuid primary key default gen_random_uuid(),
  batch_id uuid not null references public.curriculum_import_batches(id) on delete cascade,
  row_number integer,
  external_row_id text,
  item_type text,
  error_code text not null,
  error_message text not null,
  raw_row jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'source_documents','source_segments','ingestion_jobs','categories','courses',
    'course_modules','lessons','checklists','quiz_questions','faq_entries',
    'content_gaps','learning_paths','content_source_links'
  ]
  loop
    execute format('drop trigger if exists set_%I_updated_at on public.%I', table_name, table_name);
    execute format('create trigger set_%I_updated_at before update on public.%I for each row execute function public.set_updated_at()', table_name, table_name);
  end loop;
end $$;
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
create or replace function public.is_content_admin()
returns boolean
language sql
stable
as $$
  select public.current_app_role() = 'admin';
$$;
create or replace function public.mark_content_link_status(
  target_type text,
  target_id uuid,
  next_status public.source_link_status
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if target_type = 'course' then
    update public.courses set source_link_status = next_status where id = target_id;
  elsif target_type = 'module' then
    update public.course_modules set source_link_status = next_status where id = target_id;
  elsif target_type = 'lesson' then
    update public.lessons set source_link_status = next_status where id = target_id;
  elsif target_type = 'checklist' then
    update public.checklists set source_link_status = next_status where id = target_id;
  elsif target_type = 'quiz_question' then
    update public.quiz_questions set source_link_status = next_status where id = target_id;
  elsif target_type = 'faq_entry' then
    update public.faq_entries set source_link_status = next_status where id = target_id;
  end if;
end;
$$;
create or replace function public.sync_source_document_on_link()
returns trigger
language plpgsql
as $$
begin
  if new.source_document_id is null then
    select source_document_id into new.source_document_id
    from public.source_segments
    where id = new.source_segment_id;
  end if;
  return new;
end;
$$;
drop trigger if exists sync_source_document_on_link on public.content_source_links;
create trigger sync_source_document_on_link
before insert or update on public.content_source_links
for each row execute function public.sync_source_document_on_link();
create or replace function public.content_source_links_after_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_type text := coalesce(new.content_type, old.content_type);
  target_id uuid := coalesce(new.content_id, old.content_id);
  has_linked boolean;
  has_any_link boolean;
begin
  select exists (
    select 1
    from public.content_source_links
    where content_type = target_type
      and content_id = target_id
      and link_status = 'linked'
  ) into has_linked;

  select exists (
    select 1
    from public.content_source_links
    where content_type = target_type
      and content_id = target_id
  ) into has_any_link;

  perform public.mark_content_link_status(
    target_type,
    target_id,
    case
      when has_linked then 'linked'::public.source_link_status
      when has_any_link then 'pending_review'::public.source_link_status
      else 'source_missing'::public.source_link_status
    end
  );
  return coalesce(new, old);
end;
$$;
drop trigger if exists content_source_links_after_change on public.content_source_links;
create trigger content_source_links_after_change
after insert or update or delete on public.content_source_links
for each row execute function public.content_source_links_after_change();
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
    union all
    select ck.id, 'checklist', ck.title_sw, ck.status, ck.risk_level, ck.source_link_status
    from public.checklists ck
    left join public.lessons l on l.id = ck.lesson_id
    left join public.course_modules m on m.id = l.module_id
    where ck.course_id = course_id_input or m.course_id = course_id_input
    union all
    select q.id, 'quiz_question', q.question_sw, q.status, q.risk_level, q.source_link_status
    from public.quiz_questions q
    left join public.lessons l on l.id = q.lesson_id
    left join public.course_modules m on m.id = l.module_id
    where q.course_id = course_id_input or m.course_id = course_id_input
    union all
    select f.id, 'faq_entry', f.question_sw, f.status, f.risk_level, f.source_link_status
    from public.faq_entries f
    left join public.lessons l on l.id = f.lesson_id
    left join public.course_modules m on m.id = l.module_id
    where f.course_id = course_id_input or m.course_id = course_id_input
  ),
  checked as (
    select
      cs.*,
      exists (
        select 1
        from public.content_source_links csl
        join public.source_segments ss on ss.id = csl.source_segment_id
        where csl.content_type = cs.content_type
          and csl.content_id = cs.content_id
          and csl.link_status = 'linked'
          and ss.review_status in ('approved', 'published')
      ) as has_valid_source
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
    where content_type in ('lesson', 'checklist', 'quiz_question', 'faq_entry')
      and (not has_valid_source or source_link_status in ('source_missing', 'pending_review'))
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
    'missing_source_links', coalesce(missing.items, '[]'::jsonb),
    'high_risk_needs_review', coalesce(high_risk.items, '[]'::jsonb)
  )
  into report
  from missing, high_risk;

  return report;
end;
$$;
create or replace function public.publish_course(course_id_input uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  validation jsonb;
  prereq_count integer;
  before_course jsonb;
  after_course jsonb;
begin
  if not public.is_content_editor() then
    raise exception 'Only editors and admins can publish courses' using errcode = '42501';
  end if;

  select to_jsonb(c.*) into before_course
  from public.courses c
  where c.id = course_id_input
  for update;

  if before_course is null then
    raise exception 'Course not found: %', course_id_input using errcode = 'P0002';
  end if;

  validation := public.validate_course_sources(course_id_input);
  if not (validation ->> 'valid')::boolean then
    return jsonb_build_object('published', false, 'validation', validation);
  end if;

  select count(*) into prereq_count
  from (
    select c.prerequisite_course_id as prerequisite_course_id
    from public.courses c
    where c.id = course_id_input and c.prerequisite_course_id is not null
    union
    select lpc.prerequisite_course_id
    from public.learning_path_courses lpc
    where lpc.course_id = course_id_input and lpc.prerequisite_course_id is not null
  ) prereqs
  join public.courses pc on pc.id = prereqs.prerequisite_course_id
  where pc.status <> 'published';

  if prereq_count > 0 then
    return jsonb_build_object(
      'published', false,
      'validation', validation,
      'blocking_prerequisite_count', prereq_count
    );
  end if;

  update public.courses
  set status = 'published',
      published_at = coalesce(published_at, now()),
      source_link_status = 'linked'
  where id = course_id_input;

  update public.course_modules set status = 'published', published_at = coalesce(published_at, now())
  where course_id = course_id_input and status in ('approved', 'published');

  update public.lessons l set status = 'published', published_at = coalesce(l.published_at, now())
  from public.course_modules m
  where m.id = l.module_id and m.course_id = course_id_input and l.status in ('approved', 'published');

  update public.checklists ck set status = 'published', published_at = coalesce(ck.published_at, now())
  where ck.status in ('approved', 'published')
    and (
      ck.course_id = course_id_input or exists (
        select 1 from public.lessons l join public.course_modules m on m.id = l.module_id
        where l.id = ck.lesson_id and m.course_id = course_id_input
      )
    );

  update public.quiz_questions q set status = 'published', published_at = coalesce(q.published_at, now())
  where q.status in ('approved', 'published')
    and (
      q.course_id = course_id_input or exists (
        select 1 from public.lessons l join public.course_modules m on m.id = l.module_id
        where l.id = q.lesson_id and m.course_id = course_id_input
      )
    );

  update public.faq_entries f set status = 'published', published_at = coalesce(f.published_at, now())
  where f.status in ('approved', 'published')
    and (
      f.course_id = course_id_input or exists (
        select 1 from public.lessons l join public.course_modules m on m.id = l.module_id
        where l.id = f.lesson_id and m.course_id = course_id_input
      )
    );

  select to_jsonb(c.*) into after_course from public.courses c where c.id = course_id_input;

  insert into public.content_change_log(content_type, content_id, action, changed_by, before_data, after_data, metadata)
  values ('course', course_id_input, 'publish', auth.uid(), before_course, after_course, jsonb_build_object('validation', validation));

  return jsonb_build_object('published', true, 'validation', validation);
end;
$$;
create or replace function public.enforce_published_learning_path_courses()
returns trigger
language plpgsql
as $$
declare
  path_status public.content_status;
  course_status public.content_status;
begin
  select status into path_status from public.learning_paths where id = new.learning_path_id;
  select status into course_status from public.courses where id = new.course_id;

  if path_status = 'published' and course_status <> 'published' then
    raise exception 'Published learning paths can only include published courses' using errcode = '23514';
  end if;

  if new.prerequisite_course_id is not null then
    select status into course_status from public.courses where id = new.prerequisite_course_id;
    if path_status = 'published' and course_status <> 'published' then
      raise exception 'Published learning paths can only include published prerequisite courses' using errcode = '23514';
    end if;
  end if;

  return new;
end;
$$;
drop trigger if exists enforce_published_learning_path_courses on public.learning_path_courses;
create trigger enforce_published_learning_path_courses
before insert or update on public.learning_path_courses
for each row execute function public.enforce_published_learning_path_courses();
create or replace function public.enforce_learning_path_publish_ready()
returns trigger
language plpgsql
as $$
declare
  unpublished_count integer;
begin
  if new.status = 'published' then
    select count(*) into unpublished_count
    from public.learning_path_courses lpc
    join public.courses c on c.id = lpc.course_id
    left join public.courses pc on pc.id = lpc.prerequisite_course_id
    where lpc.learning_path_id = new.id
      and (c.status <> 'published' or (pc.id is not null and pc.status <> 'published'));

    if unpublished_count > 0 then
      raise exception 'Learning path has unpublished courses or prerequisites' using errcode = '23514';
    end if;

    new.published_at = coalesce(new.published_at, now());
  end if;

  return new;
end;
$$;
drop trigger if exists enforce_learning_path_publish_ready on public.learning_paths;
create trigger enforce_learning_path_publish_ready
before insert or update on public.learning_paths
for each row execute function public.enforce_learning_path_publish_ready();
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'source-documents',
  'source-documents',
  false,
  104857600,
  array['application/pdf', 'text/plain', 'text/markdown', 'application/json', 'text/csv']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;
alter table public.source_documents enable row level security;
alter table public.source_segments enable row level security;
alter table public.ingestion_jobs enable row level security;
alter table public.categories enable row level security;
alter table public.courses enable row level security;
alter table public.course_modules enable row level security;
alter table public.lessons enable row level security;
alter table public.checklists enable row level security;
alter table public.quiz_questions enable row level security;
alter table public.faq_entries enable row level security;
alter table public.content_gaps enable row level security;
alter table public.learning_paths enable row level security;
alter table public.learning_path_courses enable row level security;
alter table public.content_source_links enable row level security;
alter table public.content_reviews enable row level security;
alter table public.content_change_log enable row level security;
alter table public.curriculum_import_batches enable row level security;
alter table public.curriculum_import_errors enable row level security;
grant usage on schema public to anon, authenticated;
grant select on public.categories, public.courses, public.course_modules, public.lessons, public.checklists, public.quiz_questions, public.faq_entries, public.learning_paths, public.learning_path_courses to anon, authenticated;
grant all on public.source_documents, public.source_segments, public.ingestion_jobs, public.categories, public.courses, public.course_modules, public.lessons, public.checklists, public.quiz_questions, public.faq_entries, public.content_gaps, public.learning_paths, public.learning_path_courses, public.content_source_links, public.content_reviews, public.content_change_log, public.curriculum_import_batches, public.curriculum_import_errors to authenticated;
revoke all on function public.mark_content_link_status(text, uuid, public.source_link_status) from public, anon, authenticated;
revoke all on function public.validate_course_sources(uuid) from public, anon;
revoke all on function public.publish_course(uuid) from public, anon;
grant execute on function public.validate_course_sources(uuid) to authenticated;
grant execute on function public.publish_course(uuid) to authenticated;
drop policy if exists "Editors manage source documents" on public.source_documents;
create policy "Editors manage source documents" on public.source_documents
for all to authenticated
using (public.is_content_editor())
with check (public.is_content_editor());
drop policy if exists "Editors manage source segments" on public.source_segments;
create policy "Editors manage source segments" on public.source_segments
for all to authenticated
using (public.is_content_editor())
with check (public.is_content_editor());
drop policy if exists "Editors manage ingestion jobs" on public.ingestion_jobs;
create policy "Editors manage ingestion jobs" on public.ingestion_jobs
for all to authenticated
using (public.is_content_editor())
with check (public.is_content_editor());
drop policy if exists "Published categories are readable" on public.categories;
create policy "Published categories are readable" on public.categories
for select to anon, authenticated
using (status = 'published' or public.is_content_editor());
drop policy if exists "Editors manage categories" on public.categories;
create policy "Editors manage categories" on public.categories
for all to authenticated
using (public.is_content_editor())
with check (public.is_content_editor());
drop policy if exists "Published courses are readable" on public.courses;
create policy "Published courses are readable" on public.courses
for select to anon, authenticated
using (status = 'published' or public.is_content_editor());
drop policy if exists "Editors manage courses" on public.courses;
create policy "Editors manage courses" on public.courses
for all to authenticated
using (public.is_content_editor())
with check (public.is_content_editor());
drop policy if exists "Published modules are readable" on public.course_modules;
create policy "Published modules are readable" on public.course_modules
for select to anon, authenticated
using (
  status = 'published'
  and exists (select 1 from public.courses c where c.id = course_id and c.status = 'published')
  or public.is_content_editor()
);
drop policy if exists "Editors manage modules" on public.course_modules;
create policy "Editors manage modules" on public.course_modules
for all to authenticated
using (public.is_content_editor())
with check (public.is_content_editor());
drop policy if exists "Published lessons are readable" on public.lessons;
create policy "Published lessons are readable" on public.lessons
for select to anon, authenticated
using (
  status = 'published'
  and exists (
    select 1
    from public.course_modules m
    join public.courses c on c.id = m.course_id
    where m.id = module_id and m.status = 'published' and c.status = 'published'
  )
  or public.is_content_editor()
);
drop policy if exists "Editors manage lessons" on public.lessons;
create policy "Editors manage lessons" on public.lessons
for all to authenticated
using (public.is_content_editor())
with check (public.is_content_editor());
drop policy if exists "Published checklists are readable" on public.checklists;
create policy "Published checklists are readable" on public.checklists
for select to anon, authenticated
using (
  status = 'published'
  and (
    exists (select 1 from public.courses c where c.id = course_id and c.status = 'published')
    or exists (
      select 1 from public.lessons l
      join public.course_modules m on m.id = l.module_id
      join public.courses c on c.id = m.course_id
      where l.id = lesson_id and l.status = 'published' and m.status = 'published' and c.status = 'published'
    )
  )
  or public.is_content_editor()
);
drop policy if exists "Editors manage checklists" on public.checklists;
create policy "Editors manage checklists" on public.checklists
for all to authenticated
using (public.is_content_editor())
with check (public.is_content_editor());
drop policy if exists "Published quiz questions are readable" on public.quiz_questions;
create policy "Published quiz questions are readable" on public.quiz_questions
for select to anon, authenticated
using (
  status = 'published'
  and (
    exists (select 1 from public.courses c where c.id = course_id and c.status = 'published')
    or exists (
      select 1 from public.lessons l
      join public.course_modules m on m.id = l.module_id
      join public.courses c on c.id = m.course_id
      where l.id = lesson_id and l.status = 'published' and m.status = 'published' and c.status = 'published'
    )
  )
  or public.is_content_editor()
);
drop policy if exists "Editors manage quiz questions" on public.quiz_questions;
create policy "Editors manage quiz questions" on public.quiz_questions
for all to authenticated
using (public.is_content_editor())
with check (public.is_content_editor());
drop policy if exists "Published FAQs are readable" on public.faq_entries;
create policy "Published FAQs are readable" on public.faq_entries
for select to anon, authenticated
using (
  status = 'published'
  and (
    exists (select 1 from public.courses c where c.id = course_id and c.status = 'published')
    or exists (
      select 1 from public.lessons l
      join public.course_modules m on m.id = l.module_id
      join public.courses c on c.id = m.course_id
      where l.id = lesson_id and l.status = 'published' and m.status = 'published' and c.status = 'published'
    )
  )
  or public.is_content_editor()
);
drop policy if exists "Editors manage FAQs" on public.faq_entries;
create policy "Editors manage FAQs" on public.faq_entries
for all to authenticated
using (public.is_content_editor())
with check (public.is_content_editor());
drop policy if exists "Editors manage content gaps" on public.content_gaps;
create policy "Editors manage content gaps" on public.content_gaps
for all to authenticated
using (public.is_content_editor())
with check (public.is_content_editor());
drop policy if exists "Published learning paths are readable" on public.learning_paths;
create policy "Published learning paths are readable" on public.learning_paths
for select to anon, authenticated
using (status = 'published' or public.is_content_editor());
drop policy if exists "Editors manage learning paths" on public.learning_paths;
create policy "Editors manage learning paths" on public.learning_paths
for all to authenticated
using (public.is_content_editor())
with check (public.is_content_editor());
drop policy if exists "Published learning path courses are readable" on public.learning_path_courses;
create policy "Published learning path courses are readable" on public.learning_path_courses
for select to anon, authenticated
using (
  exists (
    select 1
    from public.learning_paths lp
    join public.courses c on c.id = course_id
    where lp.id = learning_path_id and lp.status = 'published' and c.status = 'published'
  )
  or public.is_content_editor()
);
drop policy if exists "Editors manage learning path courses" on public.learning_path_courses;
create policy "Editors manage learning path courses" on public.learning_path_courses
for all to authenticated
using (public.is_content_editor())
with check (public.is_content_editor());
drop policy if exists "Editors manage source links" on public.content_source_links;
create policy "Editors manage source links" on public.content_source_links
for all to authenticated
using (public.is_content_editor())
with check (public.is_content_editor());
drop policy if exists "Editors manage reviews" on public.content_reviews;
create policy "Editors manage reviews" on public.content_reviews
for all to authenticated
using (public.is_content_editor())
with check (public.is_content_editor());
drop policy if exists "Editors read change log" on public.content_change_log;
create policy "Editors read change log" on public.content_change_log
for select to authenticated
using (public.is_content_editor());
drop policy if exists "Editors write change log" on public.content_change_log;
create policy "Editors write change log" on public.content_change_log
for insert to authenticated
with check (public.is_content_editor());
drop policy if exists "Editors manage import batches" on public.curriculum_import_batches;
create policy "Editors manage import batches" on public.curriculum_import_batches
for all to authenticated
using (public.is_content_editor())
with check (public.is_content_editor());
drop policy if exists "Editors manage import errors" on public.curriculum_import_errors;
create policy "Editors manage import errors" on public.curriculum_import_errors
for all to authenticated
using (public.is_content_editor())
with check (public.is_content_editor());
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
using (bucket_id = 'source-documents' and public.is_content_admin());
with category_seed as (
  insert into public.categories (code, name_sw, description_sw, status, sort_order)
  values ('kilimo-cha-mazao', 'Kilimo cha Mazao', 'Maarifa ya uzalishaji wa mazao kwa wakulima.', 'published', 10)
  on conflict (code) do update set name_sw = excluded.name_sw, description_sw = excluded.description_sw
  returning id
),
path_seed as (
  insert into public.learning_paths (code, title_sw, description_sw, status, sort_order)
  values ('mkulima-wa-mpunga-mwanzo-hadi-soko', 'Mkulima wa Mpunga — Mwanzo hadi Soko', 'Njia ya kujifunza kilimo cha mpunga kutoka maandalizi hadi soko.', 'draft', 10)
  on conflict (code) do update set title_sw = excluded.title_sw, description_sw = excluded.description_sw
  returning id
),
course_seed as (
  insert into public.courses (category_id, code, title_sw, summary_sw, status, import_source, source_link_status, sort_order)
  select category_seed.id, 'kilimo-cha-mpunga-kibiashara', 'Kilimo cha Mpunga Kibiashara', 'Kozi ya awali ya kilimo cha mpunga kwa misingi ya kibiashara.', 'draft', 'manual', 'source_missing', 10
  from category_seed
  on conflict (code) do update set title_sw = excluded.title_sw, summary_sw = excluded.summary_sw
  returning id
)
insert into public.course_modules (course_id, code, title_sw, status, import_source, source_link_status, sort_order)
select course_seed.id, module_code, module_title, 'draft', 'manual', 'source_missing', module_order
from course_seed
cross join (values
  ('maandalizi-ya-shamba', 'Maandalizi ya Shamba', 10),
  ('mbegu-na-upandaji', 'Mbegu na Upandaji', 20),
  ('utunzaji-wa-shamba', 'Utunzaji wa Shamba', 30),
  ('uvunaji-na-soko', 'Uvunaji na Soko', 40)
) as modules(module_code, module_title, module_order)
on conflict (course_id, code) do update set title_sw = excluded.title_sw, sort_order = excluded.sort_order;
insert into public.learning_path_courses (learning_path_id, course_id, sort_order, required)
select lp.id, c.id, 10, true
from public.learning_paths lp
join public.courses c on c.code = 'kilimo-cha-mpunga-kibiashara'
where lp.code = 'mkulima-wa-mpunga-mwanzo-hadi-soko'
on conflict (learning_path_id, course_id) do nothing;
