-- Comment likes.
--
-- One row per (comment, user) like. Composite PK gives us
-- "one like per user per comment" for free without a unique index.
--
-- We denormalize a `like_count` column onto `comments` and keep it
-- in sync via a trigger. The alternative — `count(*)` aggregate on
-- every list query — gets slow as threads grow and forces the UI to
-- either fan-out aggregate calls or hand-write a view. The trigger
-- approach is the standard pattern (Reddit, Discourse, etc.).

create table public.comment_likes (
  comment_id uuid not null references public.comments(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (comment_id, user_id)
);

-- For "which comments did I like?" lookups when rendering a thread.
-- The PK already indexes `(comment_id, user_id)` so per-comment fanout
-- is fast; this secondary index covers the per-user filter we run on
-- the client during `listComments`.
create index comment_likes_user_idx on public.comment_likes (user_id);

-- Denormalized counter. Authoritative source remains `comment_likes`;
-- the trigger below keeps this in sync. `greatest(..., 0)` on decrement
-- defends against drift if the table is ever backfilled by hand.
alter table public.comments
  add column like_count integer not null default 0;

create or replace function public.comment_likes_count_trigger()
returns trigger
language plpgsql
as $$
begin
  if TG_OP = 'INSERT' then
    update public.comments
      set like_count = like_count + 1
      where id = NEW.comment_id;
  elsif TG_OP = 'DELETE' then
    update public.comments
      set like_count = greatest(like_count - 1, 0)
      where id = OLD.comment_id;
  end if;
  return null;
end;
$$;

create trigger comment_likes_count
  after insert or delete on public.comment_likes
  for each row execute function public.comment_likes_count_trigger();

alter table public.comment_likes enable row level security;

-- Anyone signed in can read likes (so we can render counts and "did I
-- like this" indicators). Anonymous users see nothing.
create policy "anyone signed in can read comment likes"
  on public.comment_likes for select
  to authenticated
  using (true);

-- Users can only like as themselves. Combined with the composite PK,
-- this means each user can like a given comment at most once.
create policy "users can like as themselves"
  on public.comment_likes for insert
  to authenticated
  with check (auth.uid() = user_id);

-- Users can only unlike their own likes.
create policy "users can unlike their own likes"
  on public.comment_likes for delete
  to authenticated
  using (auth.uid() = user_id);
