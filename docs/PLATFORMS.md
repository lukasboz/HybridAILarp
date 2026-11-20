# Platform builds

The active UI is Flutter for all three targets. The old SwiftUI, Compose and HTML clients are retained reference implementations.

## Web

Run `bash scripts/flutter.sh run -d web-server --web-hostname 0.0.0.0 --web-port 4173` or build with `npm run build`. Flutter compiles into `app/build/web`; the packaging helper copies it to `dist/` for the existing Firebase Hosting target. No deployment is performed by building. The first web load requires network access; a new offline asset cache is not part of this migration.

## Android

Use a complete Java 21 JDK, Android platform 36, Flutter 3.50.1 and the standard generated Gradle runner. The workspace wrapper detects the tools installed in `.cache/`.

```sh
bash scripts/flutter.sh build apk --debug
```

APK: `app/build/app/outputs/flutter-apk/app-debug.apk`. Package: `app.meethalfway.mobile`. An Android emulator can validate the app without a physical phone; actual native screenshots must still be collected. Release signing is separate from the generated development/debug configuration.

Native Firebase registration files and App Check setup are needed for live services. Manual/sample plans work without them. The Flutter implementation uses opt-in cloud AI and does not require Gemini Nano hardware.

## iOS

Flutter’s native app is `app/ios/`. Build with macOS and Xcode. The CI workflow includes a macOS unsigned compile job, but adding a workflow locally does not mean that job has run.

```sh
bash scripts/flutter.sh build ios --release --no-codesign
```

An unsigned app is not installable on an iPhone. Configure Apple development signing and the matching `app.meethalfway.mobile` provisioning identity for device installation. Native Firebase/App Check configuration is separate from signing. The connected iPhone was detected and paired on Linux at iOS 26.5; no native Flutter app has been installed or run there.

The installed Linux xtool/Darwin SDK supports the legacy SwiftUI package, not the Flutter Xcode runner. iPhone Safari can exercise the shared web build before a signed native build is available.

## Visual consistency

Shared fonts, icons, control theme and painted glass avoid platform-specific UI substitutions. The viewport selects sidebar versus bottom navigation. Widget golden tests compare both iOS and Android target-platform settings to the same phone baseline and also cover desktop. These are renderer tests, not physical cross-device screenshots. Text scaling and narrow layouts are tested without disabling accessibility.

See [Flutter migration and configuration](FLUTTER.md) for full setup, data boundaries and remaining limits.
