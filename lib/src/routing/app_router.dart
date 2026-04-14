import 'package:go_router/go_router.dart';

import '../views/forum_home/forum_home_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const ForumHomePage()),
  ],
);
