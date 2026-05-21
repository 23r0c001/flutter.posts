import 'package:flutter/material.dart';

import 'app_color_tokens.dart';
import 'app_theme_extensions.dart';

/// Central app theme builder.
///
/// Wired into `MaterialApp.router` at the root via `theme: AppTheme.light()`.
/// We deliberately do NOT use `ColorScheme.fromSeed()` — the generated
/// palette doesn't quite match our mint brand. We define an explicit
/// `ColorScheme` instead so the brand stays consistent across components.
///
/// Dark mode is not implemented in v1; when it is, add `AppTheme.dark()`
/// and wire `darkTheme: ...` + `themeMode: ...` on `MaterialApp.router`.
class AppTheme {
  AppTheme._();

  /// Builds the canonical light theme.
  ///
  /// Includes:
  ///   - Brand-aware `ColorScheme` (mint primary, slate neutrals).
  ///   - `AppChromeColors` extension for non-Material UI surfaces.
  ///   - Component themes for `FilledButton`, `OutlinedButton`, `Card`
  ///     so feature widgets don't have to re-style every instance.
  static ThemeData light() {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColorTokens.mint500,
      onPrimary: AppColorTokens.white,
      secondary: AppColorTokens.mint300,
      onSecondary: AppColorTokens.slate900,
      tertiary: AppColorTokens.slate500,
      onTertiary: AppColorTokens.white,
      error: AppColorTokens.danger500,
      onError: AppColorTokens.white,
      surface: AppColorTokens.white,
      onSurface: AppColorTokens.slate900,
      primaryContainer: AppColorTokens.mint100,
      onPrimaryContainer: AppColorTokens.mint700,
      secondaryContainer: AppColorTokens.slate100,
      onSecondaryContainer: AppColorTokens.slate900,
      tertiaryContainer: AppColorTokens.slate200,
      onTertiaryContainer: AppColorTokens.slate900,
      surfaceContainerHighest: AppColorTokens.slate200,
      onSurfaceVariant: AppColorTokens.slate500,
      outline: AppColorTokens.slate200,
      outlineVariant: AppColorTokens.slate100,
      shadow: AppColorTokens.black,
      scrim: AppColorTokens.black,
      inverseSurface: AppColorTokens.slate900,
      onInverseSurface: AppColorTokens.white,
      inversePrimary: AppColorTokens.mint300,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColorTokens.slate050,
      // Register the chrome-color extension so widgets can pull
      // `Theme.of(context).extension<AppChromeColors>()`.
      extensions: const <ThemeExtension<dynamic>>[AppChromeColors.light],
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          // 44pt minimum height matches Apple HIG (touch target accessibility).
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        // Flat cards (no elevation) — we use a subtle border instead. Looks
        // more modern and avoids Android's harsher Material shadow rendering.
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
    );
  }
}
