import 'package:flutter/material.dart';

/// View wrapper that swaps mobile vs desktop layouts at a fixed width.
///
/// USAGE: wrap feature views (forum shell, thread, profile) so individual
/// pages don't each reinvent breakpoint logic.
///
/// IMPORTANT: this is content-first, not platform-first. We branch on
/// `constraints.maxWidth`, not `Platform.isIOS` or `kIsWeb`. That means a
/// large iPad in landscape gets the "desktop" layout, and a small browser
/// window gets the "mobile" layout. This is intentional — see `Notes.md`.
///
/// Use platform checks only for things that genuinely differ across OS
/// (e.g. "show a Quit button on desktop OS") — never for layout density.
class ResponsiveLayout extends StatelessWidget {
  /// Layout used when the available width is at or below the breakpoint.
  final Widget mobile;

  /// Layout used when the available width exceeds the breakpoint.
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.desktop,
  });

  /// Single magic-number breakpoint, in logical pixels.
  ///
  /// 800 was chosen because it's just above an iPad Mini in portrait
  /// (744 logical px) and just below an iPad in landscape (1024). So the
  /// "desktop" 3-column shell engages on tablets in landscape but not in
  /// portrait, which matches what users expect.
  static const double _desktopBreakpoint = 800;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return constraints.maxWidth > _desktopBreakpoint ? desktop : mobile;
      },
    );
  }
}
