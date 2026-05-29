import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_posts/src/core/routing/app_routes.dart';
import 'package:flutter_posts/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:go_router/go_router.dart';

/// "Me" branch root.
///
/// Browsing is public, so this page can be reached by guests now. It
/// renders one of two bodies based on `AuthState`:
///   - signed in  → profile + sign-out (`_SignedInBody`).
///   - signed out → a guest CTA inviting sign-in (`_GuestBody`).
/// Transient auth states (sending link / authenticating) briefly fall
/// through to the guest body, which is fine — they resolve in a frame.
class MeHomePage extends StatelessWidget {
  const MeHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthSignedIn) {
          return _SignedInBody(state: state);
        }
        return const _GuestBody();
      },
    );
  }
}

/// Shown on the Me tab when the visitor is browsing as a guest.
class _GuestBody extends StatelessWidget {
  const _GuestBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.person_outline,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                "You're browsing as a guest",
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to post, comment, and like.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.push(AppRoutes.signInPath),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignedInBody extends StatelessWidget {
  final AuthSignedIn state;

  const _SignedInBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final user = state.user;
    // Prefer the display name; fall back to the email; final fallback
    // is the UUID — should never realistically render but keeps the
    // widget safe even on a half-formed user record.
    final headline =
        user.displayName ?? user.email ?? user.id.substring(0, 8);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (user.avatarUrl != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(user.avatarUrl!),
                    ),
                  ),
                ),
              Text(
                'Hi, $headline',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              if (user.email != null) ...[
                const SizedBox(height: 4),
                Text(
                  user.email!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () =>
                    context.read<AuthBloc>().add(const SignOutRequested()),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
