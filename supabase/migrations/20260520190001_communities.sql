-- Communities + community memberships.
--
-- "Communities" are the forum's top-level grouping (Reddit's "subreddits",
-- Discord's "servers"). For the disability-parenting audience these are
-- topics like "autism-support", "down-syndrome", "cerebral-palsy".

create table public.communities (
  id uuid primary key default gen_random_uuid(),
  -- URL-friendly identifier ("autism-support"). Unique so we can route
  -- by slug rather than UUID — better URLs, easier sharing.
  slug text not null unique,
  name text not null,
  description text,
  -- Nullable: if the creator's profile is deleted, keep the community
  -- but null out the credit. Communities outlive their founders.
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

-- Slug lookup is the hot path (every route resolves slug -> community).
create index communities_slug_idx on public.communities (slug);

alter table public.communities enable row level security;

-- All communities are public-readable to signed-in users for v1. When
-- we add private communities, gate this policy on a `visibility` column.
create policy "communities are public-readable to signed-in users"
  on public.communities for select
  to authenticated
  using (true);

-- Any signed-in user can create a community. We may want to throttle
-- this later (max N per user per day) but v1 trusts users.
create policy "any authenticated user can create a community"
  on public.communities for insert
  to authenticated
  with check (auth.uid() = created_by);

-- Community membership.
--
-- Composite PK on (community_id, user_id) so a user can't appear twice
-- in the same community. `role` is text-with-check rather than an enum
-- so we can add new roles via INSERT instead of `alter type`.
create table public.community_members (
  community_id uuid not null references public.communities(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'member' check (role in ('member', 'mod', 'owner')),
  joined_at timestamptz not null default now(),
  primary key (community_id, user_id)
);

alter table public.community_members enable row level security;

-- Members can see the membership of communities they belong to.
-- (Lets them render "12 members" on a community page.)
create policy "members can read membership rows for communities they're in"
  on public.community_members for select
  to authenticated
  using (
    exists (
      select 1 from public.community_members cm
      where cm.community_id = community_members.community_id
        and cm.user_id = auth.uid()
    )
  );

-- Users can join (insert a row for themselves) freely.
create policy "users can join communities themselves"
  on public.community_members for insert
  to authenticated
  with check (auth.uid() = user_id);

-- Users can leave (delete their own membership row).
create policy "users can leave communities themselves"
  on public.community_members for delete
  to authenticated
  using (auth.uid() = user_id);
