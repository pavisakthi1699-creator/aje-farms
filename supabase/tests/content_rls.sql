begin;

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000001","app_metadata":{"role":"learner"}}', true);
set local role authenticated;

do $$
begin
  if exists (select 1 from public.courses where status <> 'published') then
    raise exception 'Learner can read non-published courses';
  end if;

  if exists (select 1 from public.source_segments) then
    raise exception 'Learner can read source segments';
  end if;

  if exists (select 1 from public.curriculum_import_batches) then
    raise exception 'Learner can read import batches';
  end if;
end $$;

reset role;

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000002","app_metadata":{"role":"editor"}}', true);
set local role authenticated;

do $$
begin
  if not exists (select 1 from public.courses where code = 'kilimo-cha-mpunga-kibiashara') then
    raise exception 'Editor cannot read draft seed course';
  end if;
end $$;

rollback;
