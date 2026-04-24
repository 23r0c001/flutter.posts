import 'package:flutter/material.dart';

/// Presentational media viewer panel used by the shell lightbox overlay.
class MediaViewerDialog extends StatelessWidget {
  final String mediaId;
  final VoidCallback onClose;

  const MediaViewerDialog({
    super.key,
    required this.mediaId,
    required this.onClose,
  });

  @override
  /// Builds a dark viewer panel with a fixed close action.
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
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
              onPressed: onClose,
            ),
          ),
        ],
      ),
    );
  }
}
