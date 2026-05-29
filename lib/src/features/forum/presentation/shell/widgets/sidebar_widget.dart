import 'package:flutter/material.dart';
import 'package:flutter_posts/src/core/routing/app_routes.dart';
import 'package:go_router/go_router.dart';

/// Desktop-only left rail.
///
/// Visible only when the `ResponsiveLayout` selects the desktop branch
/// (width > 800px). On mobile, the equivalent navigation lives in the
/// bottom nav + drawer combo.
///
/// Highlights the current section by checking the active route path,
/// which keeps the highlight in sync without us tracking a separate
/// "selected" state.
class SidebarWidget extends StatelessWidget {
  const SidebarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final String path = GoRouterState.of(context).uri.path;

    return ColoredBox(
      color: const Color(0xFFF3F4F6),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        children: [
          const SizedBox(height: 8),
          _SidebarNavItem(
            label: 'Me',
            isSelected: path == AppRoutes.mePath,
            // `go` (not `push`) for top-level section switches — see
            // NavigationRules.md. Avoids stacking section history.
            onTap: () => context.go(AppRoutes.mePath),
          ),
          _SidebarNavItem(
            label: 'Community',
            // Community is selected for the feed root AND any /t/* drill-down.
            isSelected:
                path == AppRoutes.communityPath || path.startsWith('/t/'),
            onTap: () => context.go(AppRoutes.communityPath),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE5E7EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: const Color(0xFF111827),
            ),
          ),
        ),
      ),
    );
  }
}
