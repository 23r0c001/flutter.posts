import 'package:app_links/app_links.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/env/env.dart';
import 'core/logging/app_bloc_observer.dart';

/// One-shot app startup.
///
/// Responsibilities:
///   1. Initialize the Flutter binding (required before any async work
///      that touches platform channels).
///   2. Install the global `AppBlocObserver` (logs every Bloc/Cubit
///      state transition in debug builds).
///   3. Initialize Supabase IF env is configured. We skip when env is
///      missing so the UI shell still runs in dev without a backend.
///   4. Subscribe to `AppLinks().uriLinkStream` to receive deep-link
///      callbacks from the OAuth / magic-link redirect, and hand them
///      off to `Supabase.instance.client.auth.getSessionFromUrl`. The
///      resulting session change comes back through the
///      `onAuthStateChange` stream and into `AuthBloc`.
///   5. Hand off to the widget tree via `runApp(MyApp())`.
///
/// Why a separate file from `main.dart`? Two reasons:
///   - Keeps `main.dart` tiny and obvious ("run the bootstrap, then the app").
///   - Lets us write integration tests that call `bootstrap()` directly
///     after overriding env / clients.
Future<void> bootstrap() async {
  // (1) Ensure binding before any plugin / channel calls (Supabase needs it).
  WidgetsFlutterBinding.ensureInitialized();

  // (2) Register the global Bloc observer for cheap state-machine logging.
  Bloc.observer = AppBlocObserver();

  // (3) Initialize Supabase — only if URL + key were provided via
  //     `--dart-define`. Skipping in dev (when env is missing) keeps the
  //     UI shell runnable; `MyApp` falls back to a "configuration
  //     required" screen so the dev knows what's up.
  if (Env.isConfigured) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      // PKCE auth flow is the modern standard — protects the OAuth code
      // exchange against interception. Required for native OAuth.
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

    // (4) Listen for incoming deep links. When the OS hands us the
    //     `flutterposts://auth-callback?...` URI (either from a
    //     magic-link email or an OAuth provider redirect), forward it
    //     to Supabase. Supabase parses the URI fragment/params and
    //     populates the session, which then fires `onAuthStateChange`
    //     and propagates through `AuthBloc`.
    //
    //     Scheme + host wiring lives in `Info.plist` (iOS) and
    //     `AndroidManifest.xml` (Android) — added in Phase 5.
    _wireDeepLinkHandler();
  } else {
    debugPrint(
      '[bootstrap] WARNING: SUPABASE_URL / SUPABASE_ANON_KEY not set. '
      'Supabase calls will fail until env is configured. '
      'See SupabaseSetup.md for setup.',
    );
  }

  // (5) Off to the races.
  runApp(const MyApp());
}

/// One-time deep-link wiring.
///
/// `AppLinks().uriLinkStream` fires for both the initial link that
/// launched the app (cold start from email tap) AND any links received
/// while the app is alive (warm-state OAuth callback).
///
/// We don't dispose the subscription — it lives for the app's lifetime
/// and tearing it down on hot restart would be a footgun.
void _wireDeepLinkHandler() {
  final appLinks = AppLinks();
  appLinks.uriLinkStream.listen(
    (uri) async {
      // Filter to our scheme + auth callback host. Ignore everything
      // else (this stream is shared with ANY deep link the OS gives us).
      if (uri.scheme != 'flutterposts' || uri.host != 'auth-callback') {
        return;
      }
      try {
        // Supabase reads the access_token / refresh_token / code from
        // the URI, validates them, persists the session, and fires
        // `onAuthStateChange`. The `AuthBloc`'s stream subscription
        // then receives the new user and transitions to `AuthSignedIn`.
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
      } catch (error, stackTrace) {
        // Swallow + log: a malformed callback URI shouldn't crash the
        // app. The user will see they're still signed-out and can retry.
        debugPrint('[bootstrap] deep-link sign-in failed: $error\n$stackTrace');
      }
    },
    onError: (Object error, StackTrace stackTrace) {
      debugPrint('[bootstrap] app_links stream error: $error\n$stackTrace');
    },
  );
}
