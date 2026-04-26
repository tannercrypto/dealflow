-- ═══════════════════════════════════════════════════════════════
--  AgencyExchange — Supabase Database Schema
--  Paste this entire file into Supabase SQL Editor and click "Run"
-- ═══════════════════════════════════════════════════════════════

-- ─── PIPELINE TABLE ───
-- Stores deals (one row per company a user adds to their pipeline)
create table if not exists public.pipeline (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  company text not null,
  stage text not null default 'prospect',
  deal_value integer default 0,
  expected_close date,
  last_contact date,
  next_step text,
  added_at timestamptz default now() not null,
  updated_at timestamptz default now() not null,
  unique(user_id, company)
);

-- ─── NOTES TABLE ───
-- Stores notes attached to pipeline deals
create table if not exists public.notes (
  id uuid default gen_random_uuid() primary key,
  pipeline_id uuid references public.pipeline(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  author text not null,
  text text not null,
  created_at timestamptz default now() not null
);

-- ─── INDEXES (faster queries) ───
create index if not exists idx_pipeline_user on public.pipeline(user_id);
create index if not exists idx_notes_pipeline on public.notes(pipeline_id);
create index if not exists idx_notes_user on public.notes(user_id);

-- ─── ROW LEVEL SECURITY ───
-- Each user can only see/modify their own data
alter table public.pipeline enable row level security;
alter table public.notes enable row level security;

-- Pipeline policies
drop policy if exists "Users can view own pipeline" on public.pipeline;
create policy "Users can view own pipeline" on public.pipeline
  for select using (auth.uid() = user_id);

drop policy if exists "Users can insert own pipeline" on public.pipeline;
create policy "Users can insert own pipeline" on public.pipeline
  for insert with check (auth.uid() = user_id);

drop policy if exists "Users can update own pipeline" on public.pipeline;
create policy "Users can update own pipeline" on public.pipeline
  for update using (auth.uid() = user_id);

drop policy if exists "Users can delete own pipeline" on public.pipeline;
create policy "Users can delete own pipeline" on public.pipeline
  for delete using (auth.uid() = user_id);

-- Notes policies
drop policy if exists "Users can view own notes" on public.notes;
create policy "Users can view own notes" on public.notes
  for select using (auth.uid() = user_id);

drop policy if exists "Users can insert own notes" on public.notes;
create policy "Users can insert own notes" on public.notes
  for insert with check (auth.uid() = user_id);

drop policy if exists "Users can delete own notes" on public.notes;
create policy "Users can delete own notes" on public.notes
  for delete using (auth.uid() = user_id);

-- ─── AUTO-UPDATE updated_at ───
create or replace function public.touch_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists pipeline_updated_at on public.pipeline;
create trigger pipeline_updated_at
  before update on public.pipeline
  for each row execute function public.touch_updated_at();

-- ═══════════════════════════════════════════════════════════════
--  Done! Your database is ready.
-- ═══════════════════════════════════════════════════════════════
