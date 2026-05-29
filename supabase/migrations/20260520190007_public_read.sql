-- Public (anonymous) read access.
--
-- Switches the app from a hard auth wall to a Reddit / What To Expect
-- style model: anyone can BROWSE communities, posts, and comments
-- without signing in. Writing (insert/update/delete) still requires an
-- authenticated session — those policies live in the original feature
-- migrations and are deliberately left untouched here.
--
-- Mechanism: add permissive SELECT policies for the `anon` role next to
-- the existing `authenticated` ones. Postgres ORs permissive policies,
-- so signed-in users are unaffected; anonymous users gain read access.

create policy "communities are public-readable"
  on public.communities for select
  to anon
  using (true);

create policy "posts are public-readable"
  on public.posts for select
  to anon
  using (deleted_at is null);

create policy "comments are public-readable"
  on public.comments for select
  to anon
  using (deleted_at is null);

create policy "profiles are public-readable"
  on public.profiles for select
  to anon
  using (true);

-- DEFENSE-IN-DEPTH for profile data leakage (from AI security review).
--
-- RLS is ROW-level, not COLUMN-level: the policy above would otherwise
-- expose every column of `profiles` to anonymous scrapers. Restrict the
-- `anon` role to exactly the columns the author-join needs. This keeps
-- the existing PostgREST embed working
--   profiles:author_id(id, display_name, avatar_url)
-- (it only requests whitelisted columns) while a direct
--   profiles?select=*
-- from an anonymous client is denied.
--
-- WARNING: never add PII (email, phone, address, ...) to public.profiles.
-- Email already lives in auth.users (never exposed). Put any future
-- private field in a separate owner-RLS table or behind a view.
-- See plans_from_ai.md for the longer-term public/private split.
--
-- `comment_likes` intentionally gets NO anon policy: the client skips the
-- "did I like this" lookup when there's no session (see
-- _fetchLikedCommentIds in supabase_forum_repository.dart), and like
-- counts are read from the denormalized comments.like_count column.
revoke select on public.profiles from anon;
grant select (id, display_name, avatar_url) on public.profiles to anon;
