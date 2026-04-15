import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PostList extends StatelessWidget {
  const PostList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            title: Text('Post ${index + 1}'),
            subtitle: const Text('Placeholder post content'),
            // Use push to preserve a clear in-app back stack.
            onTap: () => context.push('/posts/${index + 1}'),
          ),
        );
      },
    );
  }
}
