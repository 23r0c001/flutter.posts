# Supabase Setup

End-to-end checklist for getting the Supabase side of `flutter_posts` ready. Do this in order. Most steps are dashboard clicks; the database part is copy-pasteable SQL.

This doc assumes you're targeting native iOS + Android (web is dropped for v1) and using the deep-link callback scheme `flutterposts://auth-callback` documented in the main plan.

---

## Part 0 — What you'll have at the end

- A Supabase project with URL + anon key you can plug into the Flutter app via `--dart-define`.
- Auth configured with: magic link (email), Google OAuth, Apple OAuth.
- Six tables (`profiles`, `communities`, `community_members`, `posts`, `comments`, `media`) with row-level security policies.
- A `media` storage bucket.
- A reproducible migration set you can `pg_dump` and walk away with if you ever leave Supabase.

Free tier limits (as of 2026, double-check on [supabase.com/pricing](https://supabase.com/pricing)):

- 50,000 monthly active users
- 500 MB database (this is the one that'll bite first for a forum — comments add up)
- 5 GB bandwidth/month
- 1 GB file storage, 50 MB max per file
- 7-day backup retention
- Project pauses after 1 week of inactivity (just visit the dashboard to wake it)

---

## Part 1 — Create the project

1. Go to [supabase.com](https://supabase.com) and sign up (GitHub login is easiest).
2. Dashboard → **New project**:
   - **Name**: `flutter-posts` (or whatever; only you see this).
   - **Database password**: generate a strong one and save it to your password manager. You'll need this for `pg_dump` and SQL access later.
   - **Region**: pick the one geographically closest to your users. For US: `us-east-1` is safe. For mixed audience: `us-east-1`. Hard to change later without a project migration.
   - **Plan**: Free.
3. Wait ~2 minutes for provisioning.
4. Once it's up, go to **Settings → API** and grab:
   - `Project URL` (looks like `https://abcdefgh.supabase.co`)
   - `anon` `public` key (a long JWT — this is safe to ship in the app)
   - `service_role` `secret` key (NEVER ship this — server-side only, full bypass-RLS power)
5. Save the URL and anon key. You'll feed them to the Flutter app via `--dart-define` (see Part 6).

---

## Part 2 — Auth configuration

All of these live under **Authentication** in the left nav.

### 2a. Site URL + redirect URLs (do this FIRST, everything else depends on it)

**Authentication → URL Configuration**:

- **Site URL**: `flutterposts://auth-callback`
  - This is what Supabase uses as the default redirect when none is specified.
  - You can also point this at a web URL like `https://flutterposts.app` if/when you have one — for now the custom scheme is fine.
- **Redirect URLs** (add each as a separate entry):
  - `flutterposts://auth-callback`
  - `flutterposts://auth-callback/*` (the wildcard catches any sub-path)
  - `http://localhost:*` (helpful for any future dev work; harmless)

Supabase will refuse to redirect to any URL not in this list, which is good security but a common "auth silently doesn't work" cause if you forget to add one.

### 2b. Email (magic link)

**Authentication → Providers → Email**:

- ✅ **Enable Email provider**.
- ✅ **Enable Magic Link sign-in**.
- ❌ Disable "Confirm email" (magic link itself is the confirmation; turning this on creates a confusing double-flow for users).
- ❌ Disable "Enable email + password" (you're not offering password auth).

**Authentication → Email Templates → Magic Link**:

Edit the template. The default is fine for development, but for production you want something warm given the audience. The critical part is the `{{ .ConfirmationURL }}` link — make sure it's prominent. Suggested copy:

```
Subject: Sign in to flutter_posts

Hi,

Tap the button below to sign in. The link expires in 1 hour.

[Sign in] -> {{ .ConfirmationURL }}

If you didn't request this, you can safely ignore this email.
```

**Email rate limits on free tier**: Supabase's built-in SMTP is throttled (~4 emails/hour from the same address in early-2026). Fine for development; for production set up a real SMTP provider. **Authentication → SMTP Settings** — services like [Resend](https://resend.com) (3000 free emails/month) or AWS SES are common. Don't worry about this until you have actual users.

### 2c. Google OAuth

You need a Google Cloud Console OAuth client first.

1. [console.cloud.google.com](https://console.cloud.google.com) → create a new project (or reuse one).
2. **APIs & Services → OAuth consent screen**:
   - User type: **External** (unless you're a Google Workspace org).
   - App name: `flutter_posts`.
   - User support email: yours.
   - Developer contact: yours.
   - Scopes: defaults (`openid`, `email`, `profile`) are enough.
   - Test users: add your own Gmail while in testing mode. (Production verification can come later.)
3. **APIs & Services → Credentials → Create credentials → OAuth client ID**:
   - **Web application** (yes, even for mobile — Supabase brokers the OAuth flow server-side, then redirects back to your app).
   - Name: `flutter_posts (Supabase)`.
   - **Authorized redirect URIs**: add `https://<your-project-ref>.supabase.co/auth/v1/callback` (find this exact URL in Supabase's Google provider settings — it shows you the URL to paste).
   - Save. Copy the **Client ID** and **Client Secret**.
4. Back in Supabase: **Authentication → Providers → Google**:
   - ✅ Enable.
   - Paste **Client ID** and **Client Secret** from step 3.
   - Save.

Native iOS/Android Google Sign-In (using `google_sign_in` package + `signInWithIdToken`) is a v1.1 optimization. For v1 we use Supabase's browser-based OAuth, which doesn't need the iOS/Android-specific OAuth client IDs.

### 2d. Apple OAuth

Requires an [Apple Developer Program](https://developer.apple.com/programs/) account ($99/year). If you don't have one yet, you can skip this section and come back to it in Phase 5 of the main plan.

You'll create three things in Apple Developer portal and paste them into Supabase:

1. **App ID** (Identifiers → App IDs → "+" → App):
   - Bundle ID: `com.yourname.flutterposts` (must match what's in your Xcode project; pick now, hard to change later).
   - Enable **Sign In with Apple** capability.
2. **Services ID** (Identifiers → Services IDs → "+"):
   - Identifier: `com.yourname.flutterposts.auth` (must be different from the App ID).
   - Enable Sign In with Apple, click "Configure":
     - Primary App ID: the App ID from step 1.
     - Domains and Subdomains: `<your-project-ref>.supabase.co`.
     - Return URLs: `https://<your-project-ref>.supabase.co/auth/v1/callback`.
3. **Key** (Keys → "+"):
   - Name: `flutter_posts Sign In with Apple Key`.
   - Enable Sign In with Apple, configure → pick the App ID from step 1.
   - Download the `.p8` file IMMEDIATELY — it can only be downloaded once. Save it somewhere safe.
   - Note the **Key ID** (10 chars).
4. Find your **Team ID** in Apple Developer → top-right corner of the page.

Back in Supabase: **Authentication → Providers → Apple**:

- ✅ Enable.
- **Services ID**: from step 2 (`com.yourname.flutterposts.auth`).
- **Team ID**: from step 4.
- **Key ID**: from step 3.
- **Secret Key**: paste the entire contents of the `.p8` file (including the `-----BEGIN PRIVATE KEY-----` lines).
- Save.

The above is the OAuth web flow (used for Apple Sign-In on Android, and as fallback on iOS). On iOS, you'll *also* use the native Apple Sign-In flow via the `sign_in_with_apple` package and pass the resulting ID token to `supabase.auth.signInWithIdToken(provider: OAuthProvider.apple, ...)`. The Services ID + native flow share the same provider config in Supabase.

---

## Part 3 — Database schema

You can run these via the Supabase **SQL Editor** (left nav → SQL Editor → New query) for now. Once the Supabase CLI is set up (Part 5), save them as numbered files under `supabase/migrations/` so they're reproducible.

Run these in order, one block at a time.

### 3a. Profiles table + auto-create trigger

```sql
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles are readable by anyone signed in"
  on public.profiles for select
  to authenticated
  using (true);

create policy "users can update their own profile"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

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
```

### 3b. Communities + memberships

```sql
create table public.communities (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  description text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create index communities_slug_idx on public.communities (slug);

alter table public.communities enable row level security;

create policy "communities are public-readable to signed-in users"
  on public.communities for select
  to authenticated
  using (true);

create policy "any authenticated user can create a community"
  on public.communities for insert
  to authenticated
  with check (auth.uid() = created_by);

create table public.community_members (
  community_id uuid not null references public.communities(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'member' check (role in ('member', 'mod', 'owner')),
  joined_at timestamptz not null default now(),
  primary key (community_id, user_id)
);

alter table public.community_members enable row level security;

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

create policy "users can join communities themselves"
  on public.community_members for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "users can leave communities themselves"
  on public.community_members for delete
  to authenticated
  using (auth.uid() = user_id);
```

### 3c. Posts + comments

```sql
create table public.posts (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references public.communities(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index posts_community_created_idx on public.posts (community_id, created_at desc) where deleted_at is null;
create index posts_author_idx on public.posts (author_id);

alter table public.posts enable row level security;

create policy "anyone signed in can read non-deleted posts"
  on public.posts for select
  to authenticated
  using (deleted_at is null);

create policy "authors can create their own posts"
  on public.posts for insert
  to authenticated
  with check (auth.uid() = author_id);

create policy "authors can update their own posts"
  on public.posts for update
  to authenticated
  using (auth.uid() = author_id)
  with check (auth.uid() = author_id);

create policy "authors can soft-delete their own posts"
  on public.posts for delete
  to authenticated
  using (auth.uid() = author_id);

create table public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  parent_comment_id uuid references public.comments(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index comments_post_created_idx on public.comments (post_id, created_at) where deleted_at is null;
create index comments_parent_idx on public.comments (parent_comment_id) where deleted_at is null;

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
```

### 3d. Media table

The `media` table is metadata only; actual files live in Supabase Storage (Part 4).

```sql
create table public.media (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  post_id uuid references public.posts(id) on delete cascade,
  storage_path text not null unique,
  mime_type text not null,
  width int,
  height int,
  created_at timestamptz not null default now()
);

create index media_post_idx on public.media (post_id);
create index media_owner_idx on public.media (owner_id);

alter table public.media enable row level security;

create policy "anyone signed in can read media"
  on public.media for select
  to authenticated
  using (true);

create policy "owners can insert media rows"
  on public.media for insert
  to authenticated
  with check (auth.uid() = owner_id);

create policy "owners can delete their media rows"
  on public.media for delete
  to authenticated
  using (auth.uid() = owner_id);
```

### 3e. Seed data (optional, useful for development)

```sql
insert into public.communities (slug, name, description) values
  ('autism-support', 'Autism Support', 'Parents and caregivers of people on the spectrum.'),
  ('downs-community', 'Down''s Community', 'For families of people with Down''s syndrome.'),
  ('cerebral-palsy', 'Cerebral Palsy', 'Resources and conversations for families dealing with CP.'),
  ('intro', 'Welcome', 'Introduce yourself and meet others.');
```

You can re-run this safely; `insert ... on conflict (slug) do nothing` would make it idempotent if you want. For now, just run once.

---

## Part 4 — Storage bucket for media

**Storage → New bucket**:

- **Name**: `media`.
- **Public bucket**: ❌ unchecked (keep private; we'll serve via signed URLs or RLS).
- **File size limit**: `5 MB` (raise later if you add video).
- **Allowed MIME types**: `image/jpeg, image/png, image/webp, image/gif` (add `video/mp4` later if needed).

Then in **Storage → Policies → media → New policy**, add these (replace the default templates):

```sql
create policy "authenticated users can read media"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'media');

create policy "authenticated users can upload to their own folder"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "users can delete their own media"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
```

Upload convention: `media/{user_id}/{uuid}.{ext}`. The policy enforces that users can only upload into their own `{user_id}` folder, which prevents one user from overwriting another's files.

---

## Part 5 — Supabase CLI (local development + migrations)

Once you have the dashboard set up, install the CLI so you can manage migrations as code.

```bash
brew install supabase/tap/supabase
```

Then in the repo root:

```bash
supabase init                                 # creates supabase/ folder
supabase login                                # opens browser, paste access token
supabase link --project-ref <your-project-ref>
supabase db pull                              # pulls the schema you just built into supabase/migrations/
```

After this, the SQL you ran in Part 3 is captured as migration files. Future changes:

```bash
supabase migration new <name>                 # creates a new empty migration file
# edit the file
supabase db push                              # applies to remote
```

For local dev with a local Supabase running in Docker:

```bash
supabase start                                # spins up local stack
supabase db reset                             # blows away local DB and reapplies migrations from scratch
```

Local stack runs at `http://localhost:54321` with its own anon key (printed when you run `supabase status`). Useful for offline dev.

---

## Part 6 — Connecting the Flutter app

The Flutter app will get URL + anon key via `--dart-define` so they're not committed to git.

`.env` file at repo root (gitignored — already in `.gitignore` if it's the default Flutter one):

```bash
SUPABASE_URL=https://<your-project-ref>.supabase.co
SUPABASE_ANON_KEY=<your-anon-key>
```

`lib/src/core/env/env.dart` (created in Phase 1 of the main plan):

```dart
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}
```

Run/build with the values injected:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<your-project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<your-anon-key>
```

For convenience, set up `--dart-define-from-file=.env.json` instead (Flutter 3.7+), with a `.env.json` like:

```json
{
  "SUPABASE_URL": "https://<your-project-ref>.supabase.co",
  "SUPABASE_ANON_KEY": "<your-anon-key>"
}
```

Then just `flutter run --dart-define-from-file=.env.json`. Add `.env.json` to `.gitignore`.

---

## Part 7 — Testing checklist

Tick these off once Part 1-6 are done and Phase 3 of the main plan ships:

- [ ] Dashboard → SQL editor → `select * from auth.users` returns nothing (fresh project).
- [ ] Dashboard → Authentication → Users → manually invite yourself by email → email arrives → click magic link → user appears in `auth.users` AND a row exists in `public.profiles` (the trigger fired).
- [ ] Run app on iOS simulator with `--dart-define`s → "Send magic link" works (email arrives in your inbox).
- [ ] `pg_dump` produces a clean SQL file:
  ```bash
  pg_dump "postgresql://postgres:<password>@db.<your-project-ref>.supabase.co:5432/postgres" \
    --schema=public --no-owner --no-privileges > backup.sql
  ```
  Open `backup.sql` and verify all 6 tables + policies are present. This proves portability — you can restore this into any vanilla Postgres anywhere.
- [ ] Try inserting a post as one user, then attempt to update it as a different user via SQL editor with `set local role authenticated; set local request.jwt.claims to '{"sub": "<other-user-uuid>"}';` — should fail per RLS.

---

## Gotchas you'll hit

- **"Magic link email never arrives"**: check the Supabase free SMTP rate limit (~4/hour same address). Send to a different email or wait. Set up real SMTP for production.
- **"OAuth redirects to a white screen"**: the redirect URL isn't in the allowed list. Go re-check Part 2a.
- **"User signed up but no profile row"**: the `on_auth_user_created` trigger failed silently. Check **Database → Logs** for trigger errors. Common cause: `raw_user_meta_data` not having `full_name`; the `coalesce` in the trigger handles this but verify.
- **"Apple Sign-In errors with `invalid_client`"**: 99% chance the Services ID or Team ID is wrong in Supabase's Apple provider config, or the `.p8` key has extra whitespace. Re-paste it.
- **"My DB hit 500 MB"**: forum content grows fast. Soft-deleted posts/comments still take space. You'll want a periodic vacuum cron or to upgrade. Storage is cheap once you're paying ($25/mo Pro tier gives you 8 GB).
- **Project paused due to inactivity**: just open the dashboard, it un-pauses. Doesn't affect production usage; only fires after a full week of zero traffic.

---

## What's NOT in this doc (deliberately)

- Stripe / payments / IAP — no monetization in v1.
- Push notifications (Supabase doesn't do these directly; use OneSignal or APNs/FCM yourself when the time comes).
- Realtime subscriptions — supported by Supabase out of the box, but not wired in v1.
- Edge Functions — we don't need any for v1; everything is direct client→DB through RLS.
- Custom domain (`db.yourdomain.com` instead of `*.supabase.co`) — Pro tier feature, not relevant pre-launch.
