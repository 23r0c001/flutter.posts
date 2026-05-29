# Before Shipping

Stuff that's deferred while iterating on UI. None of it blocks running
the app in the iOS Simulator against the in-memory fakes (offline dev
mode). All of it blocks shipping to TestFlight / Play Store.

Tackle roughly in order — earlier items are prerequisites for later
ones.

---

## 1. Pick a bundle identifier you own

**Why deferred:** `flutter create` ships the placeholder
`com.example.flutterPosts`. Xcode's free personal-team signing happily
provisions it onto your own devices for development, so device testing
keeps working. What you CAN'T do with `com.example.*` is:
  - Submit to TestFlight / App Store Connect — Apple rejects it.
  - Enable paid capabilities that require a registered App ID (Sign In
    with Apple, push notifications, iCloud, etc.).

So device testing right now: fine. Anything past that: change the
bundle ID first.

**What to do:**

- Decide on a reverse-DNS bundle ID. Conventional pattern:
  `com.<your-or-company-domain>.flutterposts`, e.g.
  `com.dominiquechilders.flutterposts`. It doesn't need to be a domain
  you actually own, but it should be globally unique — pick something
  recognizable.
- iOS:
  - Open `ios/Runner.xcworkspace` in Xcode.
  - Runner target → General → Identity → Bundle Identifier.
  - Update for Debug, Release, and Profile configurations (Xcode does
    all three when you edit the General tab).
  - Alternatively, find/replace `com.example.flutterPosts` in
    `ios/Runner.xcodeproj/project.pbxproj` (3 occurrences for the
    Runner target, plus 3 for `RunnerTests`).
- Android:
  - Update `applicationId` in `android/app/build.gradle.kts`.
  - Update `package="..."` in
    `android/app/src/main/AndroidManifest.xml` and the Kotlin
    `MainActivity.kt` package declaration. The Android Studio refactor
    tool handles both.
- Update `URL identifier` in `ios/Runner/Info.plist`'s
  `CFBundleURLTypes` to match the new bundle ID convention (cosmetic;
  the `URL Schemes` value `flutterposts` is what actually matters for
  deep links).

---

## 2. Enroll in the Apple Developer Program

**Why deferred:** $99/yr, requires a real person/business identity.
NOT needed for testing on your own devices — Xcode's free personal
team handles that with a 7-day re-signing flow. You only need the paid
Developer Program for:
  - TestFlight / App Store submission.
  - Paid capabilities (Sign In with Apple, push notifications, etc.).
  - Distribution to anyone outside your own devices.

**What to do:**

- <https://developer.apple.com/programs/enroll/>
- Once enrolled, in Xcode → Settings → Accounts, sign in with the same
  Apple ID. Your paid team will appear alongside (or replace) your
  free personal team.
- In the Runner target's Signing & Capabilities tab, switch the team
  to your paid developer team. Automatic signing will then re-issue
  long-lived profiles instead of the 7-day personal-team ones.

---

## 3. Re-enable Apple Sign-In

**Why deferred:** Requires Steps 1 and 2. App Store Guideline 4.8
requires offering Apple Sign-In whenever you offer another social
sign-in (we offer Google), so this is non-optional for store
submission.

**What to do:**

- In Xcode → Runner target → Signing & Capabilities tab:
  - Click "+ Capability" → "Sign In with Apple".
  - Xcode creates `ios/Runner/Runner.entitlements` and adds
    `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements` to
    `project.pbxproj`.
- On the Supabase side: Authentication → Providers → Apple → enable,
  paste your Apple Services ID, Team ID, Key ID, and the contents of
  your `AuthKey_*.p8` file. Full walkthrough in Supabase docs:
  <https://supabase.com/docs/guides/auth/social-login/auth-apple>
- In the running app, pass `--dart-define=ENABLE_APPLE_SIGN_IN=true`
  (e.g., add `"ENABLE_APPLE_SIGN_IN": "true"` to your `.env.json`).
  The "Continue with Apple" button on the sign-in screen will then
  render.
- Verify with `flutter build ios` (no `--no-codesign` this time). If
  Xcode complains about the entitlement, the team + bundle ID +
  capability triplet still has a gap somewhere.

---

## 4. Set up Google OAuth

**Why deferred:** Requires a Google Cloud project — a few minutes of
clickops but unnecessary until you wire up real auth.

**What to do:**

- <https://console.cloud.google.com/> → new project → APIs & Services
  → Credentials → Create OAuth 2.0 Client ID.
