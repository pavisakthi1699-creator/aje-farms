do $$ begin create type public.content_status as enum ('draft','needs_review','approved','published','archived','failed'); exception when duplicate_object then null; end $$;
do $$ begin create type public.content_risk_level as enum ('normal','medium','high'); exception when duplicate_object then null; end $$;
do $$ begin create type public.source_link_status as enum ('linked','source_missing','pending_review'); exception when duplicate_object then null; end $$;

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.source_documents (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  language_code text not null default 'sw',
  source_type text not null,
  source_kind text not null default 'document' check (source_kind in ('video','transcript','pdf','document','audio','image')),
  storage_bucket text not null default 'source-documents',
  storage_path text not null,
  file_name text not null,
  checksum text not null,
  processing_status public.content_status not null default 'draft',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (storage_bucket, storage_path)
);

drop trigger if exists set_source_documents_updated_at on public.source_documents;
create trigger set_source_documents_updated_at
before update on public.source_documents
for each row execute function public.set_updated_at();

create table if not exists public.courses (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  title_sw text not null,
  language_code text not null default 'sw',
  status public.content_status not null default 'draft',
  risk_level public.content_risk_level not null default 'normal',
  import_source text not null default 'manual',
  external_id text,
  source_reference text,
  source_link_status public.source_link_status not null default 'pending_review',
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_courses_updated_at on public.courses;
create trigger set_courses_updated_at
before update on public.courses
for each row execute function public.set_updated_at();

create table if not exists public.course_modules (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  code text not null,
  title_sw text not null,
  status public.content_status not null default 'draft',
  risk_level public.content_risk_level not null default 'normal',
  import_source text not null default 'manual',
  external_id text,
  source_reference text,
  source_link_status public.source_link_status not null default 'pending_review',
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (course_id, code)
);

drop trigger if exists set_course_modules_updated_at on public.course_modules;
create trigger set_course_modules_updated_at
before update on public.course_modules
for each row execute function public.set_updated_at();

create table if not exists public.lessons (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references public.course_modules(id) on delete cascade,
  code text not null,
  title_sw text not null,
  body_sw text,
  lesson_type text not null default 'reading' check (lesson_type in ('reading','video','pdf','checklist','quiz','practical_task','audio')),
  status public.content_status not null default 'draft',
  risk_level public.content_risk_level not null default 'normal',
  import_source text not null default 'manual',
  external_id text,
  source_reference text,
  source_link_status public.source_link_status not null default 'pending_review',
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (module_id, code)
);

drop trigger if exists set_lessons_updated_at on public.lessons;
create trigger set_lessons_updated_at
before update on public.lessons
for each row execute function public.set_updated_at();

create table if not exists public.learning_paths (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  title_sw text not null,
  status public.content_status not null default 'draft',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_learning_paths_updated_at on public.learning_paths;
create trigger set_learning_paths_updated_at
before update on public.learning_paths
for each row execute function public.set_updated_at();

create table if not exists public.learning_path_courses (
  id uuid primary key default gen_random_uuid(),
  learning_path_id uuid not null references public.learning_paths(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  sort_order integer not null default 0,
  required boolean not null default true,
  created_at timestamptz not null default now(),
  unique (learning_path_id, course_id)
);

create table if not exists public.curriculum_import_batches (
  id uuid primary key default gen_random_uuid(),
  import_source text not null default 'notebooklm',
  batch_hash text not null unique,
  file_name text,
  row_count integer not null default 0,
  valid_count integer not null default 0,
  error_count integer not null default 0,
  status public.content_status not null default 'draft',
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

create table if not exists public.curriculum_staging_rows (
  id uuid primary key default gen_random_uuid(),
  batch_id uuid not null references public.curriculum_import_batches(id) on delete cascade,
  row_number integer not null,
  external_row_id text,
  item_type text not null,
  row_data jsonb not null default '{}'::jsonb,
  validation_status text not null default 'valid' check (validation_status in ('valid','invalid','promoted')),
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

drop trigger if exists set_curriculum_staging_rows_updated_at on public.curriculum_staging_rows;
create trigger set_curriculum_staging_rows_updated_at
before update on public.curriculum_staging_rows
for each row execute function public.set_updated_at();

create table if not exists public.content_source_assets (
  id uuid primary key default gen_random_uuid(),
  content_type text not null check (content_type in ('course','module','lesson','checklist','quiz_question','faq_entry')),
  content_id uuid not null,
  source_document_id uuid not null references public.source_documents(id) on delete restrict,
  link_status public.source_link_status not null default 'pending_review',
  evidence_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (content_type, content_id, source_document_id)
);

drop trigger if exists set_content_source_assets_updated_at on public.content_source_assets;
create trigger set_content_source_assets_updated_at
before update on public.content_source_assets
for each row execute function public.set_updated_at();

create table if not exists public.lesson_resources (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  resource_type text not null check (resource_type in ('video','transcript','pdf','audio','image')),
  storage_path text,
  external_url text,
  title_sw text not null,
  duration_seconds integer,
  transcript_source_document_id uuid references public.source_documents(id) on delete set null,
  status public.content_status not null default 'draft',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (lesson_id, resource_type, title_sw)
);

drop trigger if exists set_lesson_resources_updated_at on public.lesson_resources;
create trigger set_lesson_resources_updated_at
before update on public.lesson_resources
for each row execute function public.set_updated_at();;
