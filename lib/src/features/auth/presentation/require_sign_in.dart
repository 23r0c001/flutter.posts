import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_posts/src/core/routing/app_routes.dart';
import 'package:flutter_posts/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:go_router/go_router.dart';

/// Write-action gate for the public-browse model.
///
/// Browsing is open to everyone, but posting / commenting / liking
/// require a session. Call this at the start of any gated action:
///
/// ```dart
/// onPressed: () {
///   if (!ensureSignedIn(context, action: 'like comments')) return;
///   context.read<ThreadCubit>().toggleCommentLike(comment.id);
/// }
/// ```
///
/// Returns `true` if the user is already signed in (caller proceeds).
/// Otherwise it shows a "sign in to join" bottom sheet and returns
/// `false`, so the caller should bail out — the sheet drives the user
/// to the sign-in flow on its own.
///
/// [action] is interpolated into the prompt ("Sign in to {action}"), so
/// pass a short verb phrase like `'like comments'` or `'post'`.
bool ensureSignedIn(BuildContext context, {String action = 'join the conversation'}) {
  if (context.read<AuthBloc>().state is AuthSignedIn) {
    return true;
  }
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => _SignInPromptSheet(action: action),
  );
  return false;
}

/// Bottom sheet shown to guests who tap a gated action.
class _SignInPromptSheet extends StatelessWidget {
  final String action;

  const _SignInPromptSheet({required this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sign in to $action',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You can browse freely, but joining in needs a quick sign-in.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                // Close the sheet first, then route to sign-in so the
                // sheet doesn't linger over the new page.
                Navigator.of(context).pop();
                context.push(AppRoutes.signInPath);
              },
              child: const Text('Sign in'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Not now'),
            ),
          ],
        ),
      ),
    );
  }
}