- Create THREE client IDs (Google's requirement):
  - **Web** (this is what Supabase actually uses — paste its client
    ID + secret into Supabase Authentication → Providers → Google).
  - **iOS** (bundle ID from Step 1).
  - **Android** (package name + SHA-1 from `keytool`; debug keystore
    SHA-1 works for now, release keystore SHA-1 comes in Step 7).
- Authorized redirect URI in the Web credential's config:
  `https://<your-supabase-ref>.supabase.co/auth/v1/callback`.
- Full walkthrough: <https://supabase.com/docs/guides/auth/social-login/auth-google>

---

## 5. Stand up a Supabase project

**Why deferred:** While in offline dev mode the in-memory fakes serve
the UI. The moment you want real auth or real persistence, you need
the project.

**What to do:**

- <https://supabase.com/dashboard> → new project. Free tier is fine
  for dev.
- Project settings → API → copy the URL and `anon` (public) key into
  `.env.json` (gitignored; template at `.env.json.example`).
- Project settings → Authentication → URL Configuration → add
  `flutterposts://auth-callback` to the allowlist. This is the deep
  link Supabase will redirect magic-link and OAuth callbacks to.
- Apply the schema migrations:
  ```bash
  brew install supabase/tap/supabase   # if not already
  supabase login
  supabase link --project-ref <your-ref>
  supabase db push
  ```
  Details in `supabase/README.md`.
- Run with the new env: `flutter run --dart-define-from-file=.env.json`.
  The "OFFLINE DEV" banner will disappear, signing the real
  `SupabaseAuthRepository` and `SupabaseForumRepository` are in use.

---

## 6. Set up Google Sign-In on Android

**Why deferred:** Google's Android OAuth flow requires a SHA-1
fingerprint of your signing keystore. Until you have a release
keystore (Step 7) you can register the debug keystore's SHA-1, which
is what allows dev builds to do Google sign-in.

**What to do:**

- Get the debug SHA-1:
  ```bash
  keytool -list -v -keystore ~/.android/debug.keystore \
    -alias androiddebugkey -storepass android -keypass android
  ```
- In Google Cloud Console → your Android OAuth client → add that
  SHA-1.
- Add a corresponding entry for your release keystore once Step 7 is
  done.

---

## 7. Generate an Android release keystore + signing config

**Why deferred:** Debug builds (`flutter run`) use the auto-generated
debug keystore. Required for any Play Store upload.

**What to do:**

- Generate the keystore:
  ```bash
  keytool -genkey -v -keystore ~/keys/flutterposts-upload.jks \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -alias upload
  ```
  Store the resulting `.jks` somewhere safe (1Password, etc.). Losing
  it means you can never update the app's listing.
- Create `android/key.properties` (gitignore this!):
  ```
  storePassword=...
  keyPassword=...
  keyAlias=upload
  storeFile=/Users/you/keys/flutterposts-upload.jks
  ```
- Wire it into `android/app/build.gradle.kts` per the Flutter docs:
  <https://docs.flutter.dev/deployment/android#signing-the-app>
- Get the release SHA-1 (`keytool -list -v -keystore ...`) and add it
  to your Google Cloud Console Android OAuth client (from Step 6).

---

## 8. Real app icons + splash screen

**Why deferred:** Both are placeholder files from `flutter create`
right now. App stores reject reviews with default-looking icons.

**What to do:**

- Drop source assets into `assets/branding/`:
  - `app_icon.png` — 1024×1024, opaque, no rounded corners (iOS
    rounds them at the OS level).
  - `splash.png` — your logo on a transparent background, ≥1242×2436.
- Generate platform-specific assets:
  ```bash
  flutter pub run flutter_launcher_icons
  flutter pub run flutter_native_splash:create
  ```
- Both generators are already configured in `pubspec.yaml`. See
  `assets/branding/README.md` for details.

---

## 9. (Optional, for v1.1) Universal Links / App Links

**Why deferred:** Right now we use a custom URL scheme
(`flutterposts://`) for auth callbacks. That works but looks
unprofessional in messages (the deep link is visible as a `flutterposts://`
URL in the magic-link email). Real universal/app links use a normal
https URL that the OS routes to your app.

**What to do:**

- Host an `apple-app-site-association` file at
  `https://<your-domain>/.well-known/apple-app-site-association`.
- Host an `assetlinks.json` at
  `https://<your-domain>/.well-known/assetlinks.json` for Android.
- Update Supabase Authentication → URL Configuration to redirect to
  `https://<your-domain>/auth/callback` instead of
  `flutterposts://auth-callback`.
- Update `ios/Runner/Runner.entitlements` (Step 3) to add the
  Associated Domains capability with `applinks:<your-domain>`.
- Update `android/app/src/main/AndroidManifest.xml` deep-link
  intent-filter to use `android:scheme="https"` and
  `android:host="<your-domain>"` instead of `flutterposts`.

---

## Pre-submission smoke test

When all of the above is done, verify end-to-end before submitting:

- `flutter build ios --release` — completes signed, archives in Xcode.
- `flutter build appbundle --release` — completes, .aab uploads to
  Play Console internal testing.
- Magic link, Google, and Apple sign-in all work on a physical device.
- Posting + commenting persists across app restarts (proves Supabase
  RLS isn't blocking writes).
- Deep links from the magic-link email actually open the app.
