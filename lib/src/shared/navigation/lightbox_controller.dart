import 'package:flutter/foundation.dart';

import 'lightbox_history_bridge.dart';

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

  bool get isOpen => _isOpen;
  String get mediaId => _mediaId;

  void open({required String mediaId}) {
    _mediaId = mediaId;
    _historyBridge.open();
    if (!_isOpen) {
      _isOpen = true;
      notifyListeners();
    }
  }

  void close() {
    _historyBridge.close();
    if (_isOpen) {
      _isOpen = false;
      notifyListeners();
    }
  }

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

final LightboxController forumLightboxController = LightboxController();
