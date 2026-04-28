import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Placeholder settings page for the "Me" section.
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
