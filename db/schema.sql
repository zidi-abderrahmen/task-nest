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
create table public.tasks (
  id uuid not null default gen_random_uuid(),
  title text null default ''::text,
  description text null default ''::text,
  completed boolean null,
  created_at timestamp with time zone not null default now(),
  priority text null,
  due_date date null,
  priority_order integer null,
  constraint tasks_pkey primary key (id)
);

-- The app sorts by (priority_order, created_at) on every fetch, both ascending.
create index tasks_priority_order_created_at_idx
  on public.tasks (priority_order asc, created_at asc);

-- Row Level Security.
--
-- The app currently performs unauthenticated CRUD against the `tasks` table.
-- These policies match the demo configuration: anonymous read/write so that
-- the client works without auth. This is fine for demo data only — see the
-- README "Performance & Security Considerations" before using real data.
alter table public.tasks enable row level security;

create policy "Allow anonymous read on tasks"
  on public.tasks for select
  to anon
  using (true);

create policy "Allow anonymous insert on tasks"
  on public.tasks for insert
  to anon
  with check (true);

create policy "Allow anonymous update on tasks"
  on public.tasks for update
  to anon
  using (true)
  with check (true);

create policy "Allow anonymous delete on tasks"
  on public.tasks for delete
  to anon
  using (true);