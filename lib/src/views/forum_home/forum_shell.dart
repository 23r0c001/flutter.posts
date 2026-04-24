import 'package:flutter/material.dart';

import '../../shared/navigation/lightbox_controller.dart';
import '../../shared/widgets/responsive_layout.dart';
import 'widgets/media_viewer_dialog.dart';
import 'widgets/resources_pane.dart';
import 'widgets/sidebar_widget.dart';

/// Persistent forum shell/layout.
/// Keeps sidebar/resources mounted on desktop while swapping the center pane via routing.
class ForumShell extends StatelessWidget {
  final Widget child;

  const ForumShell({
    super.key,
    required this.child,
  });

  @override
  /// Builds the forum shell and delegates responsive behavior to shared layout.
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: forumLightboxController,
      builder: (context, _) => PopScope(
        canPop: !forumLightboxController.isOpen,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && forumLightboxController.isOpen) {
            forumLightboxController.close();
          }
        },
        child: Scaffold(
          body: Stack(
            children: [
              ResponsiveLayout(
                desktop: _buildDesktopLayout(child),
                mobile: _buildMobileLayout(child),
              ),
              if (forumLightboxController.isOpen)
                Positioned.fill(
                  child: ColoredBox(
                    color: const Color(0xCC000000),
                    child: SafeArea(
                      child: MediaViewerDialog(
                        mediaId: forumLightboxController.mediaId,
                        onClose: forumLightboxController.close,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
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

