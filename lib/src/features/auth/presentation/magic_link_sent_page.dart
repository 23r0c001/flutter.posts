import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_posts/src/features/auth/presentation/bloc/auth_bloc.dart';

/// "Check your email" confirmation after a magic link is sent.
///
/// Reachable only when `AuthState` is `AuthLinkSent` — the router's
/// redirect logic in `app_router.dart` puts us here automatically when
/// the bloc transitions to that state.
///
/// We extract `email` from the bloc state (NOT from a constructor
/// argument) because the page may be reached via deep-linked refresh
/// or back-navigation, where there's no route param to thread through.
class MagicLinkSentPage extends StatelessWidget {
  const MagicLinkSentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                // The bloc could move on (e.g., user clicked the link
                // and the deep-link handler signed them in already).
                // In that case fall back to a generic message — the
                // router will redirect us off this page in a moment.
                final email = state is AuthLinkSent ? state.email : 'your email';
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.mark_email_read_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Check your email',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'We sent a sign-in link to $email. Tap the link from this device to finish signing in.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton(
                        // "Use a different email" reverses state by
                        // pretending the user signed out. AuthBloc
                        // re-emits `AuthSignedOut`, router redirects
                        // back to SignInPage.
                        onPressed: () => context
                            .read<AuthBloc>()
                            .add(const SignOutRequested()),
                        child: const Text('Use a different email'),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Didn't get it? Check spam, or wait a minute and try again — Supabase free tier limits sign-in emails to ~4 per hour per address.",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
