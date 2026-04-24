import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_posts/src/shared/constants/app_routes.dart';
import 'package:flutter_posts/src/views/forum_home/forum_shell.dart';
import 'package:flutter_posts/src/views/forum_home/me_home_page.dart';
import 'package:flutter_posts/src/views/forum_home/thread_comments_page.dart';
import 'package:flutter_posts/src/views/forum_home/widgets/post_list.dart';

/// Top-level app router.
/// Uses a shell so sidebar/resources persist while center content routes change.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.communityPath,
  routes: [
    // Persistent forum shell route; child changes with nested route path.
    ShellRoute(
      builder: (context, state, child) => ForumShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.communityPath,
          // Forum feed entry route.
          pageBuilder: (context, state) =>
              _buildAdaptivePage(state: state, child: const PostList()),
        ),
        GoRoute(
          path: AppRoutes.mePath,
          pageBuilder: (context, state) =>
              _buildAdaptivePage(state: state, child: const MeHomePage()),
        ),
        GoRoute(
          // Reddit-like thread route:
          // /t/:group/comments/:threadId
          path:
              '/${AppRoutes.groupPrefix}/:group/${AppRoutes.commentsSegment}/:threadId',
          // Thread route rendered in the same shell center pane.
          pageBuilder: (context, state) {
            final threadId = state.pathParameters['threadId'] ?? '';
            return _buildAdaptivePage(
              state: state,
              child: ThreadCommentsPage(threadId: threadId),
            );
          },
        ),
      ],
    ),
  ],
);

/// Applies platform-aware route transitions:
/// - Web: no transition to avoid sluggish lingering overlays.
/// - Mobile: horizontal slide for a native app feel.
Page<void> _buildAdaptivePage({
  required GoRouterState state,
  required Widget child,
}) {
  // Web gets instant route swaps so old content does not linger/fade.
  if (kIsWeb) {
    return NoTransitionPage<void>(key: state.pageKey, child: child);
  }

  // Mobile gets a forward push slide for a native navigation feel.
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, routeChild) {
      // Enter from right to left; mirrors common Android/iOS push patterns.
      // TODO: Add left to right for back navigation
      final slideTween = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));

      return SlideTransition(
        position: animation.drive(slideTween),
        child: routeChild,
      );
    },
  );
}
