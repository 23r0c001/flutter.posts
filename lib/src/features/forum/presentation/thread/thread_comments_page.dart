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
    final theme = Theme.of(context);
    final muted =
        theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final displayName = comment.author?.displayName;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author + relative timestamp on the same line so each
              // comment "header" reads naturally: "Sam · 5m ago".
              Row(
                children: [
                  if (displayName != null) ...[
                    Flexible(
                      child: Text(
                        displayName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('  ·  ', style: muted),
                  ],
                  Text(_formatRelativeTime(comment.createdAt), style: muted),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(comment.body),
              ),
              _CommentLikeBar(comment: comment),
            ],
          ),
        ),
      ),
    );
  }
}

/// Heart icon + like count row at the bottom of each comment.
///
/// Tapping fires `ThreadCubit.toggleCommentLike` which performs an
/// optimistic update before the network round-trip, so the icon /
/// count flip happens instantly.
class _CommentLikeBar extends StatelessWidget {
  final Comment comment;

  const _CommentLikeBar({required this.comment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    return Row(
      children: [
        IconButton(
          icon: Icon(
            comment.likedByMe ? Icons.favorite : Icons.favorite_border,
            size: 20,
            color: comment.likedByMe ? activeColor : null,
          ),
          tooltip: comment.likedByMe ? 'Unlike' : 'Like',
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(),
          onPressed: () =>
              context.read<ThreadCubit>().toggleCommentLike(comment.id),
        ),
        const SizedBox(width: 2),
        Text(
          '${comment.likeCount}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: comment.likedByMe
                ? activeColor
                : theme.colorScheme.onSurfaceVariant,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Format a past `DateTime` as a compact relative string
/// ("just now", "5m ago", "3h ago", "2d ago", "Mar 4").
///
/// Kept inline to avoid pulling in a dependency for one widget.
/// Falls back to a short absolute date once differences exceed a
/// week so timestamps stay informative on long-lived threads.
String _formatRelativeTime(DateTime when) {
  final diff = DateTime.now().difference(when);
  if (diff.inSeconds < 45) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[when.month - 1]} ${when.day}';
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
