-- Together Couples Planner — Supabase schema
-- Paste the entire file into the Supabase SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.couples (
  id uuid primary key default gen_random_uuid(),
  couple_name text not null default 'Our Couple',
  relationship_start_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  couple_id uuid not null references public.couples(id) on delete cascade,
  display_name text not null default 'Partner',
  created_at timestamptz not null default now()
);

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples(id) on delete cascade,
  title text not null,
  event_date date not null,
  start_time time,
  end_time time,
  category text not null default 'date' check (category in ('date','anniversary','birthday','travel','cinema','dinner','gift','other')),
  location text,
  description text,
  budget numeric(12,2) not null default 0 check (budget >= 0),
  reminder text default 'none' check (reminder in ('none','10m','1h','1d','1w')),
  recurring text default 'none' check (recurring in ('none','weekly','monthly','yearly')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.date_plans (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples(id) on delete cascade,
  title text not null,
  date date not null,
  time time,
  location text,
  description text,
  estimated_budget numeric(12,2) not null default 0 check (estimated_budget >= 0),
  actual_spending numeric(12,2) not null default 0 check (actual_spending >= 0),
  status text not null default 'Planned' check (status in ('Planned','Confirmed','Completed','Cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.date_tasks (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples(id) on delete cascade,
  date_plan_id uuid references public.date_plans(id) on delete set null,
  title text not null,
  completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples(id) on delete cascade,
  name text not null,
  amount numeric(12,2) not null check (amount > 0),
  category text not null default 'Other',
  expense_date date not null,
  related_date_plan_id uuid references public.date_plans(id) on delete set null,
  related_event_id uuid references public.events(id) on delete set null,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.goals (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples(id) on delete cascade,
  title text not null,
  target_amount numeric(12,2) not null check (target_amount > 0),
  current_amount numeric(12,2) not null default 0 check (current_amount >= 0),
  target_date date,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.goal_contributions (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples(id) on delete cascade,
  goal_id uuid not null references public.goals(id) on delete cascade,
  amount numeric(12,2) not null check (amount > 0),
  contributed_on date not null,
  note text,
  created_at timestamptz not null default now()
);

create table if not exists public.memories (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples(id) on delete cascade,
  title text not null,
  memory_date date not null,
  note text,
  image_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.wishlist (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples(id) on delete cascade,
  title text not null,
  category text not null default 'Activity',
  priority text not null default 'Medium' check (priority in ('Low','Medium','High')),
  notes text,
  completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples(id) on delete cascade,
  type text not null default 'reminder',
  title text,
  message text,
  remind_at timestamptz,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

-- Helpful indexes
create index if not exists events_couple_date_idx on public.events(couple_id,event_date);
create index if not exists date_plans_couple_date_idx on public.date_plans(couple_id,date);
create index if not exists expenses_couple_date_idx on public.expenses(couple_id,expense_date);
create index if not exists goals_couple_idx on public.goals(couple_id);
create index if not exists goal_contributions_goal_idx on public.goal_contributions(goal_id);
create index if not exists notifications_couple_remind_idx on public.notifications(couple_id,remind_at);

-- Helper used by RLS. SECURITY DEFINER avoids recursive profile-policy evaluation.
create or replace function public.get_my_couple_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select couple_id from public.profiles where user_id = auth.uid() limit 1;
$$;

revoke all on function public.get_my_couple_id() from public;
grant execute on function public.get_my_couple_id() to authenticated;

-- Create one couple + profile automatically when an Auth user is created.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  new_couple_id uuid;
  c_name text;
  d_name text;
begin
  c_name := coalesce(nullif(new.raw_user_meta_data->>'couple_name',''),'Our Couple');
  d_name := coalesce(nullif(new.raw_user_meta_data->>'display_name',''),'Partner');
  insert into public.couples(couple_name) values(c_name) returning id into new_couple_id;
  insert into public.profiles(user_id,couple_id,display_name) values(new.id,new_couple_id,d_name);
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- RLS
alter table public.couples enable row level security;
alter table public.profiles enable row level security;
alter table public.events enable row level security;
alter table public.date_plans enable row level security;
alter table public.date_tasks enable row level security;
alter table public.expenses enable row level security;
alter table public.goals enable row level security;
alter table public.goal_contributions enable row level security;
alter table public.memories enable row level security;
alter table public.wishlist enable row level security;
alter table public.notifications enable row level security;

-- Policies are intentionally couple-scoped.
drop policy if exists "couples_select" on public.couples;
create policy "couples_select" on public.couples for select to authenticated using (id = public.get_my_couple_id());
drop policy if exists "couples_update" on public.couples;
create policy "couples_update" on public.couples for update to authenticated using (id = public.get_my_couple_id()) with check (id = public.get_my_couple_id());

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles for select to authenticated using (user_id = auth.uid());
drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid() and couple_id = public.get_my_couple_id());

-- Generic policies for all shared tables.
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['events','date_plans','date_tasks','expenses','goals','goal_contributions','memories','wishlist','notifications'] LOOP
    EXECUTE format('drop policy if exists %I_select on public.%I', t, t);
    EXECUTE format('create policy %I_select on public.%I for select to authenticated using (couple_id = public.get_my_couple_id())', t, t);
    EXECUTE format('drop policy if exists %I_insert on public.%I', t, t);
    EXECUTE format('create policy %I_insert on public.%I for insert to authenticated with check (couple_id = public.get_my_couple_id())', t, t);
    EXECUTE format('drop policy if exists %I_update on public.%I', t, t);
    EXECUTE format('create policy %I_update on public.%I for update to authenticated using (couple_id = public.get_my_couple_id()) with check (couple_id = public.get_my_couple_id())', t, t);
    EXECUTE format('drop policy if exists %I_delete on public.%I', t, t);
    EXECUTE format('create policy %I_delete on public.%I for delete to authenticated using (couple_id = public.get_my_couple_id())', t, t);
  END LOOP;
END $$;

-- Delete shared data for the authenticated user. Auth user deletion itself is handled by the optional Edge Function.
create or replace function public.delete_my_couple_data()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare c uuid;
begin
  c := public.get_my_couple_id();
  if c is null then return; end if;
  delete from public.couples where id = c;
end;
$$;
revoke all on function public.delete_my_couple_data() from public;
grant execute on function public.delete_my_couple_data() to authenticated;

-- Storage bucket for optional memory photos.
insert into storage.buckets(id,name,public)
values ('memories','memories',true)
on conflict (id) do nothing;

drop policy if exists "memory_images_select" on storage.objects;
create policy "memory_images_select" on storage.objects for select to authenticated using (bucket_id='memories' and (storage.foldername(name))[1] = public.get_my_couple_id()::text);
drop policy if exists "memory_images_insert" on storage.objects;
create policy "memory_images_insert" on storage.objects for insert to authenticated with check (bucket_id='memories' and (storage.foldername(name))[1] = public.get_my_couple_id()::text);
drop policy if exists "memory_images_delete" on storage.objects;
create policy "memory_images_delete" on storage.objects for delete to authenticated using (bucket_id='memories' and (storage.foldername(name))[1] = public.get_my_couple_id()::text);

-- Enable Realtime on collaborative tables. Each table is guarded independently so rerunning the SQL is safe.
do $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['events','date_plans','date_tasks','expenses','goals','goal_contributions','memories','wishlist','notifications'] LOOP
    BEGIN
      EXECUTE format('alter publication supabase_realtime add table public.%I', t);
    EXCEPTION WHEN duplicate_object THEN
      NULL;
    END;
  END LOOP;
END $$;
