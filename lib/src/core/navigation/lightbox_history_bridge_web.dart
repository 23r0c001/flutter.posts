// This file is intentionally web-only and is selected via the conditional
// import in `lightbox_history_bridge.dart` when `dart.library.html` is
// available. The lints below would otherwise complain about every line:
//   - `dart:html` is deprecated, but it's still the canonical Flutter web
//     history API as of mid-2026; migrating to `package:web` is a v2
//     polish item if/when we revisit web as a target.
//   - `avoid_web_libraries_in_flutter` doesn't understand conditional
//     imports — it sees `dart:html` as a hard dependency even when it
//     isn't selected on iOS/Android builds.
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;

import 'lightbox_history_bridge.dart';

/// Web implementation of [LightboxHistoryBridge].
///
/// Strategy: the lightbox open state is reflected in the URL fragment
/// (`#lightbox`). Opening the lightbox pushes a new history entry with
/// the fragment; closing it pops the entry. This makes the browser back
/// button "close the lightbox first" — which is what every web user
/// expects from a modal-style overlay.
///
/// NOTE: This file is only compiled when targeting Flutter web (gated by
/// `dart.library.html` in `lightbox_history_bridge.dart`). For v1 we don't
/// ship web — this file is dead code, kept around for future re-targeting.
class WebLightboxHistoryBridge implements LightboxHistoryBridge {
  WebLightboxHistoryBridge({required this.onExternalStateChange}) {
    _popStateSubscription = html.window.onPopState.listen((_) {
      final bool isOpen = _readHashState();
      if (!isOpen) {
        _openedByApp = false;
      }
      onExternalStateChange(isOpen);
    });
  }

  final void Function(bool isOpen) onExternalStateChange;
  StreamSubscription<html.PopStateEvent>? _popStateSubscription;

  /// Tracks whether the current `#lightbox` history entry was pushed by us
  /// (vs. a deep link / refresh / direct URL). If we pushed it, `close()`
  /// can `history.back()` to undo it; otherwise we replaceState to avoid
  /// leaving an orphan entry.
  bool _openedByApp = false;

  @override
  bool get isLightboxOpen => _readHashState();

  @override
  void open() {
    if (_readHashState()) {
      return;
    }

    final Uri uri = Uri.parse(html.window.location.href);
    final Uri lightboxUri = uri.replace(fragment: 'lightbox');
    html.window.history.pushState(null, '', lightboxUri.toString());
    _openedByApp = true;
    onExternalStateChange(true);
  }

  @override
  void close() {
    if (!_readHashState()) {
      return;
    }

    if (_openedByApp) {
      _openedByApp = false;
      html.window.history.back();
      return;
    }

    final Uri uri = Uri.parse(html.window.location.href);
    final Uri baseUri = uri.replace(fragment: '');
    html.window.history.replaceState(null, '', baseUri.toString());
    onExternalStateChange(false);
  }

  @override
  void dispose() {
    _popStateSubscription?.cancel();
  }

  bool _readHashState() {
    return html.window.location.hash == '#lightbox';
  }
}

/// Selected by the conditional import in `lightbox_history_bridge.dart`
/// when `dart.library.html` IS available (web).
LightboxHistoryBridge createLightboxHistoryBridgeImpl({
  required void Function(bool isOpen) onExternalStateChange,
}) {
  return WebLightboxHistoryBridge(
    onExternalStateChange: onExternalStateChange,
  );
}
