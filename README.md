# flutter_posts

A forum app for parents and caregivers of people with disabilities.

- **v1 platforms**: native iOS + Android. Web/desktop targets exist but
  aren't shipped (folders left auto-generated for future re-targeting).
- **Backend**: Supabase (Postgres + RLS + Auth + Storage). Migrations
  are committed under `supabase/migrations/` — `pg_dump` portable.
- **Auth**: magic link (primary), Google OAuth, Apple Sign-In (iOS).
- **State management**: `flutter_bloc` (Cubit by default, full Bloc for
  `AuthBloc`).

For the architectural reasoning behind these choices and the file
structure, see `Notes.md` and the original implementation plan.

---

## Quick start (after prereqs below are done)

```bash
# 1. Install deps.
flutter pub get

# 2. Copy the env template and fill in your Supabase project values.
cp .env.json.example .env.json
$EDITOR .env.json    # paste in SUPABASE_URL + SUPABASE_ANON_KEY

# 3. Apply migrations to your Supabase project.
cd supabase && supabase db push   # or `supabase db reset` against a local

# 4. Run the app.
flutter run --dart-define-from-file=.env.json
```

Detailed Supabase setup walkthrough lives in [`SupabaseSetup.md`](SupabaseSetup.md).

---

## Native mobile prerequisites

These are NOT code changes — they're manual setup steps that block
running on real devices or submitting to the stores. Do them once.

### 1. Apple Developer Program ($99/year)

Required for:
- Running on a real iPhone for > 7 days.
- Enabling the "Sign In with Apple" capability in Xcode.
- Submitting to the App Store.

Sign up at <https://developer.apple.com/programs/>.

### 2. Google Play Console ($25 one-time)

Required for submitting to the Play Store. Sign up at
<https://play.google.com/console/signup>.

### 3. Google Cloud Console OAuth client IDs

For the Supabase-mediated browser-based Google sign-in flow, you need
OAuth client IDs registered with Google Cloud:

1. <https://console.cloud.google.com/> → create a project.
2. APIs & Services → OAuth consent screen → fill out (External, app
   name, support email, dev contact).
3. APIs & Services → Credentials → "+ Create credentials" → OAuth
   client ID:
   - One **iOS** client: bundle ID = `com.example.flutter_posts`
     (or whatever you set in Xcode).
   - One **Android** client: package name = `com.example.flutter_posts`
     + SHA-1 fingerprint of your signing cert (`./gradlew signingReport`
     from `android/`).
   - One **Web** client (used by Supabase to broker the OAuth handshake):
     authorized redirect URI = `https://<project-ref>.supabase.co/auth/v1/callback`.

4. In the Supabase dashboard: Authentication → Providers → Google →
   paste the Web client's `client_id` and `client_secret`. Save.

Per the plan, v1 uses Supabase's browser-based OAuth (`signInWithOAuth`)
which only needs the Supabase-side configuration. The native iOS/Android
client IDs are required when we upgrade to the `google_sign_in`
package for a smoother UX (v1.1 work).

### 4. Apple Sign-In Xcode capability

Already required because we ship Google Sign-In (App Store Guideline 4.8).
Steps:

1. Open `ios/Runner.xcworkspace` (NOT `Runner.xcodeproj`).
2. Select the Runner target → Signing & Capabilities tab.
3. Click **"+ Capability"** → **"Sign In with Apple"**.
4. Xcode will add `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements`
   to the project. That file is already checked in.
5. Verify the capability was added: rebuild and try the "Continue with
   Apple" button in the app.

Then in the Supabase dashboard:
- Authentication → Providers → Apple → enable.
- Provide the Service ID, Team ID, and Key from Apple Developer
  portal → Keys (create a "Sign In with Apple" key).

### 5. Supabase Auth redirect URL

In the Supabase dashboard:
- Authentication → URL Configuration → "Redirect URLs":
- Add `flutterposts://auth-callback`.

This is the URL the magic-link emails + OAuth redirects link to, which
the OS deep-links back into the app. The deep-link wiring lives in:
- `ios/Runner/Info.plist` → `CFBundleURLTypes` (committed).
- `android/app/src/main/AndroidManifest.xml` → `<intent-filter>` (committed).
- `lib/src/bootstrap.dart` → URI listener (committed).

### 6. App icons + splash screen

Source images are NOT committed yet — drop them in and run the
generators when ready. See [`assets/branding/README.md`](assets/branding/README.md).

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

---

## Directory structure

```
lib/
├── main.dart                        # entry point
├── src/
│   ├── app.dart                     # MaterialApp.router + providers
│   ├── bootstrap.dart               # Supabase init, deep-link handler
│   │
│   ├── core/                        # cross-feature plumbing
│   │   ├── env/                     # --dart-define wrapper
│   │   ├── error/                   # AppError + Supabase mapper
│   │   ├── logging/                 # AppBlocObserver
│   │   ├── navigation/              # lightbox controller + history bridge
│   │   ├── routing/                 # go_router config
│   │   ├── theme/                   # AppTheme, ColorScheme, tokens
│   │   └── widgets/                 # ResponsiveLayout + shared atoms
│   │
│   └── features/
│       ├── auth/                    # magic link + OAuth flows
│       │   ├── data/                # AuthRepository (Supabase wrapper)
│       │   ├── domain/              # AuthUser (plain Dart)
│       │   └── presentation/        # AuthBloc, SignInPage, MagicLinkSentPage
│       ├── forum/                   # communities, posts, comments
│       │   ├── data/                # ForumRepository, data models
│       │   └── presentation/
│       │       ├── shell/           # ForumShell + chrome widgets
│       │       ├── feed/            # CommunitiesCubit, FeedCubit, list pages
│       │       └── thread/          # ThreadCubit, thread page
│       └── me/
│           └── presentation/        # MeHomePage, MeSettingsPage
```

Layer rule: only `<feature>/data/` imports `supabase_flutter`. Cubits
and widgets consume the repository APIs and never see Supabase types.

---

## Tests

```bash
flutter test           # unit + widget tests
flutter analyze        # static analysis
```

Test coverage is minimal in v1 — the priority was shipping working
auth + data layer first. The repositories are dependency-injected
(`AuthRepository({SupabaseClient? supabase})` etc.) so they're trivial
to test with a fake Supabase later.

---

## Out of scope for v1

The original plan deferred all monetization, web/desktop targets,
realtime updates, push notifications, search, and moderation tools.
See the plan markdown for the full list and the reasoning.
