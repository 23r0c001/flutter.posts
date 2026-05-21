/// Format a past `DateTime` as a compact relative string
/// ("just now", "5m ago", "3h ago", "2d ago", "Mar 4").
///
/// Falls back to a short absolute date (`Mon D`) once the difference
/// exceeds a week so timestamps stay informative on long-lived
/// threads without needing a full date library.
///
/// Lives in `core/util` (not in a feature folder) because both the
/// forum feed and the thread comment list call it; keeping it here
/// avoids a feature-to-feature import.
String formatRelativeTime(DateTime when) {
  final diff = DateTime.now().difference(when);
  if (diff.inSeconds < 45) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[when.month - 1]} ${when.day}';
}
