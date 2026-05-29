import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_posts/src/core/error/app_error.dart';
import 'package:flutter_posts/src/features/forum/data/forum_repository.dart';
import 'package:flutter_posts/src/features/forum/data/models/community.dart';
import 'package:flutter_posts/src/features/forum/data/models/post.dart';

/// Drives `GroupFeedPage` — the feed of posts inside a single community.
///
/// Resolves the community by slug first (so callers can pass URLs like
/// `/t/autism-support` without doing the lookup themselves), then loads
/// posts. Two failure modes are surfaced separately:
///   - Slug not found → emit `FeedNotFound`.
///   - Network/server error → emit `FeedError`.
class FeedCubit extends Cubit<FeedState> {
  final ForumRepository _forumRepository;
  final String _communitySlug;

  FeedCubit({
    required ForumRepository forumRepository,
    required String communitySlug,
  })  : _forumRepository = forumRepository,
        _communitySlug = communitySlug,
        super(const FeedInitial());

  /// Load the community + its posts. Safe to call multiple times.
  Future<void> load() async {
    emit(const FeedLoading());
    try {
      final community =
          await _forumRepository.getCommunityBySlug(_communitySlug);
      if (community == null) {
        emit(FeedNotFound(slug: _communitySlug));
        return;
      }
      final posts = await _forumRepository.listPosts(community.id);
      emit(FeedLoaded(community: community, posts: posts));
    } on AppError catch (error) {
      emit(FeedError(error: error));
    } catch (error, stackTrace) {
      emit(FeedError(error: mapSupabaseError(error, stackTrace)));
    }
  }

  /// Create a post and prepend it to the feed (optimistic-ish: we
  /// re-fetch the row with author info via the insert's RETURNING).
  Future<void> createPost({
    required String title,
    String? body,
  }) async {
    final current = state;
    if (current is! FeedLoaded) return; // can't post without a community.
    try {
      final newPost = await _forumRepository.createPost(
        communityId: current.community.id,
        title: title,
        body: body,
      );
      emit(
        FeedLoaded(
          community: current.community,
          posts: [newPost, ...current.posts],
        ),
      );
    } on AppError catch (error) {
      emit(FeedError(error: error));
    }
  }
}

/// Sealed state for `FeedCubit`.
sealed class FeedState extends Equatable {
  const FeedState();

  @override
  List<Object?> get props => const [];
}

class FeedInitial extends FeedState {
  const FeedInitial();
}

class FeedLoading extends FeedState {
  const FeedLoading();
}

class FeedLoaded extends FeedState {
  final Community community;
  final List<Post> posts;

  const FeedLoaded({required this.community, required this.posts});

  @override
  List<Object?> get props => [community, posts];
}

/// Distinct state for "slug doesn't resolve to a known community".
/// Lets the UI render a "this community doesn't exist" 404 page
/// instead of a generic error.
class FeedNotFound extends FeedState {
  final String slug;

  const FeedNotFound({required this.slug});

  @override
  List<Object?> get props => [slug];
}

class FeedError extends FeedState {
  final AppError error;

  const FeedError({required this.error});

  @override
  List<Object?> get props => [error];
}
