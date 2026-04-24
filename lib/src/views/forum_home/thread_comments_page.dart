import 'package:flutter/material.dart';
import 'package:flutter_posts/src/shared/navigation/lightbox_controller.dart';
import 'package:flutter_posts/src/shared/widgets/responsive_layout.dart';

/// Thread page that shows post context at top and comments below.
class ThreadCommentsPage extends StatelessWidget {
  final String threadId;

  const ThreadCommentsPage({super.key, required this.threadId});

  @override
  /// Uses `ResponsiveLayout` directly so this page can diverge between
  /// desktop/mobile over time without changing routing structure.
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      desktop: _buildThreadBody(context, isDesktop: true),
      mobile: _buildThreadBody(context, isDesktop: false),
    );
  }

  /// Builds placeholder post + comments content for the center pane.
  Widget _buildThreadBody(BuildContext context, {required bool isDesktop}) {
    final double horizontalPadding = isDesktop ? 24 : 12;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        20,
        horizontalPadding,
        24,
      ),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thread $threadId',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text('Placeholder post body for this thread.'),
                const SizedBox(height: 12),
                // Tapping media toggles `#lightbox` URL state.
                GestureDetector(
                  onTap: () =>
                      forumLightboxController.open(mediaId: 'hero-$threadId'),
                  child: Container(
                    height: isDesktop ? 280 : 220,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Tap to open embedded media',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          5,
          (index) => Card(
            child: ListTile(
              title: Text('Comment ${index + 1}'),
              subtitle: Text('Placeholder comment in thread $threadId'),
            ),
          ),
        ),
      ],
    );
  }

}
