import 'package:equatable/equatable.dart';

import 'author_summary.dart';

/// A forum post. Maps 1:1 to a row in `public.posts`.
///
/// `author` is populated when the query joins `profiles:author_id(...)`,
/// which is the common case for feeds + thread headers. When the query
/// doesn't join, `author` is null and the UI falls back to author ID.
class Post extends Equatable {
  final String id;
  final String communityId;
  final String authorId;
  final String title;
  final String? body;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Joined author info (display_name, avatar_url) when available.
  final AuthorSummary? author;

  const Post({
    required this.id,
    required this.communityId,
    required this.authorId,
    required this.title,
    this.body,
    required this.createdAt,
    required this.updatedAt,
    this.author,
  });

  /// Parses a row from `from('posts').select('..., profiles:author_id(...)')`.
  /// The author join is optional — if absent or null, `author` stays null.
  factory Post.fromJson(Map<String, dynamic> json) {
    final rawAuthor = json['profiles'] ?? json['author'];
    return Post(
      id: json['id'] as String,
      communityId: json['community_id'] as String,
      authorId: json['author_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String?,
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
        communityId,
        authorId,
        title,
        body,
        createdAt,
        updatedAt,
        author,
      ];
}
