begin;

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000001","app_metadata":{"role":"learner"}}', true);
set local role authenticated;

do $$
begin
  perform 1 from public.courses limit 1;
  raise exception 'Learner can read curriculum tables directly';
exception
  when insufficient_privilege then null;
end $$;

reset role;

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000002","app_metadata":{"role":"editor"}}', true);
set local role authenticated;

do $$
begin
  perform 1 from public.lessons limit 1;
  raise exception 'Editor can bypass the API and read curriculum directly';
exception
  when insufficient_privilege then null;
end $$;

rollback;
