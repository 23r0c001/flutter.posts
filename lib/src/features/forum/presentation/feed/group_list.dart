import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_posts/src/core/routing/app_routes.dart';
import 'package:flutter_posts/src/features/forum/data/forum_repository.dart';
import 'package:flutter_posts/src/features/forum/presentation/feed/cubit/communities_cubit.dart';
import 'package:go_router/go_router.dart';

/// Top-level community list (root of the Community branch).
///
/// Self-provides its `CommunitiesCubit` — each navigation to this page
/// gets a fresh cubit, which means the data is refetched. That's fine
/// for v1; once we add `Realtime` or local caching we can move the
/// cubit higher up.
///
/// Layered as `<Provider> -> <View>` so the view can `context.read<...>`
/// the cubit and `BlocBuilder` it.
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
                      padding: const EdgeInsets.all(16),
                      itemCount: communities.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final community = communities[index];
                        final path =
                            AppRoutes.groupPath(group: community.slug);
                        return Card(
                          child: ListTile(
                            title: Text(community.name),
                            subtitle: community.description != null
                                ? Text(
                                    community.description!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            // `push` (not `go`) so back returns to the
                            // list rather than the shell root. See
                            // NavigationRules.md "drill-down" rule.
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No communities yet.\nRun the supabase seed migration to populate.',
          textAlign: TextAlign.center,
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
