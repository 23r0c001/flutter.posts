import 'package:equatable/equatable.dart';

import 'author_summary.dart';

/// A comment on a post. Maps 1:1 to a row in `public.comments`.
///
/// Threading: `parentCommentId` is null for top-level comments and
/// points at another comment for nested replies. v1 renders a flat
/// list ordered by `createdAt`; nested rendering is a v2 polish item.
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

  const Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    this.parentCommentId,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.author,
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
      ];
}
