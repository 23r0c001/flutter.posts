/// Compile-time environment variables passed via `--dart-define`.
///
/// `String.fromEnvironment` reads values set at compile time, NOT runtime,
/// so these constants can be `const` and tree-shaken by the compiler when
/// not used. They default to empty strings if the `--dart-define` flag
/// is omitted, which is what enables `isConfigured` to gate Supabase
/// initialization in `bootstrap.dart`.
///
/// Usage (preferred — keeps values out of source control):
///   flutter run --dart-define-from-file=.env.json
///   # where .env.json is a gitignored JSON file with the keys below.
///
/// Or one-off:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://abc.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJhbGc...
///
/// IMPORTANT: never commit the actual values. `.env.json` is in
/// `.gitignore`. The `anon` key is safe to embed in the binary (it's
/// the public client key); the `service_role` key NEVER ships in the
/// app — it's a server-only credential.
library;

class Env {
  Env._();

  /// Supabase project URL, e.g. `https://abcdefgh.supabase.co`.
  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL');

  /// Supabase anon (public) API key. Safe to ship in the binary;
  /// Postgres RLS policies are what protect data, NOT key secrecy.
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// True iff both required vars are present at compile time.
  ///
  /// Lets `bootstrap.dart` skip Supabase initialization in dev builds
  /// where env wasn't passed — useful for running the shell/UI without
  /// a working backend in front of you.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Whether Apple Sign-In is enabled in this build.
  ///
  /// Defaults to false because enabling Apple Sign-In requires three
  /// things that aren't free or fast to set up:
  ///   1. An Apple Developer Program enrollment ($99/yr).
  ///   2. A real bundle identifier you own (NOT `com.example.*`).
  ///   3. The `com.apple.developer.applesignin` entitlement enabled
  ///      via Xcode's Signing & Capabilities tab, which writes a
  ///      `Runner.entitlements` file referenced from project.pbxproj.
  ///
  /// Until you've done those, the "Continue with Apple" button is
  /// hidden so a misconfigured build doesn't show a button that
  /// throws at runtime. Flip it on with:
  ///   `--dart-define=ENABLE_APPLE_SIGN_IN=true`
  ///
  /// App Store Guideline 4.8 only requires Apple Sign-In be offered
  /// when your shipped app supports another third-party sign-in
  /// (Google, etc.) — so this gating is fine during dev. Re-enable
  /// it before submitting to TestFlight.
  static const bool appleSignInEnabled = bool.fromEnvironment(
    'ENABLE_APPLE_SIGN_IN',
    defaultValue: false,
  );
}
