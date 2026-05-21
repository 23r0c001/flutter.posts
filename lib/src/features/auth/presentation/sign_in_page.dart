import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_posts/src/features/auth/presentation/bloc/auth_bloc.dart';

/// The sign-in screen.
///
/// Two flows:
///   1. **Magic link (primary).** Email field + "Send magic link" button.
///      Dispatches `SignInWithMagicLinkRequested`. On success the bloc
///      moves to `AuthLinkSent` and the router redirects to
///      `MagicLinkSentPage`.
///   2. **Google OAuth (secondary).** "Continue with Google" button —
///      dispatches `SignInWithGoogleRequested`, the bloc moves to
///      `AuthAuthenticating` while the browser handles the OAuth flow.
///
/// Apple Sign-In is iOS-only and Phase 5; not yet rendered.
///
/// All button enablement is derived from `AuthState` — we never have to
/// track "is the form submitting" in local widget state.
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submitMagicLink() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final email = _emailController.text.trim();
    context.read<AuthBloc>().add(SignInWithMagicLinkRequested(email));
  }

  void _submitGoogle() {
    context.read<AuthBloc>().add(const SignInWithGoogleRequested());
  }

  void _submitApple() {
    context.read<AuthBloc>().add(const SignInWithAppleRequested());
  }

  /// Apple Sign-In button is rendered ONLY on iOS. App Store Guideline
  /// 4.8 requires offering it whenever third-party social sign-in (like
  /// Google) is present on iOS. Showing it on Android is confusing and
  /// not necessary — Apple's policies don't apply there.
  bool get _shouldShowApple {
    // `kIsWeb` first because `Platform.isIOS` throws on web. v1 doesn't
    // ship web but the guard is cheap insurance.
    if (kIsWeb) return false;
    return Platform.isIOS;
  }

  /// Trivial email regex — Supabase will reject malformed emails too,
  /// this is just an early "please type @ somewhere" UX nudge.
  String? _validateEmail(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'Email is required.';
    }
    final email = raw.trim();
    if (!email.contains('@') || !email.contains('.')) {
      return 'That doesn\'t look like an email address.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No app bar — sign-in is the only place this page renders, and
      // there's nothing to back-navigate to from a signed-out state.
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              // BlocConsumer = BlocBuilder + BlocListener in one. We use
              // `listener` to react to side effects (errors) and
              // `builder` to render the form with state-driven UI.
              child: BlocConsumer<AuthBloc, AuthState>(
                listenWhen: (previous, current) {
                  // Only react when error state appears (skip equal-state
                  // re-emissions and transitions we don't care about).
                  return current is AuthSignedOut &&
                      current.lastError != null &&
                      previous != current;
                },
                listener: (context, state) {
                  if (state is AuthSignedOut && state.lastError != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.lastError!.userMessage),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  final isInFlight = state is AuthSendingLink ||
                      state is AuthAuthenticating;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Sign in',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We\'ll email you a link. No password needed.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Form(
                        key: _formKey,
                        child: TextFormField(
                          controller: _emailController,
                          enabled: !isInFlight,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.go,
                          autocorrect: false,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            // Constrain field height to match buttons.
                            isDense: false,
                          ),
                          validator: _validateEmail,
                          onFieldSubmitted: (_) => _submitMagicLink(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: isInFlight ? null : _submitMagicLink,
                        child: state is AuthSendingLink
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Send magic link'),
                      ),
                      const SizedBox(height: 24),
                      const _OrDivider(),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: isInFlight ? null : _submitGoogle,
                        icon: const Icon(Icons.login),
                        label: state is AuthAuthenticating
                            ? const Text('Opening browser…')
                            : const Text('Continue with Google'),
                      ),
                      if (_shouldShowApple) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: isInFlight ? null : _submitApple,
                          icon: const Icon(Icons.apple),
                          label: const Text('Continue with Apple'),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal "or" divider used between the magic-link form and the
/// OAuth buttons. Pulled out as a private widget so the Column above
/// stays readable.
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outlineVariant;
    return Row(
      children: [
        Expanded(child: Divider(color: color)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'or',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Divider(color: color)),
      ],
    );
  }
}
