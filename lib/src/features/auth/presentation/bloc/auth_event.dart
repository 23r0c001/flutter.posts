part of 'auth_bloc.dart';

/// Sealed event hierarchy for the auth state machine.
///
/// Why sealed instead of just abstract? Sealed classes are exhaustive
/// in `switch`, so the bloc's `on<>` handlers form a closed set the
/// compiler can verify. Adding a new auth event without registering a
/// handler is a compile error — we'd rather know at build time than
/// at runtime ("user clicked button, nothing happened").
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => const [];
}

/// Emitted internally by the bloc when `authStateChanges()` fires.
/// Private convention via underscore — callers from outside the bloc
/// shouldn't be dispatching this directly.
class AuthSessionChanged extends AuthEvent {
  /// The new authenticated user, or null if signed out.
  final AuthUser? user;

  const AuthSessionChanged(this.user);

  @override
  List<Object?> get props => [user];
}

/// User submitted the sign-in form requesting a magic link to [email].
class SignInWithMagicLinkRequested extends AuthEvent {
  final String email;

  const SignInWithMagicLinkRequested(this.email);

  @override
  List<Object?> get props => [email];
}

/// User tapped "Continue with Google" on the sign-in page.
class SignInWithGoogleRequested extends AuthEvent {
  const SignInWithGoogleRequested();
}

/// User tapped "Continue with Apple" on the sign-in page.
///
/// PHASE 5: handled. Until then the bloc emits an `AuthSignedOut` with
/// an explanatory error if dispatched. (The button is iOS-only AND
/// disabled until Phase 5, so this shouldn't fire in practice.)
class SignInWithAppleRequested extends AuthEvent {
  const SignInWithAppleRequested();
}

/// User tapped the "Sign out" action.
class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}
