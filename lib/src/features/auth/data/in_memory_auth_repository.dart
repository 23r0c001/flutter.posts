import 'dart:async';

import 'package:flutter_posts/src/features/auth/data/auth_repository.dart';
import 'package:flutter_posts/src/features/auth/domain/auth_user.dart';
import 'package:meta/meta.dart';

/// `AuthRepository` that never talks to a backend.
///
/// Two purposes:
///
///   1. **Offline dev mode.** `app.dart` instantiates this when
///      `Env.isConfigured` is false so the UI is runnable without a
///      Supabase project.
///
///   2. **Unit / widget tests.** Tests can construct one with the
///      desired initial state, drive the auth stream via `setUser`, and
///      assert on bloc transitions deterministically.
///
/// Test-oriented design notes:
///   - Default `latency` is `Duration.zero` so tests don't have to pump
///     extra time. Production dev mode opts into a small delay so the
///     loading states are visible.
///   - The stream is broadcast (multiple listeners welcome) and the
///     initial value is replayed once via `scheduleMicrotask` so a
///     subscriber that attaches synchronously after construction will
///     see it. Use `pumpEventQueue()` / `await Future.microtask((){})`
///     in tests if you need to await that replay.
///   - `dispose()` must be called by long-lived owners; tests should
///     call it in `tearDown`.
class InMemoryAuthRepository implements AuthRepository {
  /// The well-known dev user. Its ID matches one of the fake authors
  /// in `InMemoryForumRepository`, so "your" posts in offline dev mode
  /// are attributed to this user.
  static const AuthUser defaultUser = AuthUser(
    id: '00000000-0000-0000-0000-000000000001',
    email: 'dev@flutterposts.local',
    displayName: 'Dev User',
  );

  /// [initialUser] seeds `currentUser`. Pass `null` to start signed-out.
  /// Defaults to [defaultUser] so the offline-dev shell renders without
  /// forcing the developer through a sign-in screen on every restart.
  ///
  /// [signInUser] is who magic-link / Google / Apple resolve to in this
  /// fake. Defaults to [initialUser] if non-null, else [defaultUser].
  ///
  /// [latency] is the artificial delay applied to each async call.
  /// Default zero (test-friendly). Production dev mode passes ~200ms
  /// so loading states are perceptible.
  InMemoryAuthRepository({
    AuthUser? initialUser = defaultUser,
    AuthUser? signInUser,
    this.latency = Duration.zero,
  })  : _signInUser = signInUser ?? initialUser ?? defaultUser,
        _currentUser = initialUser {
    if (_currentUser != null) {
      // Broadcast streams don't replay on subscribe, so we schedule a
      // microtask to emit once any listeners have had a chance to
      // attach. AuthBloc subscribes synchronously in its constructor,
      // so this lands as the first emitted value.
      scheduleMicrotask(() {
        if (!_controller.isClosed) _controller.add(_currentUser);
      });
    }
  }

  /// Artificial latency applied to each method. Public-final so tests
  /// can read it back if they're asserting timings.
  final Duration latency;

  final AuthUser _signInUser;
  AuthUser? _currentUser;

  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Stream<AuthUser?> authStateChanges() => _controller.stream;

  @override
  Future<void> sendMagicLink(String email) async {
    await _wait();
    final localPart =
        email.contains('@') ? email.substring(0, email.indexOf('@')) : email;
    _emit(AuthUser(
      id: _signInUser.id,
      email: email,
      displayName: localPart,
      avatarUrl: _signInUser.avatarUrl,
    ));
  }

  @override
  Future<void> signInWithGoogle() async {
    await _wait();
    _emit(_signInUser);
  }

  @override
  Future<void> signInWithApple() async {
    await _wait();
    _emit(_signInUser);
  }

  @override
  Future<void> signOut() async {
    await _wait();
    _emit(null);
  }

  // ---------------------------------------------------------------------------
  // Test hooks. These are public on purpose; the offline-dev path
  // doesn't use them, but tests need a deterministic way to push state.
  // ---------------------------------------------------------------------------

  /// Directly set the current user and emit on the stream. Use this in
  /// tests to drive `AuthBloc` through state transitions without
  /// caring which sign-in method got it there.
  @visibleForTesting
  void setUser(AuthUser? user) => _emit(user);

  /// Close the underlying stream controller. Long-lived owners
  /// (e.g., `_MyAppState.dispose`) and tests in `tearDown` should call this.
  void dispose() {
    if (!_controller.isClosed) _controller.close();
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  void _emit(AuthUser? user) {
    _currentUser = user;
    if (!_controller.isClosed) _controller.add(user);
  }

  /// Single point of artificial delay so we can no-op cleanly when
  /// `latency` is zero (the test default).
  Future<void> _wait() {
    if (latency == Duration.zero) return Future<void>.value();
    return Future<void>.delayed(latency);
  }
}
