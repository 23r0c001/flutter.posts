import 'package:flutter_posts/src/features/forum/data/models/comment.dart';
import 'package:flutter_posts/src/features/forum/data/models/community.dart';
import 'package:flutter_posts/src/features/forum/data/models/post.dart';

/// Forum data contract.
///
/// LAYER RULE: cubits / UI talk to THIS interface, not to any concrete
/// backend. The production binding is `SupabaseForumRepository`; the
/// dev-without-env binding is `InMemoryForumRepository`. Both implement
/// the same shape so UI behavior is identical across the two.
///
/// All methods are `Future<T>` — Supabase Realtime subscriptions are
/// out of scope for v1 (callers manually refresh by calling these again).
abstract interface class ForumRepository {
  // -- Communities ----------------------------------------------------------

  /// List all visible communities. Ordering is implementation-defined
  /// but stable across calls (e.g., alphabetical).
  Future<List<Community>> listCommunities();

  /// Fetch a community by its URL slug. Returns null if not found —
  /// `slug not found` is a legitimate not-found, not an exception.
  Future<Community?> getCommunityBySlug(String slug);

  // -- Posts ---------------------------------------------------------------

  /// List posts in a community, most-recent-first. [limit] caps the
  /// page size. Pagination is intentionally crude for v1 — `before`
  /// arg gets added when we wire infinite scroll.
  Future<List<Post>> listPosts(String communityId, {int limit = 30});

  /// Fetch a single post by ID. Throws `AppError` on not-found —
  /// callers (`ThreadCubit`) treat that as a hard error.
  Future<Post> getPost(String postId);

  /// Create a post on behalf of the signed-in user. Returns the
  /// freshly inserted row so the UI can prepend it to the feed.
  Future<Post> createPost({
    required String communityId,
    required String title,
    String? body,
  });

  // -- Comments ------------------------------------------------------------

  /// List comments on a post, oldest-first.
  Future<List<Comment>> listComments(String postId);

  /// Create a comment on behalf of the signed-in user.
  Future<Comment> createComment({
    required String postId,
    String? parentCommentId,
    required String body,
  });

  // -- Comment likes -------------------------------------------------------

  /// Like a comment as the signed-in user. Idempotent — liking a
  /// comment that's already liked is a no-op so the UI can retry
  /// safely after a network blip.
  Future<void> likeComment(String commentId);

  /// Remove the signed-in user's like from a comment. Idempotent —
  /// unliking a comment that wasn't liked is a no-op.
  Future<void> unlikeComment(String commentId);
}
