create table if not exists public.app_settings (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.app_settings enable row level security;

drop policy if exists deny_direct_client_access on public.app_settings;
create policy deny_direct_client_access on public.app_settings
  for all to public
  using (false)
  with check (false);

insert into public.app_settings (key, value)
values (
  'home_topics',
  '["Matunda na Mbogamboga", "Nafaka", "Mifugo", "Mengineyo"]'::jsonb
)
on conflict (key) do nothing;
