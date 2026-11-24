-- TaskNest database schema
--
-- Apply this file to a NEW Supabase / PostgreSQL project, for example via the
-- Supabase SQL editor (Dashboard → SQL → New query) or:
--
--   supabase db execute --file db/schema.sql
--
-- NOTE: The original school-demo Supabase project already contains this schema
-- and should NOT be reset/recreated from this file. Use it only to bootstrap a
-- fresh project (see README "Database & Data Layer").

-- The `tasks` table is the single source of truth for the app.
--
-- `user_id` links each task to an authenticated Supabase user. When NULL the
-- task was created by an anonymous (not-signed-in) user and lives only in the
-- local on-device store; once the user signs in, local tasks are uploaded with
-- their `user_id` populated.
create table public.tasks (
  id uuid not null default gen_random_uuid(),
  title text null default ''::text,
  description text null default ''::text,
  completed boolean null,
  created_at timestamp with time zone not null default now(),
  priority text null,
  due_date date null,
  priority_order integer null,
  user_id uuid references auth.users(id) on delete cascade,
  constraint tasks_pkey primary key (id)
);

-- The app sorts by (priority_order, created_at) on every fetch, both ascending.
create index tasks_priority_order_created_at_idx
  on public.tasks (priority_order asc, created_at asc);

-- Index for fast per-user lookups when signed in.
create index tasks_user_id_idx
  on public.tasks (user_id);

-- Row Level Security.
--
-- Two access modes are supported:
--   1. Anonymous (not signed in) — full CRUD on rows where user_id IS NULL.
--      These rows are the local-only tasks; the app keeps them on-device and
--      uploads them on sign-in.
--   2. Authenticated — full CRUD scoped to their own rows (user_id = auth.uid()).
alter table public.tasks enable row level security;

-- Anonymous: read/write only rows that have no owner (local-only tasks).
create policy "Allow anonymous read on own local tasks"
  on public.tasks for select
  to anon
  using (user_id is null);

create policy "Allow anonymous insert of local tasks"
  on public.tasks for insert
  to anon
  with check (user_id is null);

create policy "Allow anonymous update of local tasks"
  on public.tasks for update
  to anon
  using (user_id is null)
  with check (user_id is null);

create policy "Allow anonymous delete of local tasks"
  on public.tasks for delete
  to anon
  using (user_id is null);

-- Authenticated: full CRUD scoped to the signed-in user's own rows.
create policy "Allow authenticated read own tasks"
  on public.tasks for select
  to authenticated
  using (user_id = auth.uid());

create policy "Allow authenticated insert own tasks"
  on public.tasks for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "Allow authenticated update own tasks"
  on public.tasks for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "Allow authenticated delete own tasks"
  on public.tasks for delete
  to authenticated
  using (user_id = auth.uid());