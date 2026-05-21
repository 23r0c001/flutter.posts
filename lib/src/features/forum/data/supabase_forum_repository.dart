import 'package:flutter_posts/src/core/error/app_error.dart';
import 'package:flutter_posts/src/features/forum/data/forum_repository.dart';
import 'package:flutter_posts/src/features/forum/data/models/comment.dart';
import 'package:flutter_posts/src/features/forum/data/models/community.dart';
import 'package:flutter_posts/src/features/forum/data/models/post.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Production `ForumRepository` backed by Supabase Postgres queries.
///
/// LAYER RULE: only file in `features/forum/` that imports
/// `supabase_flutter`. Cubits / UI consume the `ForumRepository`
/// interface and never touch Supabase or PostgREST directly.
class SupabaseForumRepository implements ForumRepository {
  /// Defaulted to `Supabase.instance.client`; override for tests.
  final SupabaseClient _supabase;

  SupabaseForumRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // Communities
  // ---------------------------------------------------------------------------

  @override
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

  @override
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

  /// Joins `profiles:author_id` so each post arrives with its author's
  /// display name / avatar, avoiding an N+1 lookup in the UI.
  @override
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

  @override
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

  /// RLS guarantees `author_id == auth.uid()`; we pass the current
  /// user explicitly so the call fails fast if somehow signed out.
  @override
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

  @override
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

  @override
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

  /// PostgREST returns `List<dynamic>` of `Map<String, dynamic>`. The
  /// casting + mapping is identical for every list query — extracted
  /// here so each method stays compact.
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
