import 'lightbox_history_bridge_stub.dart'
    if (dart.library.html) 'lightbox_history_bridge_web.dart';

abstract class LightboxHistoryBridge {
  bool get isLightboxOpen;

  void open();

  void close();

  void dispose();
}

LightboxHistoryBridge createLightboxHistoryBridge({
  required void Function(bool isOpen) onExternalStateChange,
}) {
  return createLightboxHistoryBridgeImpl(
    onExternalStateChange: onExternalStateChange,
  );
}
