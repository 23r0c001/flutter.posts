import 'package:equatable/equatable.dart';

/// Public author info embedded in joined post/comment queries.
///
/// LAYER: this is a `data/` model. Lives under data/ rather than
/// domain/ because for now it's only used as a sub-record of joined
/// query results. If a feature ever needs an Author concept of its
/// own, promote this to `features/forum/domain/`.
///
/// All fields nullable because `profiles` rows may be incomplete or
/// the join may return null (e.g., user got deleted but post lingers).
class AuthorSummary extends Equatable {
  final String id;
  final String? displayName;
  final String? avatarUrl;

  const AuthorSummary({
    required this.id,
    this.displayName,
    this.avatarUrl,
  });

  /// Parses the `profiles:author_id(...)` shape that PostgREST returns
  /// for foreign-key joins. The shape is:
  ///   { "id": "uuid", "display_name": "...", "avatar_url": "..." }
  factory AuthorSummary.fromJson(Map<String, dynamic> json) {
    return AuthorSummary(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, displayName, avatarUrl];
}
