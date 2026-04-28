import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_posts/src/shared/constants/app_routes.dart';
import 'package:flutter_posts/src/views/forum_home/forum_shell.dart';
import 'package:flutter_posts/src/views/forum_home/group_feed_page.dart';
import 'package:flutter_posts/src/views/forum_home/me_home_page.dart';
import 'package:flutter_posts/src/views/forum_home/thread_comments_page.dart';
import 'package:flutter_posts/src/views/forum_home/widgets/group_list.dart';

/// Top-level app router.
/// Uses a shell so sidebar/resources persist while center content routes change.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.communityPath,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          ForumShell(navigationShell: navigationShell),
      branches: [
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
                  // Reddit-like thread route:
                  // /t/:group/comments/:threadId
                  path:
                      '${AppRoutes.groupPrefix}/:group/${AppRoutes.commentsSegment}/:threadId',
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
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.mePath,
              pageBuilder: (context, state) => _buildAdaptivePage(
                state: state,
                child: const MeHomePage(),
              ),
            ),
          ],
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

  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return CupertinoPage<void>(key: state.pageKey, child: child);
  }

  return MaterialPage<void>(key: state.pageKey, child: child);
}
