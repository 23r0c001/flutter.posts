import 'package:supabase_flutter/supabase_flutter.dart';

/// Unified application error type.
///
/// Repositories catch backend / network exceptions and re-throw as
/// `AppError`. Cubits/blocs catch `AppError` and emit error states.
/// Widgets render `state.error.userMessage` — they never see raw
/// Supabase, PostgREST, or HTTP exception types.
///
/// This keeps the UI free of backend coupling: if we ever swap Supabase
/// out for raw Postgres + a Dart server, only the mapper changes.
class AppError implements Exception {
  /// Short, machine-readable category (used for logging / branching).
  final AppErrorKind kind;

  /// Human-facing message safe to show in toasts / error UI.
  ///
  /// Should be calm and actionable. The audience is parents of disabled
  /// kids — they don't need to see stack traces or PostgREST codes.
  final String userMessage;

  /// The original exception, kept for logging / diagnostics. Never shown
  /// to users.
  final Object? cause;

  /// Stack trace from the original throw site, when available.
  final StackTrace? stackTrace;

  const AppError({
    required this.kind,
    required this.userMessage,
    this.cause,
    this.stackTrace,
  });

  @override
  String toString() => 'AppError(${kind.name}): $userMessage';
}

/// Coarse categorization of errors. Add new kinds sparingly — too many
/// granular kinds defeats the point of having a single error type.
enum AppErrorKind {
  /// Catch-all for anything we couldn't classify.
  unknown,

  /// Network unreachable, timeout, DNS failure, offline, etc.
  network,

  /// Auth failed (bad token, expired session, OAuth cancelled, etc.).
  auth,

  /// Server returned 4xx or 5xx with no more specific category.
  server,

  /// Constraint violation (unique, foreign key) or RLS denial.
  permission,

  /// Validation failed before we even sent the request.
  validation,
}

/// Maps Supabase / PostgREST exceptions into a domain-friendly
/// [AppError]. Repositories call this in their `catch` blocks.
///
/// Kept here (in `core/error/`) rather than each repository so we have
/// ONE place to add new mappings as new error types come up.
AppError mapSupabaseError(Object error, [StackTrace? stackTrace]) {
  // AuthException — Supabase auth failures (wrong code, expired link, etc.).
  if (error is AuthException) {
    return AppError(
      kind: AppErrorKind.auth,
      userMessage: _humanizeAuthMessage(error.message),
      cause: error,
      stackTrace: stackTrace,
    );
  }

  // PostgrestException — RLS / constraint / query errors from the DB.
  if (error is PostgrestException) {
    final bool isPermission = error.code == '42501' || // permission denied
        error.code == 'PGRST301'; // RLS row-not-visible
    return AppError(
      kind: isPermission ? AppErrorKind.permission : AppErrorKind.server,
      userMessage: isPermission
          ? "You don't have permission to do that."
          : 'Something went wrong. Please try again.',
      cause: error,
      stackTrace: stackTrace,
    );
  }

  // StorageException — Supabase Storage uploads / signed URL failures.
  if (error is StorageException) {
    return AppError(
      kind: AppErrorKind.server,
      userMessage: 'Could not save or load media. Please try again.',
      cause: error,
      stackTrace: stackTrace,
    );
  }

  // Default — anything we don't recognize is "unknown".
  return AppError(
    kind: AppErrorKind.unknown,
    userMessage: 'Something went wrong. Please try again.',
    cause: error,
    stackTrace: stackTrace,
  );
}

/// Translates raw Supabase auth messages into something a tired caregiver
/// won't be confused by. Returns the input unchanged for messages we
/// don't recognize so we don't accidentally hide actionable info.
String _humanizeAuthMessage(String raw) {
  final lower = raw.toLowerCase();
  if (lower.contains('email rate limit')) {
    return 'Too many requests. Please wait a minute and try again.';
  }
  if (lower.contains('invalid login credentials')) {
    return "We couldn't sign you in with that. Try the magic link instead.";
  }
  if (lower.contains('user already registered')) {
    return 'That email is already in use. Sign in instead.';
  }
  if (lower.contains('jwt expired') || lower.contains('expired')) {
    return 'Your session expired. Please sign in again.';
  }
  return raw;
}
