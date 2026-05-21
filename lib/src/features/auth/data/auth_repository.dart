import 'package:flutter_posts/src/features/auth/domain/auth_user.dart';

/// Auth backend contract.
///
/// LAYER RULE: blocs / UI talk to THIS interface, not to any concrete
/// backend. The production binding is `SupabaseAuthRepository`; the
/// dev-without-env binding is `InMemoryAuthRepository`. Both live in
/// `data/`. Adding a third (e.g., Firebase) is a self-contained file.
///
/// Errors thrown from every method are `AppError` (or a subclass);
/// implementations are responsible for mapping their backend's
/// exception types via `mapSupabaseError` or equivalent.
abstract interface class AuthRepository {
  /// Synchronous read of the persisted user, if any. `AuthBloc` reads
  /// this once at construction to seed its initial state — so the UI
  /// doesn't flash sign-in before the auth stream catches up.
  AuthUser? get currentUser;

  /// Stream of auth state changes. Map `null` means signed-out. The
  /// stream MUST emit at least once after subscription so `AuthBloc`
  /// can transition from any seeded initial state.
  Stream<AuthUser?> authStateChanges();

  /// Send a magic-link email. The link redirects back into the app via
  /// the configured deep-link scheme (production) or just signs the
  /// user in immediately (dev / in-memory).
  Future<void> sendMagicLink(String email);

  /// Start the Google OAuth flow.
  Future<void> signInWithGoogle();

  /// Start the Sign In with Apple flow (iOS only in production).
  Future<void> signInWithApple();

  /// End the session.
  Future<void> signOut();
}
