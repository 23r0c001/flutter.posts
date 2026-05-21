import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// "Me" settings page.
///
/// Presents as a full-screen modal-style page with its own app bar (so
/// the shell's mobile app bar is suppressed for this route). Tap the
/// close icon to pop back to the Me root.
///
/// PHASE 1: empty body.
/// LATER: account info, sign-out, notification prefs, etc.
class MeSettingsPage extends StatelessWidget {
  const MeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
          tooltip: 'Close settings',
        ),
        title: const Text('Settings'),
      ),
      body: const SizedBox.expand(),
    );
  }
}
