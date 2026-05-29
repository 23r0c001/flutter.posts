import 'package:equatable/equatable.dart';

import 'author_summary.dart';

/// A comment on a post. Maps 1:1 to a row in `public.comments`.
///
/// Threading: `parentCommentId` is null for top-level comments and
/// points at another comment for nested replies. v1 renders a flat
/// list ordered by `createdAt`; nested rendering is a v2 polish item.
///
/// Likes: `likeCount` is denormalized from the `like_count` column on
/// the row (kept in sync by a DB trigger over `comment_likes`).
/// `likedByMe` is NOT part of the row — it's set by the repository
/// after a parallel lookup against `comment_likes` for the current
/// `auth.uid()` and merged onto each comment. Defaults to false so
/// any path that constructs a `Comment` without that lookup (tests,
/// in-memory dev mode, optimistic UI) still produces a valid object.
class Comment extends Equatable {
  final String id;
  final String postId;
  final String authorId;

  /// Null for top-level comments; points at another comment for replies.
  final String? parentCommentId;

  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Joined author info when the query includes `profiles:author_id(...)`.
  final AuthorSummary? author;

  /// Total like count. Mirrors `comments.like_count`.
  final int likeCount;

  /// Whether the current signed-in user has liked this comment.
  /// Populated client-side by the repository, not stored on the row.
  final bool likedByMe;

  const Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    this.parentCommentId,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.author,
    this.likeCount = 0,
    this.likedByMe = false,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final rawAuthor = json['profiles'] ?? json['author'];
    return Comment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      authorId: json['author_id'] as String,
      parentCommentId: json['parent_comment_id'] as String?,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      author: rawAuthor is Map<String, dynamic>
          ? AuthorSummary.fromJson(rawAuthor)
          : null,
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      // `likedByMe` is never in the row — repositories overlay this
      // after a separate query against `comment_likes`.
    );
  }

  /// Returns a copy with the given fields replaced. Used by the
  /// cubit for optimistic like toggles.
  Comment copyWith({
    int? likeCount,
    bool? likedByMe,
  }) {
    return Comment(
      id: id,
      postId: postId,
      authorId: authorId,
      parentCommentId: parentCommentId,
      body: body,
      createdAt: createdAt,
      updatedAt: updatedAt,
      author: author,
      likeCount: likeCount ?? this.likeCount,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }

  @override
  List<Object?> get props => [
        id,
        postId,
        authorId,
        parentCommentId,
        body,
        createdAt,
        updatedAt,
        author,
        likeCount,
        likedByMe,
      ];
}
