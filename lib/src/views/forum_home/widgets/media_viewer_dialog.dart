import 'package:flutter/material.dart';

/// Full-screen-ish modal media viewer used by thread pages.
///
/// This is intentionally a dialog (not a route) so:
/// - URL does not change
/// - refresh naturally clears the open media
/// - only the `X` button closes the viewer
class MediaViewerDialog extends StatelessWidget {
  final String mediaId;

  const MediaViewerDialog({super.key, required this.mediaId});

  @override
  /// Builds a dark viewer canvas with a fixed close action.
  Widget build(BuildContext context) {
    // Allow system/browser back to dismiss this dialog route.
    return PopScope(
      canPop: true,
      child: Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Positioned.fill(
              // Placeholder media body. Later this can become Image.network.
              child: Center(
                child: Text(
                  'Media $mediaId',
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                tooltip: 'Close media',
                color: Colors.white,
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
