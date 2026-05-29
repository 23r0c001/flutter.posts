part of 'auth_bloc.dart';

/// Sealed state hierarchy. Sealed → exhaustive `switch` in widgets:
///
///   switch (state) {
///     AuthSignedOut() => SignInPage(...),
///     AuthSendingLink() => CircularProgressIndicator(),
///     AuthLinkSent() => MagicLinkSentPage(...),
///     AuthAuthenticating() => ...,
///     AuthSignedIn(:final user) => ProfileWidget(user: user),
///   }
///
/// Adding a new state without updating every switch is a compile error.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => const [];
}

/// No active session. Optionally carries a `lastError` so we can surface
/// "your link expired" / "couldn't reach the server" toasts on the
/// sign-in page after a failed attempt.
class AuthSignedOut extends AuthState {
  /// The most recent error, if any. UI may render this as a snack bar
  /// or inline message. Null on first/clean load.
  final AppError? lastError;

  const AuthSignedOut({this.lastError});

  @override
  List<Object?> get props => [lastError];
}

/// Magic-link API call is in flight (very brief — just the network
/// round-trip to Supabase). UI typically shows a button spinner.
class AuthSendingLink extends AuthState {
  const AuthSendingLink();
}

/// Magic-link email has been dispatched and we're waiting for the
/// user to click it. UI shows the `MagicLinkSentPage` ("check your
/// email"). [email] is shown back to the user so they know which
/// inbox to look in.
class AuthLinkSent extends AuthState {
  final String email;

  const AuthLinkSent({required this.email});

  @override
  List<Object?> get props => [email];
}

/// An OAuth provider (Google or Apple) flow is in progress. Lasts from
/// the moment the browser is launched until the deep-link callback
/// resolves (or the user cancels and we time out).
class AuthAuthenticating extends AuthState {
  const AuthAuthenticating();
}

/// Active session with an authenticated user. Every authenticated
/// feature should `BlocBuilder<AuthBloc, AuthState>` and pattern-match
/// on this case to get [user].
class AuthSignedIn extends AuthState {
  final AuthUser user;

  const AuthSignedIn({required this.user});

  @override
  List<Object?> get props => [user];
}
