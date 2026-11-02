-- 媽咪樂駐點經理案例雲端：Supabase SQL Editor 執行
create table if not exists public.manager_roles (
 user_id uuid primary key references auth.users(id) on delete cascade,
 role text not null check (role in ('manager','supervisor')),
 created_at timestamptz not null default now()
);
create table if not exists public.manager_cases (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
 topic text not null check(topic in ('721','假','薪水','工具','方法','意願','客戶預告','其他')),
 title text not null,
 case_details text not null default '',
 attendance_note text not null default '',
 renewal_note text not null default '',
 salary_note text not null default '',
 manager_script text not null default '',
 employee_intent text not null default '',
 employee_deadline text not null default '',
 manager_resources text not null default '',
 employee_actions text not null default '',
 evidence text not null default '',
 status text not null default '待處理' check(status in ('待處理','進行中','待驗收','已完成')),
 due_date date,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists manager_cases_owner_idx on public.manager_cases(owner_id);
create index if not exists manager_cases_status_idx on public.manager_cases(status);
alter table public.manager_roles enable row level security;
alter table public.manager_cases enable row level security;
revoke all on public.manager_roles from anon;
revoke all on public.manager_cases from anon;
grant select on public.manager_roles to authenticated;
grant select,insert,update,delete on public.manager_cases to authenticated;
create or replace function public.is_supervisor() returns boolean
language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.manager_roles where user_id=auth.uid() and role='supervisor')
$$;
revoke all on function public.is_supervisor() from public;
grant execute on function public.is_supervisor() to authenticated;
drop policy if exists "read own role" on public.manager_roles;
create policy "read own role" on public.manager_roles for select to authenticated using(user_id=auth.uid());
drop policy if exists "read own or supervisor" on public.manager_cases;
create policy "read own or supervisor" on public.manager_cases for select to authenticated using(owner_id=auth.uid() or public.is_supervisor());
drop policy if exists "insert own" on public.manager_cases;
create policy "insert own" on public.manager_cases for insert to authenticated with check(owner_id=auth.uid());
drop policy if exists "update own" on public.manager_cases;
create policy "update own" on public.manager_cases for update to authenticated using(owner_id=auth.uid()) with check(owner_id=auth.uid());
drop policy if exists "delete own" on public.manager_cases;
create policy "delete own" on public.manager_cases for delete to authenticated using(owner_id=auth.uid());
-- 安全地設定督導：先由 Supabase Authentication 建立/邀請督導帳號，再在 SQL Editor 執行：
-- insert into public.manager_roles(user_id,role) values ('督導帳號的 auth.users.id','supervisor')
-- on conflict(user_id) do update set role='supervisor';
-- 請勿把 service_role 金鑰寫進 GitHub 或網頁。