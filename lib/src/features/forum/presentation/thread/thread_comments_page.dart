import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_posts/src/core/navigation/lightbox_controller.dart';
import 'package:flutter_posts/src/core/widgets/responsive_layout.dart';
import 'package:flutter_posts/src/features/forum/data/forum_repository.dart';
import 'package:flutter_posts/src/features/forum/data/models/comment.dart';
import 'package:flutter_posts/src/features/forum/data/models/post.dart';
import 'package:flutter_posts/src/features/forum/presentation/thread/cubit/thread_cubit.dart';

/// Thread detail: post header + flat comment list.
///
/// PHASE 4: backed by `ThreadCubit` which loads post + comments in
/// parallel from Supabase. Nested threading (`parent_comment_id`)
/// is flattened — v2 will add tree rendering.
class ThreadCommentsPage extends StatelessWidget {
  /// URL-supplied post UUID.
  final String threadId;

  const ThreadCommentsPage({super.key, required this.threadId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ThreadCubit(
        forumRepository: context.read<ForumRepository>(),
        postId: threadId,
      )..load(),
      child: ResponsiveLayout(
        desktop: const _ThreadView(isDesktop: true),
        mobile: const _ThreadView(isDesktop: false),
      ),
    );
  }
}

class _ThreadView extends StatelessWidget {
  final bool isDesktop;

  const _ThreadView({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final double horizontalPadding = isDesktop ? 24 : 12;

    return BlocBuilder<ThreadCubit, ThreadState>(
      builder: (context, state) {
        return switch (state) {
          ThreadInitial() ||
          ThreadLoading() =>
            const Center(child: CircularProgressIndicator()),
          ThreadError(:final error) => _ErrorState(
              message: error.userMessage,
              onRetry: context.read<ThreadCubit>().load,
            ),
          ThreadLoaded(:final post, :final comments) => RefreshIndicator(
              onRefresh: context.read<ThreadCubit>().load,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  20,
                  horizontalPadding,
                  24,
                ),
                children: [
                  _PostHeader(post: post, isDesktop: isDesktop),
                  const SizedBox(height: 12),
                  if (comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text('No comments yet. Be the first.'),
                      ),
                    )
                  else
                    ...comments.map((c) => _CommentTile(comment: c)),
                ],
              ),
            ),
        };
      },
    );
  }
}

class _PostHeader extends StatelessWidget {
  final Post post;
  final bool isDesktop;

  const _PostHeader({required this.post, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (post.author?.displayName != null) ...[
              const SizedBox(height: 4),
              Text(
                'by ${post.author!.displayName}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            if (post.body != null && post.body!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(post.body!),
            ],
            const SizedBox(height: 12),
            // Tapping media toggles the lightbox via the global
            // controller. Lightbox overlay lives in `ForumShell`.
            GestureDetector(
              onTap: () =>
                  forumLightboxController.open(mediaId: 'hero-${post.id}'),
              child: Container(
                height: isDesktop ? 280 : 220,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Tap to open embedded media',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (comment.author?.displayName != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    comment.author!.displayName!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              Text(comment.body),
            ],
          ),
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
