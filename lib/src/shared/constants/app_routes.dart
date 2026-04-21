/// Central place for route segment constants.
///
/// Keeping these in one file makes it easy to switch from `/t` to `/r`
/// later without chasing string literals across routing and widgets.
class AppRoutes {
  /// Temporary group prefix (`/t`) while we iterate on routing.
  static const String groupPrefix = 't';

  /// Segment for thread-style comment pages.
  static const String commentsSegment = 'comments';

  /// Utility helper so callers do not hand-build thread paths.
  static String threadPath({
    required String group,
    required String threadId,
  }) {
    return '/$groupPrefix/$group/$commentsSegment/$threadId';
  }
}
