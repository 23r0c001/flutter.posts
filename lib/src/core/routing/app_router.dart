import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_posts/src/core/routing/app_routes.dart';
import 'package:flutter_posts/src/core/routing/go_router_refresh_stream.dart';
import 'package:flutter_posts/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_posts/src/features/auth/presentation/magic_link_sent_page.dart';
import 'package:flutter_posts/src/features/auth/presentation/sign_in_page.dart';
import 'package:flutter_posts/src/features/forum/presentation/feed/group_feed_page.dart';
import 'package:flutter_posts/src/features/forum/presentation/feed/group_list.dart';
import 'package:flutter_posts/src/features/forum/presentation/shell/forum_shell.dart';
import 'package:flutter_posts/src/features/forum/presentation/thread/thread_comments_page.dart';
import 'package:flutter_posts/src/features/me/presentation/me_home_page.dart';
import 'package:flutter_posts/src/features/me/presentation/me_settings_page.dart';
import 'package:go_router/go_router.dart';

/// Builds the app's root router with auth-aware redirects.
///
/// Why a factory function and not a top-level constant: the router
/// needs a reference to the `AuthBloc` to (a) react to auth state via
/// `refreshListenable`, and (b) inspect the current state in `redirect`.
/// `AuthBloc` is created inside the widget tree in `app.dart`, so the
/// router can't be a compile-time const.
GoRouter createAppRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: AppRoutes.communityPath,
    // Re-evaluate `redirect` whenever the bloc emits a new state.
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) => _authRedirect(authBloc, state),
    routes: [
      // Sign-in routes live OUTSIDE the StatefulShellRoute so the shell
      // chrome (sidebar, drawer, bottom nav) doesn't render behind the
      // sign-in flow. These are full-page takeovers.
      GoRoute(
        path: AppRoutes.signInPath,
        pageBuilder: (context, state) => _buildAdaptivePage(
          state: state,
          child: const SignInPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.magicLinkSentPath,
        pageBuilder: (context, state) => _buildAdaptivePage(
          state: state,
          child: const MagicLinkSentPage(),
        ),
      ),
      // The shell wraps every authenticated page so the sidebar/
      // resources rails stay mounted while only the center pane navigates.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ForumShell(navigationShell: navigationShell),
        branches: [
          // Branch 0 — Community: full browse stack (list → feed → thread).
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.communityPath,
                pageBuilder: (context, state) => _buildAdaptivePage(
                  state: state,
                  child: const GroupList(),
                ),
                routes: [
                  GoRoute(
                    // /t/:group
                    path: '${AppRoutes.groupPrefix}/:group',
                    pageBuilder: (context, state) {
                      final group = state.pathParameters['group'] ?? '';
                      return _buildAdaptivePage(
                        state: state,
                        child: GroupFeedPage(group: group),
                      );
                    },
                  ),
                  GoRoute(
                    // /t/:group/comments/:threadId — Reddit-style thread URL.
                    path:
                        '${AppRoutes.groupPrefix}/:group/${AppRoutes.commentsSegment}/:threadId',
                    pageBuilder: (context, state) {
                      final threadId =
                          state.pathParameters['threadId'] ?? '';
                      return _buildAdaptivePage(
                        state: state,
                        child: ThreadCommentsPage(threadId: threadId),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          // Branch 1 — Me: shallow (root + settings drill-down).
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.mePath,
                pageBuilder: (context, state) => _buildAdaptivePage(
                  state: state,
                  child: const MeHomePage(),
                ),
                routes: [
                  GoRoute(
                    path: 'settings',
                    pageBuilder: (context, state) => _buildAdaptivePage(
                      state: state,
                      child: const MeSettingsPage(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Routes the user based on auth state.
///
///   AuthSignedOut / AuthSendingLink / AuthAuthenticating
///       → force to /sign-in (the sign-in form handles the transient states)
///   AuthLinkSent
///       → force to /sign-in/magic-link-sent ("check your email")
///   AuthSignedIn
///       → if currently on a sign-in route, kick to /community; else stay put.
String? _authRedirect(AuthBloc authBloc, GoRouterState state) {
  final auth = authBloc.state;
  final path = state.matchedLocation;
  final isOnSignIn = path == AppRoutes.signInPath;
  final isOnMagicLinkSent = path == AppRoutes.magicLinkSentPath;
  final isOnAnyAuthRoute = isOnSignIn || isOnMagicLinkSent;

  switch (auth) {
    case AuthSignedIn():
      // Already signed in but stuck on an auth page → go to the feed.
      return isOnAnyAuthRoute ? AppRoutes.communityPath : null;

    case AuthLinkSent():
      // Magic link sent: show the confirmation page (if not already there).
      return isOnMagicLinkSent ? null : AppRoutes.magicLinkSentPath;

    case AuthSendingLink():
    case AuthAuthenticating():
    case AuthSignedOut():
      // Any not-yet-authenticated state belongs on the sign-in form.
      return isOnSignIn ? null : AppRoutes.signInPath;
  }
}

/// Applies platform-aware route transitions:
///   - Web: no transition (avoids sluggish lingering overlays).
///   - iOS: Cupertino horizontal slide.
///   - Other (Android/Material/desktop): Material default slide+fade.
Page<void> _buildAdaptivePage({
  required GoRouterState state,
  required Widget child,
}) {
  // Wrap every route in an opaque background to prevent "ghosting"
  // during horizontal transitions (old page bleeding through the gap).
  final Widget opaqueChild = _buildOpaqueRouteChild(child);

  if (kIsWeb) {
    return NoTransitionPage<void>(key: state.pageKey, child: opaqueChild);
  }

  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return CupertinoPage<void>(key: state.pageKey, child: opaqueChild);
  }

  return MaterialPage<void>(key: state.pageKey, child: opaqueChild);
}

Widget _buildOpaqueRouteChild(Widget child) {
  return Builder(
    builder: (context) => ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    ),
  );
}
