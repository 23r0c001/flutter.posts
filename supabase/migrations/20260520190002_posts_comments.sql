-- Posts and comments.
--
-- Posts belong to a community + author. Comments belong to a post +
-- author, with an optional `parent_comment_id` for threading (Reddit-
-- style nested replies). `deleted_at` is nullable for SOFT deletes so
-- thread structure isn't broken when a parent comment is removed.

create table public.posts (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references public.communities(id) on delete cascade,
  -- Author FKs to profiles (not auth.users) so we can join cleanly to
  -- the display_name without going through the privileged auth schema.
  author_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- Soft delete. NULL = active, set to timestamp on delete.
  deleted_at timestamptz
);

-- Hot path: render a community feed sorted by recency, excluding deleted.
-- Partial index on `deleted_at is null` is much smaller than full index,
-- since the deleted set should be a tiny minority.
create index posts_community_created_idx
  on public.posts (community_id, created_at desc)
  where deleted_at is null;

-- For "my posts" / profile pages.
create index posts_author_idx on public.posts (author_id);

alter table public.posts enable row level security;

-- Anyone signed in reads non-deleted posts. Anonymous users see nothing.
create policy "anyone signed in can read non-deleted posts"
  on public.posts for select
  to authenticated
  using (deleted_at is null);

-- Authors can create their own posts.
create policy "authors can create their own posts"
  on public.posts for insert
  to authenticated
  with check (auth.uid() = author_id);

-- Authors can edit their own posts. (We may want a 1-hour edit window
-- later; for v1, no time limit.)
create policy "authors can update their own posts"
  on public.posts for update
  to authenticated
  using (auth.uid() = author_id)
  with check (auth.uid() = author_id);

-- "Delete" here means we let the author DELETE — but in practice the
-- app should issue an UPDATE setting `deleted_at = now()` (soft delete).
-- This policy is defense-in-depth in case a hard delete slips through.
create policy "authors can soft-delete their own posts"
  on public.posts for delete
  to authenticated
  using (auth.uid() = author_id);

-- Comments.
create table public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  -- Self-referential FK for threading. Top-level comments have null parent.
  -- `on delete cascade` so deleting a parent removes the subtree.
  parent_comment_id uuid references public.comments(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

-- Hot path: render a thread's comments sorted by recency.
create index comments_post_created_idx
  on public.comments (post_id, created_at)
  where deleted_at is null;

-- For rendering a parent's replies efficiently.
create index comments_parent_idx
  on public.comments (parent_comment_id)
  where deleted_at is null;

alter table public.comments enable row level security;

create policy "anyone signed in can read non-deleted comments"
  on public.comments for select
  to authenticated
  using (deleted_at is null);

create policy "authors can create their own comments"
  on public.comments for insert
  to authenticated
  with check (auth.uid() = author_id);

create policy "authors can update their own comments"
  on public.comments for update
  to authenticated
  using (auth.uid() = author_id)
  with check (auth.uid() = author_id);

create policy "authors can soft-delete their own comments"
  on public.comments for delete
  to authenticated
  using (auth.uid() = author_id);
