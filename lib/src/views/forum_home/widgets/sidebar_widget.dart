import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/constants/app_routes.dart';

class SidebarWidget extends StatelessWidget {
  const SidebarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final String path = GoRouterState.of(context).uri.path;

    return ColoredBox(
      color: Color(0xFFF3F4F6),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        children: [
          _SidebarNavItem(
            label: 'Community',
            isSelected: path == AppRoutes.communityPath || path.startsWith('/t/'),
            onTap: () => context.go(AppRoutes.communityPath),
          ),
          const SizedBox(height: 8),
          _SidebarNavItem(
            label: 'Me',
            isSelected: path == AppRoutes.mePath,
            onTap: () => context.go(AppRoutes.mePath),
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
