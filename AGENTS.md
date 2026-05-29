# AGENTS.md

Orientation for any AI agent (or human) starting fresh on this repo.
Read this first. For setup commands see [README.md](README.md); for the
architecture rules see [.cursor/rules/instructions.md](.cursor/rules/instructions.md).

## What this app is

A community forum for **parents and caregivers of people with
disabilities** (autism, Down's syndrome, cerebral palsy, IEP/school
navigation, siblings, etc.). Think **Reddit / What To Expect**: a list
of communities, each with a feed of posts, each post a thread of
comments with likes.

## Who it's for (this drives UX decisions)

The audience is often **tired, stressed caregivers**. Bias every product
and copy decision toward: calm, plain language, accessible, low-friction,
never clever-but-confusing. Error messages are reassuring and actionable,
not technical (see `AppError.userMessage` and the humanized auth
messages in [lib/src/core/error/app_error.dart](lib/src/core/error/app_error.dart)).

## Platform targets (IMPORTANT — some older docs are stale)

- **iOS first** — this is the current, active target.
- **Android after iOS** — supported in code, shipped second.
- **Never web, never desktop.** The web/desktop folders are
  auto-generated leftovers; we do not ship them.
- Despite "no web," the UI is still **responsive** because an iPad in
  landscape gets the wide (desktop-style) layout. Responsiveness is
  about screen width, not platform.

Stale references to "Web-first" in
[.cursor/rules/instructions.md](.cursor/rules/instructions.md) and
[Notes.md](Notes.md) predate this decision — treat THIS file as
authoritative.

Portability rules so "iOS now" never becomes "iOS only":
- Never import `dart:html` or web-only packages. Use cross-platform
  Flutter plugins (e.g. `file_picker`) so 100% of the code still
  compiles on iOS and Android.
- Use `LayoutBuilder` / `ResponsiveLayout` for layout ("show a
  sidebar?"). Use `Platform`/`defaultTargetPlatform` only for genuine
  OS-specific behavior (e.g. Cupertino vs Material icons), never for
  layout density.

## Access model (Reddit-style)

- **Anyone can browse without signing in** — communities, feeds, and
  threads are public read.
- **Writing requires sign-in** — posting, commenting, and liking are
  gated. The UI prompts guests with a "sign in to join" sheet; the DB
  enforces it via `to authenticated` RLS on all writes.
- (This open-browse model is being rolled out; see the active plan and
  [plans_from_ai.md](plans_from_ai.md) for deferred backend hardening.)

## Tech stack

- **Flutter** + Dart.
- **Backend: Supabase** (Postgres + Row-Level Security + Auth +
  Storage). Migrations are committed under `supabase/migrations/`. The
  app talks to it with the anon key via `--dart-define-from-file`.
- **Auth**: magic link (primary), Google OAuth, Apple Sign-In (iOS,
  required by App Store guideline 4.8 since we offer Google).
- **State management**: `flutter_bloc` — `Cubit` by default, full `Bloc`
  only for `AuthBloc` (auth is a genuine state machine).
- **Routing**: `go_router` with deep-link support (magic-link / OAuth
  callbacks return via `flutterposts://auth-callback`).
- **Offline dev mode**: when Supabase env vars are absent, the app wires
  in-memory fake repositories and shows an "OFFLINE DEV" banner, so the
  UI runs with no backend. Selection logic is in
  [lib/src/app.dart](lib/src/app.dart).

## Architecture (feature-first + repository pattern)

- Code is organized by feature under `lib/src/features/` (`auth`,
  `forum`, `me`), with cross-cutting plumbing in `lib/src/core/`.
- **Layer rule (load-bearing):** only `<feature>/data/` may import
  `supabase_flutter`. Cubits/Blocs and widgets talk to the repository
  *interfaces* and never see Supabase/PostgREST types. Every repository
  has a Supabase impl and an in-memory impl behind one interface.
- Full directory map is in [README.md](README.md).

## UI conventions

- Lists (feeds, communities, comments) are **edge-to-edge rows separated
  by 1px dividers**, not floating rounded cards (Reddit/WTE look).
- Theme is mint primary + slate neutrals, explicit `ColorScheme` (not
  `fromSeed`), flat surfaces. See
  [lib/src/core/theme/app_theme.dart](lib/src/core/theme/app_theme.dart).
- Prefer `const` `StatelessWidget`s; use `context.push()` for drill-down
  navigation to keep the back-stack clean (see
  [NavigationRules.md](NavigationRules.md)).
- Comment intent generously, especially block comments above functions
  (house style).

## Key reference docs

- [README.md](README.md) — setup, quick start, directory structure, native prereqs.
- [SupabaseSetup.md](SupabaseSetup.md) — Supabase project walkthrough.
- [NavigationRules.md](NavigationRules.md) — routing / back-stack rules.
- [BEFORE_SHIPPING.md](BEFORE_SHIPPING.md) — release checklist (bundle IDs, Apple setup).
- [plans_from_ai.md](plans_from_ai.md) — deferred backend/infra hardening TODOs.
- [.cursor/rules/instructions.md](.cursor/rules/instructions.md) — coding rules (note the stale "web-first" line).

## Verify changes

```bash
flutter analyze
flutter test
```

## Out of scope for v1

Monetization, web/desktop shipping, realtime updates, push
notifications, search, and moderation tooling are all deferred.
