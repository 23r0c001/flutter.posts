import 'package:flutter/material.dart';

import 'app_color_tokens.dart';

/// Semantic colors that are app-specific and not covered by ColorScheme.
@immutable
class AppChromeColors extends ThemeExtension<AppChromeColors> {
  final Color sidebarBackground;
  final Color sidebarSelectedBackground;
  final Color pageBackground;
  final Color pageOverlay;

  const AppChromeColors({
    required this.sidebarBackground,
    required this.sidebarSelectedBackground,
    required this.pageBackground,
    required this.pageOverlay,
  });

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

  @override
  AppChromeColors lerp(ThemeExtension<AppChromeColors>? other, double t) {
    if (other is! AppChromeColors) {
      return this;
    }
    return AppChromeColors(
      sidebarBackground: Color.lerp(sidebarBackground, other.sidebarBackground, t)!,
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
