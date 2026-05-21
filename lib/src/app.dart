import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/env/env.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/forum/data/forum_repository.dart';

/// Root widget.
///
/// Owns the app-wide singletons:
///   - `AuthRepository` (data layer, talks to Supabase).
///   - `AuthBloc` (state machine, subscribes to repo's auth stream).
///   - `GoRouter` instance configured with the bloc for redirects.
///
/// Stateful so we can `dispose()` them cleanly on hot restart and on
/// platform-driven app teardown.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

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
    if (_isConfigured) {
      _authRepository = AuthRepository();
      _forumRepository = ForumRepository();
      _authBloc = AuthBloc(authRepository: _authRepository);
      _router = createAppRouter(_authBloc);
    }
  }

  @override
  void dispose() {
    if (_isConfigured) {
      _authBloc.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Friendly fallback when env vars aren't set — keeps the app from
    // crash-looping in dev when SUPABASE_URL / SUPABASE_ANON_KEY were
    // forgotten on `flutter run`. See SupabaseSetup.md Part 6.
    if (!_isConfigured) {
      return MaterialApp(
        title: 'My Forum App',
        theme: AppTheme.light(),
        home: const _MissingEnvScreen(),
      );
    }

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
        ),
      ),
    );
  }
}

/// Shown when `--dart-define`s are missing. Tells the dev what to do.
/// Not localized — this is a dev affordance, not user-facing in production.
class _MissingEnvScreen extends StatelessWidget {
  const _MissingEnvScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.settings_input_component,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Configuration required',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  'SUPABASE_URL and SUPABASE_ANON_KEY were not passed.\n\n'
                  'Run with: flutter run --dart-define-from-file=.env.json\n\n'
                  'See SupabaseSetup.md at the repo root.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
