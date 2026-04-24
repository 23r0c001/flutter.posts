import 'package:flutter/material.dart';

/// Placeholder center-pane content for the "Me" section.
class MeHomePage extends StatelessWidget {
  const MeHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn()) {
      return Center(
        child: Text(
          'You are logged in.',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(onPressed: () {}, child: const Text('Log In')),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }

  /// Temporary auth gate until real session/auth state is wired.
  bool _isLoggedIn() {
    return false;
  }
}
