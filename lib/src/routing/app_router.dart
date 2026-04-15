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
          builder: (context, state) => const PostList(),
        ),
        GoRoute(
          path: '/posts/:postId',
          builder: (context, state) {
            final postId = state.pathParameters['postId'] ?? '';
            return PostDetailPage(postId: postId);
          },
        ),
      ],
    ),
  ],
);
