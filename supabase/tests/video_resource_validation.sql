begin;

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000002","app_metadata":{"role":"editor"}}', true);
set local role authenticated;

insert into public.source_documents (
  title,
  source_type,
  source_kind,
  storage_path,
  file_name,
  checksum,
  processing_status
)
values (
  'Video Validation Source',
  'video',
  'video',
  'tests/video-validation-source.mp4',
  'video-validation-source.mp4',
  'video-validation-source-checksum',
  'draft'
)
returning id as source_document_id \gset

insert into public.courses (code, title_sw, status, source_link_status)
values ('video-validation-course', 'Video Validation Course', 'draft', 'pending_review')
returning id as course_id \gset

insert into public.course_modules (course_id, code, title_sw, status, source_link_status)
values (:'course_id', 'video-validation-module', 'Video Validation Module', 'draft', 'pending_review')
returning id as module_id \gset

insert into public.lessons (
  module_id,
  code,
  title_sw,
  lesson_type,
  status,
  source_link_status,
  import_source
)
values (
  :'module_id',
  'video-validation-lesson',
  'Video Validation Lesson',
  'video',
  'draft',
  'pending_review',
  'notebooklm'
)
returning id as lesson_id \gset

insert into public.lesson_resources (
  lesson_id,
  resource_type,
  title_sw,
  status,
  transcript_source_document_id
)
values (
  :'lesson_id',
  'video',
  'Video Validation Lesson',
  'draft',
  :'source_document_id'
);

insert into public.content_source_assets (
  content_type,
  content_id,
  source_document_id,
  link_status
)
values (
  'lesson',
  :'lesson_id',
  :'source_document_id',
  'pending_review'
);

do $$
begin
  if not exists (
    select 1
    from public.lesson_resources
    where lesson_id = :'lesson_id' and resource_type = 'video'
  ) then
    raise exception 'lesson_resources insert failed';
  end if;

  if not exists (
    select 1
    from public.content_source_assets
    where content_type = 'lesson'
      and content_id = :'lesson_id'
      and link_status = 'pending_review'
  ) then
    raise exception 'content_source_assets insert failed';
  end if;
end $$;

rollback;
