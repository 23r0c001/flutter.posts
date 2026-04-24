import 'dart:async';
import 'dart:html' as html;

import 'lightbox_history_bridge.dart';

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

LightboxHistoryBridge createLightboxHistoryBridgeImpl({
  required void Function(bool isOpen) onExternalStateChange,
}) {
  return WebLightboxHistoryBridge(
    onExternalStateChange: onExternalStateChange,
  );
}
