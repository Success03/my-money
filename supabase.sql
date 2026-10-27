-- MY MONEY: Run in your own Supabase project's SQL Editor.
-- This is a private per-user JSON record store, not an open public table.
create table if not exists public.finance_data (
  user_id uuid primary key references auth.users(id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public.finance_data enable row level security;
revoke all on public.finance_data from anon;
grant select, insert, update, delete on public.finance_data to authenticated;

drop policy if exists "User can select own finance data" on public.finance_data;
create policy "User can select own finance data" on public.finance_data
  for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists "User can insert own finance data" on public.finance_data;
create policy "User can insert own finance data" on public.finance_data
  for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists "User can update own finance data" on public.finance_data;
create policy "User can update own finance data" on public.finance_data
  for update to authenticated using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
drop policy if exists "User can delete own finance data" on public.finance_data;
create policy "User can delete own finance data" on public.finance_data
  for delete to authenticated using ((select auth.uid()) = user_id);

create or replace function public.set_finance_data_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end;
$$;
drop trigger if exists finance_data_updated_at on public.finance_data;
create trigger finance_data_updated_at before update on public.finance_data
  for each row execute function public.set_finance_data_updated_at();
