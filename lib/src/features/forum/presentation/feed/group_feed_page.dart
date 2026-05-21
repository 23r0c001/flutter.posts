import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_posts/src/core/routing/app_routes.dart';
import 'package:flutter_posts/src/features/forum/data/forum_repository.dart';
import 'package:flutter_posts/src/features/forum/presentation/feed/cubit/feed_cubit.dart';
import 'package:go_router/go_router.dart';

/// Feed of posts within a single community.
///
/// `group` is the URL slug from the path (`/t/:group`). `FeedCubit`
/// resolves the slug to a `Community` and then loads posts.
class GroupFeedPage extends StatelessWidget {
  /// URL-friendly slug for the community (e.g., "autism-support").
  final String group;

  const GroupFeedPage({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FeedCubit(
        forumRepository: context.read<ForumRepository>(),
        communitySlug: group,
      )..load(),
      child: _GroupFeedView(slug: group),
    );
  }
}

class _GroupFeedView extends StatelessWidget {
  final String slug;

  const _GroupFeedView({required this.slug});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeedCubit, FeedState>(
      builder: (context, state) {
        return switch (state) {
          FeedInitial() ||
          FeedLoading() =>
            const Center(child: CircularProgressIndicator()),
          FeedNotFound(:final slug) => _NotFoundState(slug: slug),
          FeedError(:final error) => _ErrorState(
              message: error.userMessage,
              onRetry: context.read<FeedCubit>().load,
            ),
          FeedLoaded(:final community, :final posts) => RefreshIndicator(
              onRefresh: context.read<FeedCubit>().load,
              child: posts.isEmpty
                  // Single-item ListView so RefreshIndicator still works
                  // — Refresh requires a scrollable child.
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        Text(
                          community.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No posts yet. Be the first to start a conversation.',
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: posts.length + 1, // +1 for header
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              left: 4,
                              right: 4,
                              top: 4,
                              bottom: 8,
                            ),
                            child: Text(
                              community.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall,
                            ),
                          );
                        }
                        final post = posts[index - 1];
                        final path = AppRoutes.threadPath(
                          group: slug,
                          threadId: post.id,
                        );
                        return Card(
                          child: ListTile(
                            title: Text(post.title),
                            subtitle: post.body != null
                                ? Text(
                                    post.body!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            trailing: post.author?.displayName != null
                                ? Text(
                                    post.author!.displayName!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  )
                                : null,
                            onTap: () => context.push(path),
                          ),
                        );
                      },
                    ),
            ),
        };
      },
    );
  }
}

class _NotFoundState extends StatelessWidget {
  final String slug;

  const _NotFoundState({required this.slug});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No such community: "$slug"',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go(AppRoutes.communityPath),
              child: const Text('Back to all communities'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
