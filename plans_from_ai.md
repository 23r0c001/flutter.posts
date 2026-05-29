# Plans from AI review

Deferred items surfaced during AI security/scaling review. None block the
current "browse without login" work; they are backend / infrastructure
tasks to do when standing up the real Supabase project and/or before
public launch. Ordered roughly by priority.

## Context

Public (anonymous) read access was enabled so guests can browse
communities, feeds, and threads without signing in (Reddit / What To
Expect model). Writes (post / comment / like) still require an
authenticated session, enforced both in the UI (`ensureSignedIn`) and at
the database (`to authenticated` RLS on all insert/update/delete).

What was already handled in code, so it is NOT listed below:

- Read-path indexing — the hot queries are already indexed
  (`posts_community_created_idx`, `comments_post_created_idx`,
  `communities_slug_idx`, `comment_likes_user_idx`).
- Profile column exposure — the public-read migration restricts the
  `anon` role to `(id, display_name, avatar_url)` on `public.profiles`
  via a column-level GRANT, so a future PII column is private-by-default
  to anonymous callers.

---

## TODO (backend / infra)

### 1. Profiles: long-term PII isolation (do before adding ANY private field)

- The column-level GRANT protects the public (`anon`) role, but the
  existing `profiles` RLS still lets **any authenticated user read every
  column of every profile** (`to authenticated using (true)`). If real
  PII (phone, address, DOB) is ever added, it would leak to all logged-in
  users too.
- Proper fix: split public vs private profile data.
  - Option A: a `public_profiles` SQL view exposing only
    `id, display_name, avatar_url`, and point the author-join at it.
    Note: PostgREST FK embedding on a view needs an explicit/computed
    relationship, so the `profiles:author_id(...)` join in
    `supabase_forum_repository.dart` would need updating.
  - Option B: keep public columns in `profiles`, move private columns to
    a separate `profile_private` table with owner-only RLS.
- Until then: **never add PII to `public.profiles`.** (Warning comment is
  in the public-read migration.)

### 2. Server-enforced pagination caps / unbounded queries

- `listComments` fetches all comments for a post with no `LIMIT`
  (pre-existing; affects authenticated and anon equally). A hot thread or
  a scraper can pull large result sets.
- `listPosts` defaults to `limit: 30`, but the cap is applied client-side
  via PostgREST `.limit()`, so a direct API caller can request more.
- Fix options: paginate comments (cursor on `created_at`), and/or move
  reads behind RPCs / a view that enforce a hard server-side max so the
  cap cannot be bypassed by hitting PostgREST directly.

### 3. Rate limiting

- Add rate limiting at the edge (Supabase API gateway / Kong config, or
  Cloudflare in front of the project) to blunt bots hammering public
  endpoints. Anonymous read access widens the unauthenticated surface,
  so this matters more now.

### 4. CDN / edge caching for public reads

- Put a CDN (e.g. Cloudflare) in front of Supabase and cache anonymous
  GET responses for public content (community list, feeds, threads).
  Repeated scrapes of the same post are served from the edge instead of
  hitting Postgres — protects both DB CPU and the plan's bandwidth/quota.
- Requires cache rules keyed on the anon requests (no auth header) with a
  sensible TTL + invalidation story for new posts/comments.

### 5. Abuse / cost monitoring

- Before public launch, add alerting on Supabase egress, request counts,
  and DB CPU so a scraping spike is visible before it becomes a surprise
  bill. (Lower-tier Supabase plans have hard monthly caps.)
