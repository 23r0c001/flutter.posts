-- Media metadata table.
--
-- Actual file bytes live in Supabase Storage (the `media` bucket
-- configured in the next migration). This table is metadata-only:
-- which user owns each file, what post it's attached to, etc.
--
-- Why a separate `media` row instead of just storing the URL on `posts`?
--   1. Multi-media posts (multiple images per post) without a JSONB blob.
--   2. Orphaned uploads tracking — uploads not yet attached to a post.
--   3. Audit / moderation: when a media row is deleted, the storage
--      file can be cleaned up by a background job querying this table.

create table public.media (
  id uuid primary key default gen_random_uuid(),
  -- Owner is who uploaded it. Different from post.author_id when an
  -- admin uploads media on behalf of another user (rare; v1 = same).
  owner_id uuid not null references public.profiles(id) on delete cascade,
  -- Nullable: media uploaded before being attached to a post has null.
  post_id uuid references public.posts(id) on delete cascade,
  -- The path within the Supabase Storage `media` bucket. Unique because
  -- two media rows shouldn't point at the same physical file.
  -- Convention: "<owner_id>/<uuid>.<ext>".
  storage_path text not null unique,
  mime_type text not null,
  width int,
  height int,
  created_at timestamptz not null default now()
);

create index media_post_idx on public.media (post_id);
create index media_owner_idx on public.media (owner_id);

alter table public.media enable row level security;

-- Authenticated users can read any media metadata. (Actual file access
-- is gated by Storage policies in the next migration.)
create policy "anyone signed in can read media"
  on public.media for select
  to authenticated
  using (true);

-- Owners insert their own rows. The owner is implicitly the user who
-- did the upload via the Flutter SDK.
create policy "owners can insert media rows"
  on public.media for insert
  to authenticated
  with check (auth.uid() = owner_id);

-- Owners delete their own rows.
create policy "owners can delete their media rows"
  on public.media for delete
  to authenticated
  using (auth.uid() = owner_id);
