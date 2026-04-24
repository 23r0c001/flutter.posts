import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_posts/src/shared/constants/app_routes.dart';

class PostList extends StatelessWidget {
  const PostList({super.key});

  @override
  /// Placeholder post feed used for shell routing and transition validation.
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        // Keep IDs deterministic for URL demo routes:
        // /t/cursor/comments/1, /t/cursor/comments/2, ...
        final threadId = '${index + 1}';
        final threadPath = AppRoutes.threadPath(
          group: 'cursor',
          threadId: threadId,
        );
        return Card(
          child: ListTile(
            title: Text('Group ${index + 1}'),
            subtitle: const Text('Placeholder group content'),
            // Use push to preserve a clear in-app back stack.
            onTap: () => context.push(threadPath),
          ),
        );
      },
    );
  }
}
