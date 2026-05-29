import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_posts/src/core/routing/app_routes.dart';
import 'package:flutter_posts/src/features/forum/data/forum_repository.dart';
import 'package:flutter_posts/src/features/forum/data/models/community.dart';
import 'package:flutter_posts/src/features/forum/presentation/feed/cubit/communities_cubit.dart';
import 'package:go_router/go_router.dart';

/// Top-level community list (root of the Community branch).
///
/// Self-provides its `CommunitiesCubit` — each navigation to this page
/// gets a fresh cubit, which means the data is refetched. That's fine
/// for v1; once we add `Realtime` or local caching we can move the
/// cubit higher up.
///
/// LAYOUT: shares the feed's edge-to-edge row pattern — full-width
/// `InkWell` rows separated by a 1px divider, no `Card` inset. Keeps
/// the visual language consistent across the Community branch.
class GroupList extends StatelessWidget {
  const GroupList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CommunitiesCubit(
        forumRepository: context.read<ForumRepository>(),
      )..load(),
      child: const _GroupListView(),
    );
  }
}

const double _kRowHPad = 16;
const double _kRowVPad = 14;

class _GroupListView extends StatelessWidget {
  const _GroupListView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunitiesCubit, CommunitiesState>(
      builder: (context, state) {
        return switch (state) {
          CommunitiesInitial() ||
          CommunitiesLoading() =>
            const Center(child: CircularProgressIndicator()),
          CommunitiesError(:final error) => _ErrorState(
              message: error.userMessage,
              onRetry: context.read<CommunitiesCubit>().load,
            ),
          CommunitiesLoaded(:final communities) =>
            communities.isEmpty
                ? const _EmptyState()
                : RefreshIndicator(
                    onRefresh: context.read<CommunitiesCubit>().load,
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: communities.length,
                      separatorBuilder: (context, _) => Divider(
                        height: 1,
                        thickness: 1,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      itemBuilder: (context, index) {
                        return _CommunityRow(community: communities[index]);
                      },
                    ),
                  ),
        };
      },
    );
  }
}

class _CommunityRow extends StatelessWidget {
  final Community community;

  const _CommunityRow({required this.community});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: InkWell(
        // `push` (not `go`) so back returns to the list rather than
        // the shell root. See NavigationRules.md "drill-down" rule.
        onTap: () =>
            context.push(AppRoutes.groupPath(group: community.slug)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            _kRowHPad,
            _kRowVPad,
            _kRowHPad,
            _kRowVPad,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      community.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (community.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        community.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No communities to show yet.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
