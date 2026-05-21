import 'package:flutter/foundation.dart';

import 'lightbox_history_bridge.dart';

/// In-memory controller for the forum's media lightbox overlay.
///
/// The lightbox is NOT a route — it's an overlay rendered by `ForumShell`
/// above whatever route content is currently mounted. Reasons:
///   - We want it to share the route's history entry (back closes the
///     lightbox, not the entire thread).
///   - On the web, we sync it to `#lightbox` via [LightboxHistoryBridge]
///     so the browser back button works as expected.
///
/// Consumed by:
///   - `ForumShell` (renders the overlay when `isOpen == true`).
///   - Any widget that wants to open media (e.g. `ThreadCommentsPage`
///     calls `forumLightboxController.open(mediaId: ...)`).
///
/// State management: `ChangeNotifier` here rather than a Cubit, because
/// this is genuinely ephemeral UI state with one consumer (the shell)
/// and adding it to the Bloc tree would be overkill.
class LightboxController extends ChangeNotifier {
  LightboxController() {
    _historyBridge = createLightboxHistoryBridge(
      onExternalStateChange: _handleExternalStateChange,
    );
    _isOpen = _historyBridge.isLightboxOpen;
  }

  late final LightboxHistoryBridge _historyBridge;
  bool _isOpen = false;
  String _mediaId = '';

  /// True while the lightbox overlay should be rendered.
  bool get isOpen => _isOpen;

  /// Currently displayed media identifier. Empty when closed.
  String get mediaId => _mediaId;

  /// Opens the lightbox to show [mediaId].
  ///
  /// Calling this when already open updates `mediaId` but does not
  /// re-notify listeners (the shell rebuilds on its own observation).
  void open({required String mediaId}) {
    _mediaId = mediaId;
    _historyBridge.open();
    if (!_isOpen) {
      _isOpen = true;
      notifyListeners();
    }
  }

  /// Closes the lightbox overlay.
  ///
  /// Calling this when already closed is a no-op.
  void close() {
    _historyBridge.close();
    if (_isOpen) {
      _isOpen = false;
      notifyListeners();
    }
  }

  /// Invoked by the history bridge when the platform reports a state
  /// change that didn't originate here (e.g., user hits browser back).
  void _handleExternalStateChange(bool isOpen) {
    if (_isOpen == isOpen) {
      return;
    }

    _isOpen = isOpen;
    notifyListeners();
  }

  @override
  void dispose() {
    _historyBridge.dispose();
    super.dispose();
  }
}

/// Single global instance.
///
/// Yes, a global. The lightbox is forum-wide singleton state by design;
/// every widget that wants to open media targets the same overlay. If we
/// ever need multiple independent lightboxes we'd promote this into a
/// scoped provider, but YAGNI for now.
final LightboxController forumLightboxController = LightboxController();
