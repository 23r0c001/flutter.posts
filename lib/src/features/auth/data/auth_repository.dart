import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_posts/src/core/error/app_error.dart';
import 'package:flutter_posts/src/features/auth/domain/auth_user.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
// `supabase_flutter` re-exports a class also named `AuthUser` (its
// internal session/user record). We hide it so our domain `AuthUser`
// resolves unambiguously. We still need `SupabaseClient`, `OAuthProvider`,
// and `Supabase` from this package.
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

/// Wraps Supabase Auth so blocs / UI never see Supabase types.
///
/// LAYER RULE: this is the ONLY file in `features/auth/` that imports
/// `supabase_flutter`. All errors are translated to `AppError` via
/// `mapSupabaseError`; all return types are plain Dart (`AuthUser`,
/// `Stream<AuthUser?>`).
///
/// Redirect URL is the custom scheme `flutterposts://auth-callback`,
/// which the OS deep-links into the app — see Phase 5's
/// `ios/Runner/Info.plist` and `android/app/src/main/AndroidManifest.xml`.
/// `bootstrap.dart` listens for that URI via `app_links` and hands it
/// off to `Supabase.instance.client.auth.getSessionFromUrl`.
class AuthRepository {
  /// The Supabase client. Defaulted to the global singleton initialized
  /// in `bootstrap.dart`, but accepting an override makes the repository
  /// testable with a fake or local Supabase instance.
  final SupabaseClient _supabase;

  AuthRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// The deep-link target that Supabase rewrites email/OAuth callbacks
  /// to. Must match the scheme registered in:
  ///   - `ios/Runner/Info.plist` (CFBundleURLTypes)
  ///   - `android/app/src/main/AndroidManifest.xml` (intent-filter)
  ///   - Supabase Dashboard → Authentication → URL Configuration
  static const String _redirectUrl = 'flutterposts://auth-callback';

  // ---------------------------------------------------------------------------
  // Session inspection
  // ---------------------------------------------------------------------------

  /// Synchronously read the persisted user, if any.
  ///
  /// Supabase restores the session from `shared_preferences` during
  /// `Supabase.initialize`, so this is non-null immediately after boot
  /// if there's a stored session. Used by `AuthBloc`'s initial state
  /// so we never flash a sign-in screen before checking.
  AuthUser? get currentUser {
    final user = _supabase.auth.currentUser;
    return user == null ? null : AuthUser.fromSupabaseUser(user);
  }

  /// Stream of auth state changes — fires whenever the session changes
  /// (sign-in, sign-out, token refresh, etc.). Map `null` means
  /// "signed out". `AuthBloc` subscribes to this for the duration of
  /// the app and emits states accordingly.
  Stream<AuthUser?> authStateChanges() {
    return _supabase.auth.onAuthStateChange.map((event) {
      final user = event.session?.user;
      return user == null ? null : AuthUser.fromSupabaseUser(user);
    });
  }

  // ---------------------------------------------------------------------------
  // Sign-in flows
  // ---------------------------------------------------------------------------

  /// Send a magic-link email to [email]. The email contains a link that
  /// deep-links back into the app via [_redirectUrl] when tapped.
  ///
  /// Throws `AppError` on failure (wraps Supabase exceptions). Common
  /// failure modes: invalid email, rate-limited (Supabase free SMTP
  /// allows ~4 emails/hour per address).
  Future<void> sendMagicLink(String email) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: _redirectUrl,
      );
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// Start the Google OAuth flow.
  ///
  /// Opens the system browser (via `url_launcher` under the hood),
  /// completes OAuth at Google → Supabase, then redirects back to
  /// [_redirectUrl]. The OS routes the deep-link to our app and
  /// `bootstrap.dart`'s listener finishes the flow by calling
  /// `getSessionFromUrl`.
  ///
  /// Returns immediately after the browser is launched — the actual
  /// session-arrived event comes through `authStateChanges` later.
  Future<void> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _redirectUrl,
      );
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// Start the Sign In with Apple flow (iOS only).
  ///
  /// Mandatory on iOS per App Store Review Guideline 4.8 because we
  /// offer Google Sign-In. Two-step exchange:
  ///   1. Ask Apple for an ID token. We give Apple a SHA-256 of a
  ///      randomly-generated raw nonce.
  ///   2. Hand the ID token to Supabase along with the RAW nonce.
  ///      Supabase verifies the token's nonce claim matches the SHA-256
  ///      of the raw nonce we provide — proving we initiated the flow.
  ///
  /// Unlike Google's browser-based flow, Apple Sign-In returns the
  /// session synchronously (no deep-link round-trip). The auth state
  /// stream still fires `signedIn` from the `signInWithIdToken` call.
  ///
  /// Requires:
  ///   - iOS 13+ (Apple Sign-In API minimum).
  ///   - "Sign In with Apple" capability enabled in Xcode (see
  ///     `ios/Runner/Runner.entitlements` for the manual steps).
  ///   - Apple as a provider in the Supabase dashboard.
  Future<void> signInWithApple() async {
    try {
      // Generate a cryptographically random raw nonce. Apple wants the
      // SHA-256; Supabase wants the raw. We pass both.
      final rawNonce = _generateNonce();
      final hashedNonce =
          sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AppError(
          kind: AppErrorKind.auth,
          userMessage: 'Apple did not return a sign-in token. Please try again.',
        );
      }

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
    } on AppError {
      rethrow;
    } on SignInWithAppleAuthorizationException catch (error, stackTrace) {
      // User cancelled / no credential / not available → calm message.
      final isCancel = error.code == AuthorizationErrorCode.canceled;
      throw AppError(
        kind: AppErrorKind.auth,
        userMessage: isCancel
            ? 'Sign-in cancelled.'
            : 'Apple Sign-In failed. Please try again.',
        cause: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// Generates a URL-safe random nonce string. Apple recommends ≥32
  /// chars; this generator produces 32 alphanumerics.
  String _generateNonce([int length = 32]) {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  // ---------------------------------------------------------------------------
  // Sign-out
  // ---------------------------------------------------------------------------

  /// End the session. `authStateChanges` will emit `null` after this.
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }
}
