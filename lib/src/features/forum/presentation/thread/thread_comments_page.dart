import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_posts/src/core/util/relative_time.dart';
import 'package:flutter_posts/src/features/forum/data/forum_repository.dart';
import 'package:flutter_posts/src/features/forum/data/models/comment.dart';
import 'package:flutter_posts/src/features/forum/data/models/post.dart';
import 'package:flutter_posts/src/features/forum/presentation/thread/cubit/thread_cubit.dart';

/// Thread detail: post header + flat comment list.
///
/// PHASE 4: backed by `ThreadCubit` which loads post + comments in
/// parallel from Supabase. Nested threading (`parent_comment_id`)
/// is flattened — v2 will add tree rendering.
///
/// LAYOUT: post header sits flat at the top of the list (no card),
/// followed by a "N Comments" section header and a divider-separated
/// stack of full-width comment rows. Matches the Reddit/WTE pattern
/// and stays consistent with the feed list one level up.
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
      child: const _ThreadView(),
    );
  }
}

// Match the feed's row padding so the post header and comment rows
// line up under everything that came before in the navigation stack.
const double _kRowHPad = 16;
const double _kRowVPad = 14;

class _ThreadView extends StatelessWidget {
  const _ThreadView();

  @override
  Widget build(BuildContext context) {
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
              child: _ThreadList(post: post, comments: comments),
            ),
        };
      },
    );
  }
}

/// The actual list — header, section divider, comments. Kept separate
/// so the `BlocBuilder` above stays readable.
class _ThreadList extends StatelessWidget {
  final Post post;
  final List<Comment> comments;

  const _ThreadList({required this.post, required this.comments});

  @override
  Widget build(BuildContext context) {
    final divider = Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
    );

    // `ListView.builder` would mean a lot of `if (index == 0)` plumbing
    // for a tree this small; a plain `ListView` with explicit children
    // is clearer and the comment list rarely has hundreds of entries.
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _PostHeader(post: post),
        divider,
        _CommentsSectionHeader(count: comments.length),
        divider,
        if (comments.isEmpty)
          const _EmptyCommentsState()
        else
          for (int i = 0; i < comments.length; i++) ...[
            _CommentTile(comment: comments[i]),
            divider,
          ],
      ],
    );
  }
}

class _PostHeader extends StatelessWidget {
  final Post post;

  const _PostHeader({required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final displayName = post.author?.displayName;

    return Container(
      width: double.infinity,
      color: theme.colorScheme.surface,
      padding:
          const EdgeInsets.fromLTRB(_kRowHPad, 16, _kRowHPad, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metadata before title (Reddit pattern). Reads like:
          // "Sam · 5m ago" with the title underneath.
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
          const SizedBox(height: 6),
          Text(
            post.title,
            style: theme.textTheme.headlineSmall,
          ),
          if (post.body != null && post.body!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(post.body!, style: theme.textTheme.bodyLarge),
          ],
        ],
      ),
    );
  }
}

/// "12 Comments" subhead between the post and the comment list.
///
/// Pluralizes naively (no localization) — that's fine for v1.
class _CommentsSectionHeader extends StatelessWidget {
  final int count;

  const _CommentsSectionHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = count == 1 ? '1 Comment' : '$count Comments';
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surface,
      padding:
          const EdgeInsets.fromLTRB(_kRowHPad, 12, _kRowHPad, 12),
      child: Text(
        label,
        style: theme.textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.w600),
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
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final displayName = comment.author?.displayName;

    return Container(
      width: double.infinity,
      color: theme.colorScheme.surface,
      // Trim bottom padding because the like bar's IconButton already
      // contributes ~6px of touch slop; otherwise rows look gappy.
      padding: const EdgeInsets.fromLTRB(_kRowHPad, _kRowVPad, _kRowHPad, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (displayName != null) ...[
                Flexible(
                  child: Text(
                    displayName,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('  ·  ', style: muted),
              ],
              Text(formatRelativeTime(comment.createdAt), style: muted),
            ],
          ),
          const SizedBox(height: 6),
          Text(comment.body),
          _CommentLikeBar(comment: comment),
        ],
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
        // Negative left padding via `Transform.translate` would be
        // hacky; instead the IconButton's own padding pulls the heart
        // visually flush with the comment's leading edge.
        IconButton(
          icon: Icon(
            comment.likedByMe ? Icons.favorite : Icons.favorite_border,
            size: 20,
            color: comment.likedByMe ? activeColor : null,
          ),
          tooltip: comment.likedByMe ? 'Unlike' : 'Like',
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
          constraints: const BoxConstraints(),
          onPressed: () =>
              context.read<ThreadCubit>().toggleCommentLike(comment.id),
        ),
        const SizedBox(width: 6),
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

class _EmptyCommentsState extends StatelessWidget {
  const _EmptyCommentsState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surface,
      padding:
          const EdgeInsets.symmetric(horizontal: _kRowHPad, vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.mode_comment_outlined,
            size: 36,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          Text(
            'No comments yet. Be the first.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
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
