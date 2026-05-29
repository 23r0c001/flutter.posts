// Conditional barrel import: picks the web implementation when running on
// Flutter web (where `dart:html` is available), else the stub used by
// iOS/Android/desktop. This is the canonical Dart pattern for
// platform-specific code — see https://dart.dev/guides/libraries/create-packages
// section "Conditional importing and exporting".
//
// For v1 we ship native only (web is not a build target), so the stub will
// always be selected. We keep the web bridge file around in case web is
// revisited later — it has zero runtime cost when unused.
import 'lightbox_history_bridge_stub.dart'
    if (dart.library.html) 'lightbox_history_bridge_web.dart';

/// Platform-agnostic contract for syncing the lightbox open/close state with
/// the browser's URL/history (web) or no-op (mobile/desktop).
///
/// The lightbox is an in-app overlay (NOT a route), but on the web users
/// expect back-button to close it. The bridge handles this by pushing a
/// `#lightbox` hash entry when the lightbox opens, and listening for popstate
/// to close it when the user hits back.
abstract class LightboxHistoryBridge {
  /// Whether the lightbox should be considered open per the current
  /// platform's history state (used for initial restoration).
  bool get isLightboxOpen;

  /// Called when the in-app lightbox controller opens the lightbox.
  void open();

  /// Called when the in-app lightbox controller closes the lightbox.
  void close();

  /// Free any platform listeners (e.g., popstate on web).
  void dispose();
}

/// Factory dispatched via the conditional import at the top of this file.
/// The actual implementation is `WebLightboxHistoryBridge` on web,
/// `StubLightboxHistoryBridge` everywhere else.
LightboxHistoryBridge createLightboxHistoryBridge({
  required void Function(bool isOpen) onExternalStateChange,
}) {
  return createLightboxHistoryBridgeImpl(
    onExternalStateChange: onExternalStateChange,
  );
}
