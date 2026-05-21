import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/env/env.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/in_memory_auth_repository.dart';
import 'features/auth/data/supabase_auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/forum/data/forum_repository.dart';
import 'features/forum/data/in_memory_forum_repository.dart';
import 'features/forum/data/supabase_forum_repository.dart';

/// Root widget.
///
/// Owns the app-wide singletons:
///   - `AuthRepository` (data layer; either Supabase or in-memory fake).
///   - `ForumRepository` (same).
///   - `AuthBloc` (state machine, subscribes to the repo's auth stream).
///   - `GoRouter` instance configured with the bloc for redirects.
///
/// Repository selection is driven entirely by `Env.isConfigured`:
///   - When SUPABASE_URL + SUPABASE_ANON_KEY are passed via
///     `--dart-define`, we wire real Supabase implementations.
///   - When they're missing, we wire `InMemory*Repository` and show
///     an "OFFLINE DEV MODE" corner banner so you don't forget. This
///     lets you iterate on UI without ever standing up Supabase.
///
/// Tests can short-circuit that selection by passing
/// [authRepositoryOverride] / [forumRepositoryOverride]. This is the
/// hook for widget / integration tests that want to drive specific
/// auth or forum state without spinning up Supabase.
///
/// Stateful so we can `dispose()` the bloc cleanly on hot restart and
/// platform-driven app teardown.
class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    this.authRepositoryOverride,
    this.forumRepositoryOverride,
  });

  /// Optional override for the auth backend. Pass an
  /// `InMemoryAuthRepository(initialUser: ...)` (or a `mocktail` mock
  /// implementing `AuthRepository`) in tests. Null in production.
  final AuthRepository? authRepositoryOverride;

  /// Optional override for the forum backend. Same contract as
  /// [authRepositoryOverride]. Null in production.
  final ForumRepository? forumRepositoryOverride;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthRepository _authRepository;
  late final ForumRepository _forumRepository;
  late final AuthBloc _authBloc;
  late final GoRouter _router;
  late final bool _isConfigured;

  @override
  void initState() {
    super.initState();
    _isConfigured = Env.isConfigured;
    // Repository selection priority:
    //   1. Constructor overrides (tests / integration harnesses).
    //   2. Supabase impls if env is configured.
    //   3. In-memory fakes otherwise (offline dev mode).
    //
    // Everything downstream (bloc, cubits, UI) talks only to the
    // AuthRepository / ForumRepository interfaces, so the rest of the
    // app is identical regardless of which branch we take.
    //
    // Offline-dev mode opts the fakes into a small artificial latency
    // so loading states are visible while iterating. The fake's
    // default is zero, which is what tests want.
    if (widget.authRepositoryOverride != null) {
      _authRepository = widget.authRepositoryOverride!;
    } else if (_isConfigured) {
      _authRepository = SupabaseAuthRepository();
    } else {
      _authRepository = InMemoryAuthRepository(
        latency: const Duration(milliseconds: 200),
      );
    }

    if (widget.forumRepositoryOverride != null) {
      _forumRepository = widget.forumRepositoryOverride!;
    } else if (_isConfigured) {
      _forumRepository = SupabaseForumRepository();
    } else {
      _forumRepository = InMemoryForumRepository(
        latency: const Duration(milliseconds: 120),
      );
    }

    _authBloc = AuthBloc(authRepository: _authRepository);
    _router = createAppRouter(_authBloc);
  }

  @override
  void dispose() {
    _authBloc.close();
    // The in-memory auth repo owns a stream controller that needs an
    // explicit close. The Supabase repo doesn't own one — Supabase
    // manages its own auth stream lifecycle.
    final repo = _authRepository;
    if (repo is InMemoryAuthRepository) repo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // RepositoryProviders expose data-layer singletons to the whole
    // widget tree so per-route cubits can `context.read<...>` them.
    // BlocProvider hosts the app-wide `AuthBloc` (per-page cubits like
    // `FeedCubit` / `ThreadCubit` are created inside each page).
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: _authRepository),
        RepositoryProvider<ForumRepository>.value(value: _forumRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: _authBloc),
        ],
        child: MaterialApp.router(
          title: 'My Forum App',
          theme: AppTheme.light(),
          routerConfig: _router,
          // `builder` wraps every navigator route. In offline-dev mode
          // we slap a diagonal corner ribbon on every screen so you
          // never forget you're looking at fake data. In configured
          // mode we pass through untouched.
          builder: (context, child) {
            if (_isConfigured) return child ?? const SizedBox.shrink();
            return Banner(
              message: 'OFFLINE DEV',
              location: BannerLocation.topEnd,
              color: const Color(0xFFB35C00),
              textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }
}
