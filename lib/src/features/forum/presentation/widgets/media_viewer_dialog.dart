import 'package:flutter/material.dart';

/// Presentational media viewer panel used by the shell's lightbox overlay.
///
/// Deliberately dumb: takes a `mediaId` + an `onClose` callback and
/// renders. State (open/closed, current id) lives in
/// `LightboxController`; this widget is just the visual.
///
/// Lives under `features/forum/presentation/widgets/` rather than
/// `shell/widgets/` because it's a forum-feature visual that the shell
/// happens to render — not a piece of shell chrome.
class MediaViewerDialog extends StatelessWidget {
  /// Identifier of the media to display. Today drives placeholder text;
  /// once Phase 4 lands, this will look up a `media` row in Supabase
  /// and render an `Image.network` with a signed storage URL.
  final String mediaId;

  /// Called when the user taps the close button.
  final VoidCallback onClose;

  const MediaViewerDialog({
    super.key,
    required this.mediaId,
    required this.onClose,
  });

  @override
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
            // Placeholder media body. Will become `Image.network(...)`
            // with a signed Supabase Storage URL in Phase 4.
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
