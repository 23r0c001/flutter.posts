import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

/// Plain-Dart authenticated user.
///
/// LAYER RULE: this is the `domain/` representation — no Supabase types
/// leak out. Widgets, blocs, and other features import THIS, not `User`
/// from `supabase_flutter`. If we ever swap Supabase for a different
/// auth backend, only `AuthUser.fromSupabaseUser` changes.
///
/// `Equatable` lets bloc states containing an `AuthUser` short-circuit
/// equality (so the bloc doesn't emit duplicate states when the same
/// user comes through the stream twice).
class AuthUser extends Equatable {
  /// Stable, Supabase-issued user UUID. Matches `auth.users.id` and is
  /// the FK target for `public.profiles.id`.
  final String id;

  /// Email address. Always present for magic-link signups; usually
  /// present for OAuth signups (Google always provides it; Apple lets
  /// users hide it behind a private relay).
  final String? email;

  /// Display name, sourced from OAuth metadata (`full_name`) or the
  /// local part of the email for magic-link signups. Mirrors what the
  /// `handle_new_user` Postgres trigger writes to `profiles.display_name`.
  final String? displayName;

  /// Optional avatar URL, sourced from OAuth metadata.
  final String? avatarUrl;

  const AuthUser({
    required this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
  });

  /// Build an `AuthUser` from Supabase's `User` type. Only called from
  /// inside `data/auth_repository.dart` — keeps Supabase types contained
  /// at the data boundary.
  factory AuthUser.fromSupabaseUser(supa.User user) {
    final meta = user.userMetadata ?? const <String, dynamic>{};
    // OAuth providers stash the display name under different keys.
    // Google uses `full_name`, Apple uses `name`, magic-link has neither.
    final displayName = (meta['full_name'] ??
            meta['name'] ??
            meta['preferred_username']) as String?;
    return AuthUser(
      id: user.id,
      email: user.email,
      displayName: displayName,
      avatarUrl: meta['avatar_url'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, email, displayName, avatarUrl];
}
