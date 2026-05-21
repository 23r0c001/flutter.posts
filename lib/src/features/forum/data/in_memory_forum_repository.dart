import 'package:flutter_posts/src/core/error/app_error.dart';
import 'package:flutter_posts/src/features/forum/data/forum_repository.dart';
import 'package:flutter_posts/src/features/forum/data/models/author_summary.dart';
import 'package:flutter_posts/src/features/forum/data/models/comment.dart';
import 'package:flutter_posts/src/features/forum/data/models/community.dart';
import 'package:flutter_posts/src/features/forum/data/models/post.dart';
import 'package:meta/meta.dart';

/// `ForumRepository` that serves an in-memory fixture set.
///
/// Two purposes:
///
///   1. **Offline dev mode.** `app.dart` instantiates this when
///      `Env.isConfigured` is false so the forum UI is browseable
///      without a Supabase project.
///
///   2. **Unit / widget tests.** Construct with `seed: false` to start
///      empty, then push fixtures via `addCommunity` / `addPost` /
///      `addComment`. Inject a fixed clock so `createdAt` timestamps
///      and `id` values are deterministic.
///
/// Test-oriented design notes:
///   - Default `latency` is `Duration.zero` so tests don't have to
///     pump extra time. Production dev mode opts into a small delay.
///   - IDs are counter-based (`_nextId`), so two repositories with the
///     same `seed` + same `now` produce byte-identical data.
///   - `now` is injectable for deterministic timestamps in tests.
///   - All mutating methods (`createPost`, `createComment`) persist
///     into the same maps, so the "I posted, then I see it" UX works
///     both in offline dev mode and in tests that exercise that flow.
class InMemoryForumRepository implements ForumRepository {
  /// [seed] populates a built-in fixture set (6 communities matching
  /// the Supabase seed migration, 5 posts each, varied comment counts).
  /// Tests typically want `seed: false` so they can set up exactly
  /// the rows they care about.
  ///
  /// [latency] is the artificial delay applied to each method.
  /// Default zero (test-friendly).
  ///
  /// [now] is the clock used for timestamps on rows created at
  /// runtime (via `createPost` / `createComment`). Defaults to
  /// `DateTime.now`. Tests should pass a fixed-time function for
  /// deterministic assertions.
  InMemoryForumRepository({
    bool seed = true,
    this.latency = Duration.zero,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    if (seed) _seedDefaultFixture();
  }

  /// Artificial latency applied to each method.
  final Duration latency;

  final DateTime Function() _now;

  // Storage. Mutable so the create methods can append. Exposed (via
  // `addCommunity` / `addPost` / `addComment`) for tests; the offline-
  // dev path doesn't touch them directly.
  final List<Community> _communities = [];
  final Map<String, List<Post>> _postsByCommunity = {};
  final Map<String, List<Comment>> _commentsByPost = {};

  /// Likes keyed by comment id → set of user ids who liked it.
  /// `likeCount` and `likedByMe` are derived from this on every
  /// `listComments` call so the model fields don't drift.
  final Map<String, Set<String>> _likesByComment = {};

  /// "Current user" in offline-dev mode. Mirrors the dev user that
  /// `InMemoryAuthRepository` reports and matches `_defaultAuthors.first`.
  String get _currentUserId => _defaultAuthors.first.id;

  /// Monotonically increasing counter for ID generation. Deterministic
  /// across runs given identical seed / addX call order.
  int _idCounter = 0;

  /// Stable base instant for built-in seed data. A specific past
  /// instant so newly created rows (from `createPost`) are always more
  /// recent and surface at the top of feeds.
  static final DateTime _seedTime = DateTime.utc(2026, 5, 1, 12);

  /// Default fake authors, used by the built-in seed. One of them
  /// matches `InMemoryAuthRepository.defaultUser.id` so "your" posts
  /// in offline dev mode look like they belong to the dev user.
  static const List<AuthorSummary> _defaultAuthors = [
    AuthorSummary(
      id: '00000000-0000-0000-0000-000000000001',
      displayName: 'Dev User',
    ),
    AuthorSummary(
      id: '00000000-0000-0000-0000-000000000002',
      displayName: 'Sam',
    ),
    AuthorSummary(
      id: '00000000-0000-0000-0000-000000000003',
      displayName: 'Riley',
    ),
    AuthorSummary(
      id: '00000000-0000-0000-0000-000000000004',
      displayName: 'Jordan',
    ),
  ];

  // ---------------------------------------------------------------------------
  // ForumRepository
  // ---------------------------------------------------------------------------

  @override
  Future<List<Community>> listCommunities() async {
    await _wait();
    final sorted = [..._communities]..sort((a, b) => a.name.compareTo(b.name));
    return List.unmodifiable(sorted);
  }

  @override
  Future<Community?> getCommunityBySlug(String slug) async {
    await _wait();
    for (final c in _communities) {
      if (c.slug == slug) return c;
    }
    return null;
  }

  @override
  Future<List<Post>> listPosts(String communityId, {int limit = 30}) async {
    await _wait();
    final posts = _postsByCommunity[communityId] ?? const [];
    final sorted = [...posts]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(sorted.take(limit));
  }

  @override
  Future<Post> getPost(String postId) async {
    await _wait();
    for (final list in _postsByCommunity.values) {
      for (final p in list) {
        if (p.id == postId) return p;
      }
    }
    throw const AppError(
      kind: AppErrorKind.server,
      userMessage: 'That post no longer exists.',
    );
  }

  @override
  Future<Post> createPost({
    required String communityId,
    required String title,
    String? body,
  }) async {
    await _wait();
    final t = _now();
    final post = Post(
      id: _nextId('p'),
      communityId: communityId,
      authorId: _defaultAuthors.first.id,
      title: title,
      body: body,
      createdAt: t,
      updatedAt: t,
      author: _defaultAuthors.first,
    );
    addPost(post);
    return post;
  }

  @override
  Future<List<Comment>> listComments(String postId) async {
    await _wait();
    final comments = _commentsByPost[postId] ?? const [];
    final sorted = [...comments]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    // Overlay live like state from `_likesByComment` so the in-memory
    // repo's `likeCount` / `likedByMe` stay consistent with whatever
    // `likeComment` / `unlikeComment` have set since the comment was
    // first added.
    final withLikes = sorted.map((c) {
      final likers = _likesByComment[c.id];
      return c.copyWith(
        likeCount: likers?.length ?? 0,
        likedByMe: likers?.contains(_currentUserId) ?? false,
      );
    }).toList(growable: false);
    return List.unmodifiable(withLikes);
  }

  @override
  Future<Comment> createComment({
    required String postId,
    String? parentCommentId,
    required String body,
  }) async {
    await _wait();
    final t = _now();
    final comment = Comment(
      id: _nextId('cm'),
      postId: postId,
      authorId: _defaultAuthors.first.id,
      parentCommentId: parentCommentId,
      body: body,
      createdAt: t,
      updatedAt: t,
      author: _defaultAuthors.first,
    );
    addComment(comment);
    return comment;
  }

  @override
  Future<void> likeComment(String commentId) async {
    await _wait();
    _likesByComment.putIfAbsent(commentId, () => <String>{}).add(_currentUserId);
  }

  @override
  Future<void> unlikeComment(String commentId) async {
    await _wait();
    final likers = _likesByComment[commentId];
    if (likers == null) return;
    likers.remove(_currentUserId);
    if (likers.isEmpty) _likesByComment.remove(commentId);
  }

  // ---------------------------------------------------------------------------
  // Test hooks. Public on purpose. Offline-dev mode doesn't call these
  // directly — it relies on `seed: true` in the constructor. Tests
  // typically construct with `seed: false` and use these to set up
  // exactly the data they're asserting against.
  // ---------------------------------------------------------------------------

  /// Add a community to the repository. Visible for tests.
  @visibleForTesting
  void addCommunity(Community community) => _communities.add(community);

  /// Add a post to its community's list. Visible for tests.
  @visibleForTesting
  void addPost(Post post) =>
      _postsByCommunity.putIfAbsent(post.communityId, () => []).insert(0, post);

  /// Add a comment to its post's list. Visible for tests.
  @visibleForTesting
  void addComment(Comment comment) =>
      _commentsByPost.putIfAbsent(comment.postId, () => []).add(comment);

  /// Mint the next deterministic ID. Visible for tests that build
  /// rows directly via `addX` and need stable IDs that won't collide
  /// with rows minted by `createPost` / `createComment`.
  @visibleForTesting
  String nextId(String prefix) => _nextId(prefix);

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  String _nextId(String prefix) {
    _idCounter++;
    return '$prefix-$_idCounter';
  }

  Future<void> _wait() {
    if (latency == Duration.zero) return Future<void>.value();
    return Future<void>.delayed(latency);
  }

  /// Build the offline-dev fixture set. Mirrors slugs in the Supabase
  /// seed migration so switching backends doesn't change URL shape.
  void _seedDefaultFixture() {
    final communitySeeds = <_CommunitySeed>[
      _CommunitySeed(
          'intro', 'Welcome', 'Introduce yourself and meet others. Start here.'),
      _CommunitySeed('autism-support', 'Autism Support',
          'Parents and caregivers of people on the autism spectrum.'),
      _CommunitySeed("downs-community", "Down's Community",
          "For families of people with Down's syndrome."),
      _CommunitySeed('cerebral-palsy', 'Cerebral Palsy',
          'Resources and conversations for families dealing with CP.'),
      _CommunitySeed('iep-and-school', 'IEP & School',
          'Navigating IEPs, 504s, and the school system.'),
      _CommunitySeed('siblings', 'Siblings',
          'Conversations for siblings of people with disabilities.'),
    ];

    const postBodies = <String>[
      'First time here — looking forward to connecting with this community.',
      'Has anyone dealt with this before? Would love to hear how you handled it.',
      'Just had a hard week. Could use some support.',
      "Sharing something that worked for us — maybe it'll help someone else.",
      'Quick question for anyone with experience here.',
    ];
    const commentBodies = <String>[
      'Thanks for sharing — this resonated with me.',
      'We went through something similar last year. Happy to talk if it helps.',
      'Sending you good thoughts.',
      'Have you tried looking at this from a different angle?',
      "You're not alone in this.",
    ];

    // Indices are explicit so the seed produces byte-identical output
    // regardless of host clock / RNG.
    for (int ci = 0; ci < communitySeeds.length; ci++) {
      final seed = communitySeeds[ci];
      final communityId = _nextId('c');
      addCommunity(
        Community(
          id: communityId,
          slug: seed.slug,
          name: seed.name,
          description: seed.description,
          createdAt: _seedTime,
        ),
      );

      // 5 posts per community, each newer than the last.
      for (int pi = 0; pi < 5; pi++) {
        final author = _defaultAuthors[(ci + pi) % _defaultAuthors.length];
        final createdAt = _seedTime.add(Duration(hours: ci * 24 + pi * 6));
        final post = Post(
          id: _nextId('p'),
          communityId: communityId,
          authorId: author.id,
          title: 'Sample post ${pi + 1} in ${seed.name}',
          body: postBodies[pi % postBodies.length],
          createdAt: createdAt,
          updatedAt: createdAt,
          author: author,
        );
        addPost(post);

        // Variable comment counts (0, 1, 3, 5, 2) so the dev UI covers
        // empty + populated thread layouts.
        const commentCounts = [0, 1, 3, 5, 2];
        final commentCount = commentCounts[pi];
        for (int xi = 0; xi < commentCount; xi++) {
          final commentAuthor =
              _defaultAuthors[(pi + xi + 1) % _defaultAuthors.length];
          final commentAt = createdAt.add(Duration(minutes: xi * 17));
          final commentId = _nextId('cm');
          addComment(
            Comment(
              id: commentId,
              postId: post.id,
              authorId: commentAuthor.id,
              parentCommentId: null,
              body: commentBodies[xi % commentBodies.length],
              createdAt: commentAt,
              updatedAt: commentAt,
              author: commentAuthor,
            ),
          );
          // Seed a deterministic spread of likes so dev mode shows
          // a mix of liked / unliked + non-zero counts. Every 3rd
          // comment is liked by the dev user so the heart toggles.
          final likers = <String>{};
          for (int li = 0; li < (xi % 4); li++) {
            likers.add(_defaultAuthors[li].id);
          }
          if (xi % 3 == 0) likers.add(_currentUserId);
          if (likers.isNotEmpty) _likesByComment[commentId] = likers;
        }
      }
    }
  }
}

/// Internal value class for the seed-data tuples.
class _CommunitySeed {
  final String slug;
  final String name;
  final String description;
  const _CommunitySeed(this.slug, this.name, this.description);
}
