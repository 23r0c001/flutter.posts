import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_posts/src/core/navigation/lightbox_controller.dart';
import 'package:flutter_posts/src/core/routing/app_routes.dart';
import 'package:flutter_posts/src/core/widgets/responsive_layout.dart';
import 'package:flutter_posts/src/features/forum/presentation/widgets/media_viewer_dialog.dart';
import 'package:go_router/go_router.dart';

import 'widgets/mobile_community_drawer.dart';
import 'widgets/resources_pane.dart';
import 'widgets/sidebar_widget.dart';

/// Persistent forum shell / chrome.
///
/// Hosts the sidebar + resources rail (desktop) or the bottom-nav + drawer
/// (mobile), and renders the routed center pane inside both layouts. Uses
/// go_router's `StatefulNavigationShell` so each tab (Community / Me)
/// has its own independent history stack — switching tabs doesn't reset
/// scroll or pop the inner stack.
///
/// Also renders the lightbox overlay on top of everything when
/// `forumLightboxController.isOpen` — see comment on the controller for
/// why the lightbox is overlay-not-route.
class ForumShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  /// Stable scaffold key so the mobile drawer can be opened from the
  /// mobile app bar's hamburger button.
  static final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  const ForumShell({
    super.key,
    required this.navigationShell,
  });

  /// Builds the shell and delegates responsive behavior to `ResponsiveLayout`.
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: forumLightboxController,
      builder: (context, _) => PopScope(
        // While the lightbox is open, consume the system back to close
        // the overlay first — only the second back pops the route.
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
          // Keep iOS back-swipe usable for route pop. Without this, a
          // left-edge swipe would open the drawer instead of navigating
          // back, which is wildly unexpected on iOS.
          drawerEnableOpenDragGesture: false,
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

  /// Desktop 2/5/3 column split:
  ///   - Sidebar (Me/Community switcher, etc.)
  ///   - Route child (feed / thread / settings)
  ///   - Resources rail (links, ads/affiliate placements someday)
  Widget _buildDesktopLayout(Widget centerChild) {
    return Row(
      children: [
        const Expanded(flex: 2, child: SidebarWidget()),
        Expanded(flex: 5, child: centerChild),
        const Expanded(flex: 3, child: ResourcesPane()),
      ],
    );
  }

  /// Mobile keeps only the route child to maximize available width.
  /// The sidebar collapses into the drawer; resources are unreachable
  /// on mobile (deliberate — they're auxiliary, not load-bearing).
  Widget _buildMobileLayout(Widget centerChild) {
    return centerChild;
  }

  /// Bottom navigation between the Community and Me branches.
  ///
  /// Hidden on desktop (the sidebar handles section switching there) and
  /// on the settings page (which presents as a full-screen modal-style
  /// page with its own app bar).
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
          // `goBranch` preserves each tab's independent stack. Using
          // top-level `go()` here would reset the Community stack
          // every time you tab to Me and back — bad UX.
          navigationShell.goBranch(index);
        }
      },
    );
  }

  /// Tiny app bar shown on mobile only.
  ///
  /// Community branch shows a hamburger to open the drawer; the Me
  /// branch shows a settings cog. Settings page has its own app bar
  /// (with a close button) and suppresses this one.
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
      // Community branch: tiny top bar with hamburger only.
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

  /// Mobile drawer is only meaningful for the Community branch (where it
  /// lists communities). On the Me branch and on desktop, return null so
  /// `Scaffold` doesn't render a drawer.
  Widget? _buildMobileDrawer(BuildContext context) {
    final bool isDesktop = MediaQuery.sizeOf(context).width > 800;
    if (isDesktop || navigationShell.currentIndex != 0) {
      return null;
    }
    return const MobileCommunityDrawer();
  }
}
