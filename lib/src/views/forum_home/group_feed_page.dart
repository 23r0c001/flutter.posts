import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_posts/src/shared/constants/app_routes.dart';

/// Placeholder group feed page shown after selecting a group.
class GroupFeedPage extends StatelessWidget {
  final String group;

  const GroupFeedPage({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final threadId = '${index + 1}';
        final threadPath = AppRoutes.threadPath(group: group, threadId: threadId);

        return Card(
          child: ListTile(
            title: Text('Post $threadId'),
            subtitle: Text('Placeholder content in r/$group'),
            onTap: () => context.push(threadPath),
          ),
        );
      },
    );
  }
}
