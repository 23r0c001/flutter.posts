import 'package:flutter/material.dart';

import '../../shared/widgets/responsive_layout.dart';
import 'widgets/post_list.dart';
import 'widgets/resources_pane.dart';
import 'widgets/sidebar_widget.dart';

class ForumHomePage extends StatelessWidget {
  const ForumHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayout(
        desktop: _buildDesktopLayout(),
        mobile: _buildMobileLayout(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return const Row(
      children: [
        Expanded(flex: 2, child: SidebarWidget()),
        Expanded(flex: 5, child: PostList()),
        Expanded(flex: 3, child: ResourcesPane()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return const PostList();
  }
}