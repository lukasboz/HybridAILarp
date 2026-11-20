# Flutter migration

## Single UI implementation

`app/lib/` owns discovery, navigation, preferences, dialogs, planning, voting and privacy. All platforms draw the same widgets. Inter Regular/Medium/SemiBold and Material icons are bundled. The application uses one explicit Material control style, custom painted glass and a common scrolling policy. Avoid `.adaptive` controls or separate OS-specific screen trees when extending it.

Parity means matching app content at equal logical viewport size, device-pixel ratio, text scale, locale, data and animation time. System keyboards, permissions, status bars and share targets remain OS surfaces. The photo orbit, orb animation and typography use the same code on all targets. Golden tests compare both Android and iOS target-platform settings against one phone baseline; they do not replace screenshots from actual native builds.

## Build tools

Pin Flutter 3.50.1 / Dart 3.14.0. `scripts/flutter.sh` finds `.cache/flutter/bin/flutter` or the SDK on PATH, synchronizes assets, and uses cached Java/Android tools when installed. Set `ANDROID_HOME` and `JAVA_HOME` yourself to use other installations. Java must include `javac`, not only the runtime.

```sh
bash scripts/flutter.sh pub get
bash scripts/flutter.sh analyze
bash scripts/flutter.sh test
bash scripts/flutter.sh build web --release --no-web-resources-cdn
python3 scripts/package-flutter-web.py
bash scripts/flutter.sh build apk --debug
```

The wrapper copies the existing shared JSON, photos and fonts. Edit their canonical sources, not the generated copies in `app/assets/`. Commit synchronized non-secret assets. `app/assets/firebase.json` is generated and ignored.

## Native iOS

Use a Mac with Xcode and the Flutter iOS prerequisites, locally or through a hosted build service. On that machine:

```sh
bash scripts/flutter.sh pub get
bash scripts/flutter.sh build ios --release --no-codesign
```

For a device installation, configure your Apple team and signing in `app/ios/Runner.xcworkspace` (or the Xcode project when using Flutter’s Swift Package Manager integration), then run `flutter run` on the Mac or produce a signed development/ad-hoc/TestFlight build. Provisioning must match `app.meethalfway.mobile`. CI’s macOS job only creates an unsigned compile artifact; certificates, profiles and distribution are intentionally not invented or uploaded.

The Linux xtool installation and Darwin SDK are retained for the legacy SwiftUI app. They are not a supported substitute for Flutter’s Xcode pipeline. No native Flutter iPhone run has been claimed.

## Existing Firebase project

No new backend or Firebase project is required. Public client files are read from:

- `web/firebase-config.local.json`: `firebase` options, `appCheckSiteKey`, `cloudModel`, `publicWebUrl`, optional `emulator`.
- `native/android/app/google-services.json`: existing Android client with package `app.meethalfway.mobile`.
- `native/ios/Resources/GoogleService-Info.plist`: existing iOS client with bundle `app.meethalfway.mobile`.

The synchronizer translates these into platform-specific Flutter `FirebaseOptions`. Missing platform configuration keeps that platform’s manual/sample flow usable and reports live sharing as unavailable. Obtain client files through the Firebase console or authenticated CLI; they are public identifiers, not admin credentials. An authenticated CLI can list existing apps with `firebase apps:list --project meethalfway-2026-e43ca6` and retrieve their SDK configuration with `firebase apps:sdkconfig PLATFORM APP_ID --project meethalfway-2026-e43ca6`.

The production web App Check key is domain-restricted. Test live web AI on an allowed HTTPS origin; localhost requires a privately registered debug setup. Debug Android/iOS builds use SDK debug providers, and release builds use Play Integrity / App Attest. Never commit debug tokens. Emulator configuration bypasses App Check for local Auth/Firestore only; use `--dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2` for an Android emulator. Cloud AI is not emulated.

The existing Firestore schema, authorization rules, eight-member cap, twelve host-option slots and atomic revision resets are unchanged. No rules or Remote Config deployment is part of this migration.

## AI consent and storage

Flutter uses explicit cloud consent for optional note drafting and shortlist explanations. Manual editing never calls a model. Raw notes remain in the editor, are cleared after drafting/review/disposal, and never enter local plan storage or Firestore. After consent they are transmitted to Google through Firebase AI Logic; this is not on-device inference. Provider data handling is governed by the configured service.

Approved cards, local rooms and feedback defaults use Flutter SharedPreferences under `meet.flutter.*`. They do not automatically import the previous HTML localStorage or native preferences. Existing Firestore live rooms use the same backend, but anonymous identities are platform-installation specific; rejoin with an invitation when necessary.

## Rollout and remaining product scope

`npm run build` packages Flutter into `dist/`, which the existing Firebase Hosting configuration already targets. The packaged worker retires old MeetHalfway caches, and the bootstrap unregisters the legacy worker. Hosting deployment remains an explicit later action. Flutter web assets need an initial network load; offline PWA caching is not implemented in this migration. Native apps bundle their sample catalogue and save local plans offline.

The legacy `web/` and `native/` sources remain as reference, with `*:legacy` npm commands. They are not parallel supported UI implementations. The migration preserves the planning flow; it does not turn sample data into live discovery or add Yumi’s account/friends/review system.
