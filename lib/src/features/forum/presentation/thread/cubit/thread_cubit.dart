import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_posts/src/core/error/app_error.dart';
import 'package:flutter_posts/src/features/forum/data/forum_repository.dart';
import 'package:flutter_posts/src/features/forum/data/models/comment.dart';
import 'package:flutter_posts/src/features/forum/data/models/post.dart';

/// Drives `ThreadCommentsPage` — the single-thread view with post body
/// at top and comments below.
///
/// Fetches post + comments in parallel via `Future.wait` to minimize
/// total round-trip time.
class ThreadCubit extends Cubit<ThreadState> {
  final ForumRepository _forumRepository;
  final String _postId;

  ThreadCubit({
    required ForumRepository forumRepository,
    required String postId,
  })  : _forumRepository = forumRepository,
        _postId = postId,
        super(const ThreadInitial());

  /// Load post + comments. Safe to call repeatedly (pull-to-refresh).
  Future<void> load() async {
    emit(const ThreadLoading());
    try {
      // Parallel fetch — keeps thread load time bounded by the slower
      // of the two queries instead of summing them.
      final results = await Future.wait([
        _forumRepository.getPost(_postId),
        _forumRepository.listComments(_postId),
      ]);
      final post = results[0] as Post;
      final comments = results[1] as List<Comment>;
      emit(ThreadLoaded(post: post, comments: comments));
    } on AppError catch (error) {
      emit(ThreadError(error: error));
    } catch (error, stackTrace) {
      emit(ThreadError(error: mapSupabaseError(error, stackTrace)));
    }
  }

  /// Add a comment and append it to the visible list.
  ///
  /// We get the inserted row back (with author joined) so the UI can
  /// render it immediately without a re-fetch.
  Future<void> addComment({
    String? parentCommentId,
    required String body,
  }) async {
    final current = state;
    if (current is! ThreadLoaded) return;
    try {
      final inserted = await _forumRepository.createComment(
        postId: _postId,
        parentCommentId: parentCommentId,
        body: body,
      );
      emit(
        ThreadLoaded(
          post: current.post,
          comments: [...current.comments, inserted],
        ),
      );
    } on AppError catch (error) {
      emit(ThreadError(error: error));
    }
  }
}

/// Sealed state for `ThreadCubit`.
sealed class ThreadState extends Equatable {
  const ThreadState();

  @override
  List<Object?> get props => const [];
}

class ThreadInitial extends ThreadState {
  const ThreadInitial();
}

class ThreadLoading extends ThreadState {
  const ThreadLoading();
}

class ThreadLoaded extends ThreadState {
  final Post post;
  final List<Comment> comments;

  const ThreadLoaded({required this.post, required this.comments});

  @override
  List<Object?> get props => [post, comments];
}

class ThreadError extends ThreadState {
  final AppError error;

  const ThreadError({required this.error});

  @override
  List<Object?> get props => [error];
}
