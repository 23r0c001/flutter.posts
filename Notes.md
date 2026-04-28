# Gemini Notes
- How to keep the "Mobile" door open:
To ensure your "Web First" app doesn't become "Web Only," follow this one rule: Don't use dart:html.
If you need to do something platform-specific (like picking a file), use a Flutter package (like file_picker) rather than a web-only library. This ensures that when you finally run flutter run -d ios, 100% of your code still compiles [7].

- What about the "Desktop" specific features?
You mentioned isDesktop. In Flutter, you use kIsWeb or Platform.isWindows only for logic, not layout.
Use LayoutBuilder for: "Should I show a sidebar?"
Use Platform check for: "Should I show a 'Quit App' button?" (Since you can't "Quit" a website).
Does this "Content-First" scaling make sense for your Hub layout?

# Todo
- Put a search bar at the top of the shell
- Download pregnancy app, check web, see if they have subreddit concept
- View for clicking on an image should get rid of shell

# Color Themes
## New files
- `lib/src/theme/app_color_tokens.dart
  - Raw color tokens (mint + neutrals + support colors)
  - XAML resource-dictionary style “named colors”
- lib/src/theme/app_theme_extensions.dart
 - AppChromeColors ThemeExtension
 - Semantic app colors for shell-specific UI (sidebar bg, selected bg, overlay, page bg)

- lib/src/theme/app_theme.dart
 - AppTheme.light() central builder
 - Explicit ColorScheme (not fromSeed)
 - Global component themes for:
  - FilledButton
  - OutlinedButton
  - Card
 - Includes AppChromeColors.light in ThemeData.extensions

##Intent
This is ready as a scaffold for gradual adoption, but not applied yet, exactly as requested.
When you’re ready, swap in:
 - theme: AppTheme.light()
in MaterialApp.router and start replacing hardcoded colors with:
 - Theme.of(context).colorScheme...
 - Theme.of(context).extension<AppChromeColors>()!...