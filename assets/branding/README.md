# Branding assets

Source files for app icon + splash. Generators in `pubspec.yaml`
(`flutter_launcher_icons`, `flutter_native_splash`) read these and
produce all the per-platform resized assets.

## Required files

| File                | Size       | Notes                                            |
|---------------------|------------|--------------------------------------------------|
| `app_icon.png`      | 1024×1024  | App icon. Opaque (no alpha). Square corners.     |
| `splash.png`        | 1024×1024  | Centered splash logo. Transparent background OK. |

Both files are intentionally **NOT** checked in for v1 — drop them in
when you've designed them, then re-run the generators.

## Generators

After placing the source files, run:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

The output is committed (per-resolution PNGs under `ios/` and `android/`).

## What gets touched

- `ios/Runner/Assets.xcassets/AppIcon.appiconset/*` (all icon sizes)
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/*` (splash)
- `android/app/src/main/res/mipmap-*/ic_launcher.png` (all densities)
- `android/app/src/main/res/drawable*/launch_background.xml`

Verify both platforms after generating:
- iOS: `flutter run -d <iPhone simulator>` → check Home Screen + splash.
- Android: `flutter run -d <emulator>` → check launcher + splash.
