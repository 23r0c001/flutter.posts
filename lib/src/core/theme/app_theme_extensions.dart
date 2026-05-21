import 'package:flutter/material.dart';

import 'app_color_tokens.dart';

/// Semantic, app-specific colors that don't fit into Material's
/// `ColorScheme` (no slot for "sidebar background", etc.).
///
/// Registered as a `ThemeExtension` on `ThemeData`, so widgets pull them
/// via `Theme.of(context).extension<AppChromeColors>()!`. The bang is
/// safe because we always register the extension in `AppTheme.light()`.
///
/// When adding a new chrome color:
///   1. Add a field here.
///   2. Add the constant in `AppChromeColors.light` below.
///   3. Add the lerp call in `lerp()` (theme transitions need it).
///   4. Add the field to `copyWith()`.
@immutable
class AppChromeColors extends ThemeExtension<AppChromeColors> {
  /// Background fill for the desktop left-rail sidebar.
  final Color sidebarBackground;

  /// Background fill for the currently selected sidebar item.
  final Color sidebarSelectedBackground;

  /// Page background behind feed content.
  final Color pageBackground;

  /// Scrim color rendered over the page when the media lightbox is open.
  /// 80% black (0xCC) by default — opaque enough to focus, translucent
  /// enough to hint at the underlying content.
  final Color pageOverlay;

  const AppChromeColors({
    required this.sidebarBackground,
    required this.sidebarSelectedBackground,
    required this.pageBackground,
    required this.pageOverlay,
  });

  /// Light-mode default chrome palette.
  ///
  /// Only one mode for now; when we add dark mode, define `dark` here too
  /// and select between them in `AppTheme.dark()` / `AppTheme.light()`.
  static const AppChromeColors light = AppChromeColors(
    sidebarBackground: AppColorTokens.slate100,
    sidebarSelectedBackground: AppColorTokens.mint100,
    pageBackground: AppColorTokens.slate050,
    pageOverlay: Color(0xCC000000),
  );

  @override
  AppChromeColors copyWith({
    Color? sidebarBackground,
    Color? sidebarSelectedBackground,
    Color? pageBackground,
    Color? pageOverlay,
  }) {
    return AppChromeColors(
      sidebarBackground: sidebarBackground ?? this.sidebarBackground,
      sidebarSelectedBackground:
          sidebarSelectedBackground ?? this.sidebarSelectedBackground,
      pageBackground: pageBackground ?? this.pageBackground,
      pageOverlay: pageOverlay ?? this.pageOverlay,
    );
  }

  /// Called by the framework when two themes are being animated between
  /// (e.g., transitioning from light → dark). Bang-typed because the
  /// individual `Color.lerp` calls only return null when both inputs are
  /// null — we always pass non-null inputs.
  @override
  AppChromeColors lerp(ThemeExtension<AppChromeColors>? other, double t) {
    if (other is! AppChromeColors) {
      return this;
    }
    return AppChromeColors(
      sidebarBackground:
          Color.lerp(sidebarBackground, other.sidebarBackground, t)!,
      sidebarSelectedBackground: Color.lerp(
        sidebarSelectedBackground,
        other.sidebarSelectedBackground,
        t,
      )!,
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      pageOverlay: Color.lerp(pageOverlay, other.pageOverlay, t)!,
    );
  }
}
