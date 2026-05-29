import 'package:equatable/equatable.dart';

/// A community / subforum. Maps 1:1 to a row in `public.communities`.
///
/// Identified by `slug` in URLs (`/t/autism-support`) and by `id`
/// in foreign keys (posts reference `community_id`). Both are
/// available so callers don't need to make extra lookups.
class Community extends Equatable {
  final String id;
  final String slug;
  final String name;
  final String? description;
  final DateTime createdAt;

  const Community({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    required this.createdAt,
  });

  /// Parses a row from `from('communities').select()`. Throws if
  /// required fields are missing — that's a server contract violation
  /// and should fail loud.
  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, slug, name, description, createdAt];
}
