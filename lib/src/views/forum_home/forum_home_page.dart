import 'package:flutter/material.dart';

import '../../shared/widgets/responsive_layout.dart';
import 'widgets/resources_pane.dart';
import 'widgets/sidebar_widget.dart';

class ForumHomePage extends StatelessWidget {
  final Widget child;

  const ForumHomePage({super.key, required this.child});

  @override
  /// Builds the forum shell and delegates responsive behavior to shared layout.
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayout(
        desktop: _buildDesktopLayout(child),
        mobile: _buildMobileLayout(child),
      ),
    );
  }

  /// Desktop 2/5/3 split:
  /// Sidebar | Route child (feed/detail) | Resources pane.
  Widget _buildDesktopLayout(Widget centerChild) {
    return Row(
      children: [
        const Expanded(flex: 2, child: SidebarWidget()),
        Expanded(flex: 5, child: centerChild),
        const Expanded(flex: 3, child: ResourcesPane()),
      ],
    );
  }

  /// Mobile keeps only the active route child to maximize available space.
  Widget _buildMobileLayout(Widget centerChild) {
    return centerChild;
  }
}
