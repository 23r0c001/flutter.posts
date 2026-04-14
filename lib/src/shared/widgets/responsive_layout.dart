import 'package:flutter/material.dart';

/// TEMPLATE: Acts as a View Wrapper for screen-level responsiveness.
/// USAGE: Wrap Feature views (Forums, Profile, Resources) to ensure Web-first scaling.
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return constraints.maxWidth > 800 ? desktop : mobile;
      },
    );
  }
}
