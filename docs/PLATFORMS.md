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

Flutter’s native app is `app/ios/`. Build with macOS and Xcode. The hosted Mac [successfully compiled an arm64 development app](https://github.com/lukasboz/HybridAILarp/actions/runs/44657697039). No local Mac is required for that workflow.

```sh
bash scripts/flutter.sh build ios --release --no-codesign
```

The current workflow produces an unsigned AOT development app with an explicitly selected App Check debug provider. Download its artifact and unpack its tarball under `artifacts/ios/`, connect and unlock the paired phone, then run `bash scripts/install-ios.sh`. The helper refreshes its public Firebase asset; Linux `xtool install` signs and installs it with the configured Apple account. Installation succeeded on the iOS 26.5 phone, and the user confirmed that the dashboard opens after trusting their development certificate. The Firebase-configured update installed successfully and real iPhone plan creation was verified. The latest v0.2.1 AI fix awaits final on-phone verification. Native Firebase/App Check configuration must match the resulting signed bundle ID; the separate development registration now does.

The installed Linux xtool/Darwin SDK does not compile Flutter’s Xcode runner; this installation route uses the actual hosted Mac compilation. iPhone Safari can also exercise the shared web build.

## Visual consistency

Shared fonts, icons, control theme and painted glass avoid platform-specific UI substitutions. The viewport selects sidebar versus bottom navigation. Widget golden tests compare both iOS and Android target-platform settings to the same phone baseline and also cover desktop. These are renderer tests, not physical cross-device screenshots. Text scaling and narrow layouts are tested without disabling accessibility.

See [Flutter migration and configuration](FLUTTER.md) for full setup, data boundaries and remaining limits.
