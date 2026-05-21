import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_posts/src/features/auth/presentation/bloc/auth_bloc.dart';

/// "Me" branch root.
///
/// Only ever renders when `AuthState` is `AuthSignedIn` — the router
/// redirects unauthenticated users to `/sign-in` before this page can
/// be reached. Therefore the BlocBuilder only needs to handle the
/// signed-in case; everything else is defensive fallback.
class MeHomePage extends StatelessWidget {
  const MeHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Defensive fallback. If somehow we're rendered while not
        // signed in, show a generic spinner (the router redirect will
        // kick us back to /sign-in on the next frame).
        if (state is! AuthSignedIn) {
          return const Center(child: CircularProgressIndicator());
        }
        return _SignedInBody(state: state);
      },
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
