import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_posts/src/shared/navigation/lightbox_controller.dart';
import 'package:flutter_posts/src/shared/widgets/responsive_layout.dart';
import 'package:go_router/go_router.dart';

import 'widgets/media_viewer_dialog.dart';
import 'widgets/resources_pane.dart';
import 'widgets/sidebar_widget.dart';

/// Persistent forum shell/layout.
/// Keeps sidebar/resources mounted on desktop while swapping the center pane via routing.
class ForumShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ForumShell({
    super.key,
    required this.navigationShell,
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
          bottomNavigationBar: _buildMobileBottomNavigation(context),
          body: Stack(
            children: [
              ResponsiveLayout(
                desktop: _buildDesktopLayout(navigationShell),
                mobile: _buildMobileLayout(navigationShell),
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

  Widget? _buildMobileBottomNavigation(BuildContext context) {
    final bool isDesktop = MediaQuery.sizeOf(context).width > 800;
    if (isDesktop) {
      return null;
    }

    final bool isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final int currentIndex = navigationShell.currentIndex;

    return NavigationBar(
      height: 56,
      selectedIndex: currentIndex,
      destinations: [
        NavigationDestination(
          icon: Icon(
            isIOS ? CupertinoIcons.chat_bubble_2 : Icons.forum_outlined,
          ),
          selectedIcon: Icon(
            isIOS ? CupertinoIcons.chat_bubble_2_fill : Icons.forum,
          ),
          label: 'Community',
        ),
        NavigationDestination(
          icon: Icon(
            isIOS ? CupertinoIcons.person : Icons.person_outline,
          ),
          selectedIcon: Icon(
            isIOS ? CupertinoIcons.person_fill : Icons.person,
          ),
          label: 'Me',
        ),
      ],
      onDestinationSelected: (index) {
        if (index != currentIndex) {
          navigationShell.goBranch(index);
        }
      },
    );
  }
}

