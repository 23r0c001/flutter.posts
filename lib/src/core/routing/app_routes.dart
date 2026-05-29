/// Central place for route segment constants and path-builder helpers.
///
/// Lives under `core/routing/` because routing is cross-feature plumbing;
/// every feature consumes the same route table. Keeping these in one file
/// makes it easy to switch from `/t` to `/r` later (Reddit-style group
/// prefix evolution) without chasing string literals across the codebase.
///
/// Rule: never hand-build route paths at call sites. Always go through
/// the helpers below (`groupPath`, `threadPath`, etc.) so that route
/// shape changes are a one-file diff.
library;

class AppRoutes {
  /// Top-level shell section: community feed (Reddit-style "home").
  static const String communityPath = '/';

  /// Top-level shell section: user profile / settings.
  static const String mePath = '/me';

  /// Settings drill-down under the Me branch.
  static const String settingsPath = '/me/settings';

  /// Sign-in route shown by the `AuthGate` when the user is signed out.
  ///
  /// Lives outside the `StatefulShellRoute` so the sidebar/resources
  /// chrome isn't rendered behind the sign-in flow.
  static const String signInPath = '/sign-in';

  /// Confirmation screen shown after a magic-link email is dispatched.
  static const String magicLinkSentPath = '/sign-in/magic-link-sent';

  /// Temporary group prefix (`/t`) while we iterate on the URL scheme.
  /// Change this constant if we ever switch to `/r` to mimic Reddit.
  static const String groupPrefix = 't';

  /// Segment for thread-style comment pages (`/t/<group>/comments/<id>`).
  static const String commentsSegment = 'comments';

  /// Builds a path for a single group feed page.
  ///
  /// Example: `groupPath(group: 'autism-support')` → `/t/autism-support`.
  static String groupPath({
    required String group,
  }) {
    return '/$groupPrefix/$group';
  }

  /// Builds a path for a single thread within a group.
  ///
  /// Example: `threadPath(group: 'autism-support', threadId: 'abc-123')`
  ///   → `/t/autism-support/comments/abc-123`.
  ///
  /// Callers MUST go through this helper rather than concatenating strings
  /// so the URL shape stays consistent across feed cards, push handlers,
  /// share sheets, and deep links.
  static String threadPath({
    required String group,
    required String threadId,
  }) {
    return '/$groupPrefix/$group/$commentsSegment/$threadId';
  }
}
