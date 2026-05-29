import 'lightbox_history_bridge.dart';

/// Non-web implementation of [LightboxHistoryBridge].
///
/// On iOS, Android, and desktop platforms there is no browser URL hash to
/// sync with — back-button handling is done by Flutter's `PopScope` /
/// `WillPopScope` in the shell. This stub just tracks open/closed state
/// in memory and exists so the lightbox controller doesn't need
/// `kIsWeb` checks at every call site.
class StubLightboxHistoryBridge implements LightboxHistoryBridge {
  StubLightboxHistoryBridge({required this.onExternalStateChange});

  /// Callback fired when the bridge thinks the lightbox state changed
  /// from outside the controller. On the stub, this is just an echo of
  /// our own `open`/`close` calls — there is no external state source.
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

/// Selected by the conditional import in `lightbox_history_bridge.dart`
/// when `dart.library.html` is NOT available (i.e., not running on web).
LightboxHistoryBridge createLightboxHistoryBridgeImpl({
  required void Function(bool isOpen) onExternalStateChange,
}) {
  return StubLightboxHistoryBridge(
    onExternalStateChange: onExternalStateChange,
  );
}
