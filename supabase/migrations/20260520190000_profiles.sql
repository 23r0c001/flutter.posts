-- Profiles table.
--
-- One row per `auth.users` row; created automatically by the trigger
-- below when a user signs up (via magic link, OAuth, etc.). Holds the
-- public-facing user info we want to be able to read without touching
-- the privileged `auth.users` table.
--
-- `id` is a FK to `auth.users(id)` with `on delete cascade`, so deleting
-- a Supabase user automatically removes their profile.

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- RLS is OFF by default in Postgres — explicitly enable it per table.
-- Forgetting this is the #1 Supabase footgun.
alter table public.profiles enable row level security;

-- Anyone authenticated can read profiles (we need to render display names
-- next to posts/comments). Anonymous users can't read anything.
create policy "profiles are readable by anyone signed in"
  on public.profiles for select
  to authenticated
  using (true);

-- Users can only update their own profile row.
create policy "users can update their own profile"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Trigger function: insert a profile row whenever a user is created
-- in `auth.users`. Uses `security definer` so it runs with the table
-- owner's privileges (necessary because `authenticated` users don't
-- have direct insert access to `public.profiles`).
--
-- Pulls `display_name` from `raw_user_meta_data.full_name` (set by
-- Google / Apple OAuth), falling back to the local part of the email
-- for magic-link signups.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    new.raw_user_meta_data->>'avatar_url'
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
