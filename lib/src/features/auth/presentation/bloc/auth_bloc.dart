import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_posts/src/core/error/app_error.dart';
import 'package:flutter_posts/src/features/auth/data/auth_repository.dart';
import 'package:flutter_posts/src/features/auth/domain/auth_user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// The app-wide auth state machine.
///
/// Source of truth for "is the user signed in", driven by
/// `AuthRepository.authStateChanges()` (which is itself driven by
/// Supabase's `onAuthStateChange` stream).
///
/// Lifecycle:
///   1. Constructor seeds initial state from `repo.currentUser`
///      (Supabase restored the session synchronously during
///      `Supabase.initialize`). This means we never flash a sign-in
///      page when there's a valid persisted session.
///   2. Constructor subscribes to `authStateChanges` and routes every
///      emission through the internal `AuthSessionChanged` event.
///   3. UI dispatches `SignIn*Requested` / `SignOutRequested` events;
///      handlers call the repository and emit transient states
///      (`AuthSendingLink`, `AuthAuthenticating`); the eventual
///      session change comes back through the stream and emits the
///      terminal `AuthSignedIn` / `AuthSignedOut` state.
///
/// This is a full `Bloc` (not Cubit) because auth genuinely IS a state
/// machine with named transitions worth logging. Most other features
/// in this app use `Cubit` for less ceremony.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<AuthUser?>? _authSubscription;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(
          // Seed the initial state from the persisted session so the UI
          // doesn't flash sign-in for users who are already logged in.
          authRepository.currentUser != null
              ? AuthSignedIn(user: authRepository.currentUser!)
              : const AuthSignedOut(),
        ) {
    on<AuthSessionChanged>(_onSessionChanged);
    on<SignInWithMagicLinkRequested>(_onSignInWithMagicLinkRequested);
    on<SignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<SignInWithAppleRequested>(_onSignInWithAppleRequested);
    on<SignOutRequested>(_onSignOutRequested);

    // Subscribe AFTER `on<>` registrations are wired so the very first
    // emission is guaranteed to find a handler.
    _authSubscription = _authRepository.authStateChanges().listen(
      (user) => add(AuthSessionChanged(user)),
    );
  }

  // ---------------------------------------------------------------------------
  // Event handlers
  // ---------------------------------------------------------------------------

  /// Stream-driven transition. Authoritative: stream is the source of
  /// truth for "signed in vs out". If a transient state (`AuthSendingLink`,
  /// `AuthAuthenticating`, `AuthLinkSent`) is interrupted by a real
  /// session change, this handler resolves it.
  void _onSessionChanged(AuthSessionChanged event, Emitter<AuthState> emit) {
    final user = event.user;
    if (user != null) {
      emit(AuthSignedIn(user: user));
    } else {
      // Preserve a `lastError` if we were already showing one — don't
      // overwrite a useful error with a clean signed-out state just
      // because the stream re-emitted null.
      final previous = state;
      final lastError = previous is AuthSignedOut ? previous.lastError : null;
      emit(AuthSignedOut(lastError: lastError));
    }
  }

  Future<void> _onSignInWithMagicLinkRequested(
    SignInWithMagicLinkRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthSendingLink());
    try {
      await _authRepository.sendMagicLink(event.email);
      emit(AuthLinkSent(email: event.email));
    } on AppError catch (error) {
      // Errors from the repository are already `AppError`-mapped.
      emit(AuthSignedOut(lastError: error));
    } catch (error, stackTrace) {
      // Defensive — should never trigger because the repo always maps,
      // but if something slips through we still wrap it cleanly.
      emit(AuthSignedOut(lastError: mapSupabaseError(error, stackTrace)));
    }
  }

  Future<void> _onSignInWithGoogleRequested(
    SignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthAuthenticating());
    try {
      await _authRepository.signInWithGoogle();
      // `signInWithOAuth` returns once the browser is launched; the
      // actual sign-in event arrives later via `authStateChanges`
      // (which dispatches `AuthSessionChanged`). We deliberately stay
      // in `AuthAuthenticating` until then.
    } on AppError catch (error) {
      emit(AuthSignedOut(lastError: error));
    } catch (error, stackTrace) {
      emit(AuthSignedOut(lastError: mapSupabaseError(error, stackTrace)));
    }
  }

  Future<void> _onSignInWithAppleRequested(
    SignInWithAppleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthAuthenticating());
    try {
      await _authRepository.signInWithApple();
      // `signInWithIdToken` populates the session synchronously, but the
      // session change still arrives via `authStateChanges` → bloc
      // transitions to `AuthSignedIn` from `AuthSessionChanged`.
    } on AppError catch (error) {
      emit(AuthSignedOut(lastError: error));
    } catch (error, stackTrace) {
      emit(AuthSignedOut(lastError: mapSupabaseError(error, stackTrace)));
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.signOut();
      // `authStateChanges` will fire with `null` and `_onSessionChanged`
      // emits `AuthSignedOut` — no need to emit it here too.
    } on AppError catch (error) {
      // Stay signed-in but surface the error so the user can retry.
      // (Genuinely odd state — sign-out usually can't fail.)
      if (state is AuthSignedIn) {
        // Don't degrade to signed-out optimistically; just log via
        // observer (already wired in `bootstrap.dart`).
      }
      emit(AuthSignedOut(lastError: error));
    }
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    return super.close();
  }
}
