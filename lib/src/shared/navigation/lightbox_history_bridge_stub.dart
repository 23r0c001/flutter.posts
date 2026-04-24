import 'lightbox_history_bridge.dart';

class StubLightboxHistoryBridge implements LightboxHistoryBridge {
  StubLightboxHistoryBridge({required this.onExternalStateChange});

  final void Function(bool isOpen) onExternalStateChange;
  bool _isLightboxOpen = false;

  @override
  bool get isLightboxOpen => _isLightboxOpen;

  @override
  void open() {
    _isLightboxOpen = true;
    onExternalStateChange(true);
  }

  @override
  void close() {
    _isLightboxOpen = false;
    onExternalStateChange(false);
  }

  @override
  void dispose() {}
}

LightboxHistoryBridge createLightboxHistoryBridgeImpl({
  required void Function(bool isOpen) onExternalStateChange,
}) {
  return StubLightboxHistoryBridge(
    onExternalStateChange: onExternalStateChange,
  );
}
