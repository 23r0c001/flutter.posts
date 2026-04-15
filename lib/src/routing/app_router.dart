import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../views/forum_home/forum_home_page.dart';
import '../views/forum_home/post_detail_page.dart';
import '../views/forum_home/widgets/post_list.dart';

/* final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const ForumHomePage()),
  ],
);
 */

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => ForumHomePage(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => _buildAdaptivePage(
            state: state,
            child: const PostList(),
          ),
        ),
        GoRoute(
          path: '/posts/:postId',
          pageBuilder: (context, state) {
            final postId = state.pathParameters['postId'] ?? '';
            return _buildAdaptivePage(
              state: state,
              child: PostDetailPage(postId: postId),
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
  if (kIsWeb) {
    return NoTransitionPage<void>(
      key: state.pageKey,
      child: child,
    );
  }

  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, routeChild) {
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
