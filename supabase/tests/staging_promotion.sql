begin;

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000002","app_metadata":{"role":"editor"}}', true);
set local role authenticated;

insert into public.curriculum_import_batches (batch_hash, row_count, valid_count, error_count, status)
values ('staging-test-batch', 1, 1, 0, 'approved')
returning id \gset

insert into public.curriculum_staging_rows (
  batch_id,
  row_number,
  external_row_id,
  item_type,
  row_data,
  validation_status
)
values (
  :'id',
  1,
  'staging-course-1',
  'course',
  '{"item_type":"course","code":"staging-course-code","title_sw":"Staging Course"}',
  'valid'
);

do $$
begin
  if not exists (
    select 1
    from public.curriculum_staging_rows
    where external_row_id = 'staging-course-1'
      and validation_status = 'valid'
  ) then
    raise exception 'Staging row was not inserted correctly';
  end if;

  if exists (select 1 from public.courses where code = 'staging-course-code') then
    raise exception 'Live courses should not change before promotion';
  end if;
end $$;

rollback;
