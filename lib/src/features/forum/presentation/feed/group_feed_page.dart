import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_posts/src/core/routing/app_routes.dart';
import 'package:flutter_posts/src/core/util/relative_time.dart';
import 'package:flutter_posts/src/features/forum/data/forum_repository.dart';
import 'package:flutter_posts/src/features/forum/data/models/post.dart';
import 'package:flutter_posts/src/features/forum/presentation/feed/cubit/feed_cubit.dart';
import 'package:go_router/go_router.dart';

/// Feed of posts within a single community.
///
/// `group` is the URL slug from the path (`/t/:group`). `FeedCubit`
/// resolves the slug to a `Community` and then loads posts.
///
/// LAYOUT: posts render as edge-to-edge rows separated by a 1px
/// divider (Reddit/WTE-style), NOT as inset rounded cards. Each
/// row's internal padding (`_kRowHPad` / `_kRowVPad`) provides the
/// breathing room; the row itself spans the full width of the
/// containing pane so it looks intentional on both narrow phones
/// and wide desktop center columns.
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

// One source of truth for the horizontal / vertical padding inside a
// feed row. Reused by the community-name header and the empty state
// so the left margin is visually consistent down the whole page.
const double _kRowHPad = 16;
const double _kRowVPad = 12;

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
              child: ListView.separated(
                // Zero horizontal padding so each row spans edge-to-edge.
                // Vertical padding only matters at the very top / bottom.
                padding: EdgeInsets.zero,
                // +1 for the community header at index 0. Empty-state
                // posts get +1 again so RefreshIndicator still has a
                // scrollable child.
                itemCount: posts.length + (posts.isEmpty ? 2 : 1),
                separatorBuilder: (context, _) => Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _CommunityHeader(name: community.name);
                  }
                  if (posts.isEmpty) {
                    return const _EmptyPostsState();
                  }
                  final post = posts[index - 1];
                  return _PostRow(post: post, communitySlug: slug);
                },
              ),
            ),
        };
      },
    );
  }
}

/// Community-name header that sits at the top of the feed.
///
/// Rendered as a flat row so the dividers above the first post and
/// below the header form a continuous panel, rather than the header
/// floating above an indented card list.
class _CommunityHeader extends StatelessWidget {
  final String name;

  const _CommunityHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(_kRowHPad, 16, _kRowHPad, 12),
      child: Text(
        name,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }
}

/// A single post in the community feed.
///
/// Reddit/WTE pattern: author + relative timestamp metadata above the
/// title (rather than the title at the top with author awkwardly
/// trailing). Body is a 2-line preview; tap anywhere opens the thread.
class _PostRow extends StatelessWidget {
  final Post post;
  final String communitySlug;

  const _PostRow({required this.post, required this.communitySlug});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final displayName = post.author?.displayName;

    return Material(
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: () => context.push(
          AppRoutes.threadPath(group: communitySlug, threadId: post.id),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            _kRowHPad,
            _kRowVPad,
            _kRowHPad,
            _kRowVPad,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Metadata row: "Sam · 5m ago".
              Row(
                children: [
                  if (displayName != null) ...[
                    Flexible(
                      child: Text(
                        displayName,
                        style: muted?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('  ·  ', style: muted),
                  ],
                  Text(formatRelativeTime(post.createdAt), style: muted),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                post.title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (post.body != null && post.body!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  post.body!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state rendered as a feed row (rather than a centered island)
/// so it shares the same edge-to-edge layout as everything else and
/// the `RefreshIndicator` above it still has a scrollable.
class _EmptyPostsState extends StatelessWidget {
  const _EmptyPostsState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: _kRowHPad, vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.forum_outlined,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No posts yet.\nBe the first to start a conversation.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
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
