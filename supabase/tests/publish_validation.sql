begin;

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000003","app_metadata":{"role":"admin"}}', true);
set local role authenticated;

insert into public.source_documents (
  title,
  source_type,
  storage_path,
  file_name,
  checksum,
  page_count,
  processing_status
)
values (
  'Jaribio la PDF',
  'pdf',
  'tests/jaribio.pdf',
  'jaribio.pdf',
  'checksum-test',
  2,
  'approved'
)
returning id \gset

insert into public.source_segments (
  source_document_id,
  page_start,
  page_end,
  section_title,
  segment_order,
  content_sw,
  content_hash,
  extraction_method,
  review_status,
  risk_level
)
values (
  :'id',
  1,
  1,
  'Utangulizi',
  1,
  'Andaa shamba la mpunga kwa kufuata ushauri wa mtaalamu.',
  'segment-hash-test',
  'test',
  'approved',
  'normal'
)
returning id as segment_id \gset

insert into public.courses (code, title_sw, status, source_link_status)
values ('publish-test-course', 'Publish Test Course', 'approved', 'source_missing')
returning id as course_id \gset

insert into public.course_modules (course_id, code, title_sw, status, source_link_status)
values (:'course_id', 'publish-test-module', 'Publish Test Module', 'approved', 'source_missing')
returning id as module_id \gset

insert into public.lessons (
  module_id,
  code,
  title_sw,
  body_sw,
  status,
  risk_level,
  source_link_status
)
values (
  :'module_id',
  'publish-test-lesson',
  'Publish Test Lesson',
  'Lesson without linked evidence.',
  'approved',
  'normal',
  'source_missing'
)
returning id as lesson_id \gset

do $$
declare
  report jsonb;
  test_course_id uuid;
begin
  select id into test_course_id from public.courses where code = 'publish-test-course';
  report := public.publish_course(test_course_id);
  if (report ->> 'published')::boolean then
    raise exception 'Course published despite missing lesson source link';
  end if;
end $$;

insert into public.content_source_links (
  content_type,
  content_id,
  source_segment_id,
  source_document_id,
  link_status
)
values ('lesson', :'lesson_id', :'segment_id', :'id', 'linked');

update public.lessons
set risk_level = 'high', status = 'needs_review'
where id = :'lesson_id';

do $$
declare
  report jsonb;
  test_course_id uuid;
begin
  select id into test_course_id from public.courses where code = 'publish-test-course';
  report := public.publish_course(test_course_id);
  if (report ->> 'published')::boolean then
    raise exception 'Course published despite high-risk content needing review';
  end if;
end $$;

update public.lessons
set status = 'approved'
where id = :'lesson_id';

do $$
declare
  report jsonb;
  test_course_id uuid;
begin
  select id into test_course_id from public.courses where code = 'publish-test-course';
  report := public.publish_course(test_course_id);
  if not (report ->> 'published')::boolean then
    raise exception 'Course did not publish after source and risk checks passed: %', report;
  end if;
end $$;

rollback;
