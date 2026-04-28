import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_posts/src/shared/constants/app_routes.dart';
import 'package:flutter_posts/src/shared/navigation/lightbox_controller.dart';
import 'package:flutter_posts/src/shared/widgets/responsive_layout.dart';
import 'package:go_router/go_router.dart';

import 'widgets/mobile_community_drawer.dart';
import 'widgets/media_viewer_dialog.dart';
import 'widgets/resources_pane.dart';
import 'widgets/sidebar_widget.dart';

/// Persistent forum shell/layout.
/// Keeps sidebar/resources mounted on desktop while swapping the center pane via routing.
class ForumShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  static final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
        // While lightbox is open, consume back to close overlay first.
        canPop: !forumLightboxController.isOpen,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && forumLightboxController.isOpen) {
            forumLightboxController.close();
          }
        },
        child: Scaffold(
          key: _scaffoldKey,
          appBar: _buildMobileAppBar(context),
          drawer: _buildMobileDrawer(context),
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
    final String path = GoRouterState.of(context).uri.path;
    if (isDesktop || path == AppRoutes.settingsPath) {
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
          // goBranch preserves each tab's independent stack.
          // Do not use top-level go() here or Community stack will reset.
          navigationShell.goBranch(index);
        }
      },
    );
  }

  PreferredSizeWidget? _buildMobileAppBar(BuildContext context) {
    final bool isDesktop = MediaQuery.sizeOf(context).width > 800;
    if (isDesktop) {
      return null;
    }

    final String path = GoRouterState.of(context).uri.path;
    if (path == AppRoutes.settingsPath) {
      return null;
    }

    if (navigationShell.currentIndex == 0) {
      return AppBar(
        toolbarHeight: 44,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          tooltip: 'Open community menu',
        ),
      );
    }

    return AppBar(
      toolbarHeight: 44,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Open settings',
          onPressed: () => context.push(AppRoutes.settingsPath),
        ),
      ],
    );
  }

  Widget? _buildMobileDrawer(BuildContext context) {
    final bool isDesktop = MediaQuery.sizeOf(context).width > 800;
    if (isDesktop || navigationShell.currentIndex != 0) {
      return null;
    }
    return const MobileCommunityDrawer();
  }
}

