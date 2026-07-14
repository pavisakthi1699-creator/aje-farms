begin;

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000002","app_metadata":{"role":"editor"}}', true);
set local role authenticated;

insert into public.curriculum_import_batches (batch_hash, row_count, valid_count, error_count, status)
values ('test-batch-hash', 2, 1, 1, 'needs_review')
returning id \gset

insert into public.lessons (
  module_id,
  code,
  title_sw,
  body_sw,
  status,
  import_source,
  external_id,
  source_reference,
  source_link_status
)
select
  m.id,
  'notebooklm-test-lesson',
  'Somo la NotebookLM',
  'Hili ni somo la jaribio kutoka NotebookLM.',
  'draft',
  'notebooklm',
  'notebooklm-row-1',
  'NotebookLM: mpunga notes page unknown',
  'source_missing'
from public.course_modules m
join public.courses c on c.id = m.course_id
where c.code = 'kilimo-cha-mpunga-kibiashara'
limit 1;

insert into public.curriculum_import_errors (
  batch_id,
  row_number,
  external_row_id,
  item_type,
  error_code,
  error_message,
  raw_row
)
values (
  :'id',
  2,
  'bad-row',
  'lesson',
  'invalid_row',
  'module_code is required',
  '{"item_type":"lesson"}'
);

do $$
begin
  if not exists (
    select 1 from public.lessons
    where import_source = 'notebooklm'
      and status = 'draft'
      and source_link_status = 'source_missing'
      and source_reference is not null
  ) then
    raise exception 'NotebookLM import contract was not preserved';
  end if;

  if not exists (select 1 from public.curriculum_import_errors where external_row_id = 'bad-row') then
    raise exception 'Import error row was not recorded';
  end if;
end $$;

rollback;
