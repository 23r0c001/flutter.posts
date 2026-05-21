import 'package:flutter_posts/src/core/error/app_error.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/comment.dart';
import 'models/community.dart';
import 'models/post.dart';

/// Forum data access. Wraps Supabase Postgres queries behind a clean
/// Dart-typed API.
///
/// LAYER RULE: only file in `features/forum/` that imports
/// `supabase_flutter`. Cubits / UI consume this and never touch
/// Supabase or PostgREST directly.
///
/// All methods are `Future<T>` — Supabase Realtime subscriptions are
/// out of scope for v1 (we manually refresh by calling these again).
class ForumRepository {
  /// Defaulted to `Supabase.instance.client`; override for tests.
  final SupabaseClient _supabase;

  ForumRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // Communities
  // ---------------------------------------------------------------------------

  /// List all visible communities (RLS handles visibility filtering).
  ///
  /// Ordered alphabetically by name — feed-style ordering (most recent)
  /// would require tracking a community's last-active timestamp which
  /// we don't have yet.
  Future<List<Community>> listCommunities() async {
    try {
      final rows = await _supabase
          .from('communities')
          .select()
          .order('name', ascending: true);
      return _mapList(rows, Community.fromJson);
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// Fetch a community by its URL slug (e.g., "autism-support").
  /// Returns null if not found rather than throwing — `slug not found`
  /// is a legitimate not-found, not an exception.
  Future<Community?> getCommunityBySlug(String slug) async {
    try {
      final row = await _supabase
          .from('communities')
          .select()
          .eq('slug', slug)
          .maybeSingle();
      return row == null ? null : Community.fromJson(row);
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  // ---------------------------------------------------------------------------
  // Posts
  // ---------------------------------------------------------------------------

  /// List posts in a community, most-recent-first.
  ///
  /// [limit] caps the page size. Pagination is intentionally crude for
  /// v1 — when we add infinite scroll, take a [before] timestamp arg
  /// and add `.lt('created_at', before)` to get the next page.
  ///
  /// Joins `profiles:author_id` so each post arrives with its author's
  /// display name / avatar, avoiding an N+1 lookup in the UI.
  Future<List<Post>> listPosts(
    String communityId, {
    int limit = 30,
  }) async {
    try {
      final rows = await _supabase
          .from('posts')
          .select(
            'id, community_id, author_id, title, body, created_at, updated_at, '
            'profiles:author_id(id, display_name, avatar_url)',
          )
          .eq('community_id', communityId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(limit);
      return _mapList(rows, Post.fromJson);
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// Fetch a single post by ID. Throws on not-found — callers
  /// (`ThreadCubit`) treat this as a hard error since reaching a
  /// thread page with an invalid ID means a stale/broken link.
  Future<Post> getPost(String postId) async {
    try {
      final row = await _supabase
          .from('posts')
          .select(
            'id, community_id, author_id, title, body, created_at, updated_at, '
            'profiles:author_id(id, display_name, avatar_url)',
          )
          .eq('id', postId)
          .isFilter('deleted_at', null)
          .single();
      return Post.fromJson(row);
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// Create a post. Returns the freshly inserted row (so the UI can
  /// add it to the feed without re-fetching).
  ///
  /// RLS guarantees `author_id == auth.uid()`; we pass the current
  /// user explicitly so the call fails fast if somehow signed out.
  Future<Post> createPost({
    required String communityId,
    required String title,
    String? body,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw const AppError(
          kind: AppErrorKind.auth,
          userMessage: 'You need to be signed in to post.',
        );
      }
      final inserted = await _supabase
          .from('posts')
          .insert({
            'community_id': communityId,
            'author_id': userId,
            'title': title,
            'body': body,
          })
          .select(
            'id, community_id, author_id, title, body, created_at, updated_at, '
            'profiles:author_id(id, display_name, avatar_url)',
          )
          .single();
      return Post.fromJson(inserted);
    } on AppError {
      rethrow;
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  // ---------------------------------------------------------------------------
  // Comments
  // ---------------------------------------------------------------------------

  /// List comments on a post, oldest-first (typical thread ordering).
  /// Joins author info for per-comment headers.
  Future<List<Comment>> listComments(String postId) async {
    try {
      final rows = await _supabase
          .from('comments')
          .select(
            'id, post_id, author_id, parent_comment_id, body, created_at, updated_at, '
            'profiles:author_id(id, display_name, avatar_url)',
          )
          .eq('post_id', postId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: true);
      return _mapList(rows, Comment.fromJson);
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// Create a comment. Returns the inserted row with author joined.
  Future<Comment> createComment({
    required String postId,
    String? parentCommentId,
    required String body,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw const AppError(
          kind: AppErrorKind.auth,
          userMessage: 'You need to be signed in to comment.',
        );
      }
      final inserted = await _supabase
          .from('comments')
          .insert({
            'post_id': postId,
            'author_id': userId,
            'parent_comment_id': parentCommentId,
            'body': body,
          })
          .select(
            'id, post_id, author_id, parent_comment_id, body, created_at, updated_at, '
            'profiles:author_id(id, display_name, avatar_url)',
          )
          .single();
      return Comment.fromJson(inserted);
    } on AppError {
      rethrow;
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  /// Helper: PostgREST returns `List<dynamic>` of `Map<String, dynamic>`.
  /// Casting + mapping in one place keeps the per-method calls readable.
  List<T> _mapList<T>(
    List<dynamic> rows,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return rows
        .cast<Map<String, dynamic>>()
        .map(fromJson)
        .toList(growable: false);
  }
}
