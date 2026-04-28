import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_posts/src/shared/constants/app_routes.dart';

class GroupList extends StatelessWidget {
  const GroupList({super.key});

  @override
  /// Placeholder group feed used for shell routing and transition validation.
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final groupSlug = 'group-${index + 1}';
        final groupPath = AppRoutes.groupPath(group: groupSlug);
        return Card(
          child: ListTile(
            title: Text('Group ${index + 1}'),
            subtitle: const Text('Placeholder group content'),
            // Push to keep back stack linear: group -> thread.
            onTap: () => context.push(groupPath),
          ),
        );
      },
    );
  }
}
