import 'package:flutter/material.dart';

/// Placeholder center-pane content for the "Me" section.
class MeHomePage extends StatelessWidget {
  const MeHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Me', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(
          'This is placeholder personal space content. '
          'Profile, drafts, and settings can live here next.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}
