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

The hosted macOS job has successfully compiled this app. For Linux device installation, download the `ios-development-unsigned-app` artifact and unpack `MeetHalfway-unsigned-app.tar.gz` into `artifacts/ios/`. Its tarball preserves framework symlinks and executable permissions. With a paired, unlocked iPhone connected:

```sh
bash scripts/install-ios.sh
```

The helper refreshes the compiled `.app`'s public Firebase JSON asset before `xtool install` signs and installs it over USB. Compilation still happens on the hosted Mac; Apple credentials and signing keys are not uploaded. The existing account uses free provisioning, which produces a signed identifier with an `XTL-TEAMID.` prefix. A separate development Firebase iOS app now matches the observed signed identifier. The first installation succeeded and the user confirmed the dashboard opens after trusting their development certificate in Settings. The Firebase-configured update installed successfully and real iPhone plan creation was verified. The subsequent AI capacity fix is built as v0.2.1 and awaits final on-phone verification. The helper leaves any certificate-revocation decision interactive. Mac/Xcode development signing or TestFlight remain alternatives for distribution.

## Existing Firebase project

No new backend or Firebase project is required. Public client files are read from:

- `web/firebase-config.local.json`: `firebase` options, `appCheckSiteKey`, `cloudModel`, `publicWebUrl`, optional `emulator`.
- `native/android/app/google-services.json`: existing Android client with package `app.meethalfway.mobile`.
- `native/ios/Resources/GoogleService-Info.plist`: existing iOS client with bundle `app.meethalfway.mobile`.

The synchronizer translates these into platform-specific Flutter `FirebaseOptions`. Missing platform configuration keeps that platform’s manual/sample flow usable and reports live sharing as unavailable. After Firebase CLI sign-in, `node scripts/fetch-firebase-configs.mjs` retrieves and validates existing web/Android/iOS registrations without creating or deploying anything. Pass `--ios-bundle-id SIGNED_ID` when needed. These client identifiers are public; account credentials and App Check tokens must remain private.

The production web App Check key is domain-restricted. Test live web AI on an allowed HTTPS origin; local debug web builds can explicitly select `--dart-define=APP_CHECK_DEBUG=true`. Debug Android/iOS builds use SDK debug providers. Normal release builds use Play Integrity / App Attest; CI's locally signed development iOS artifact explicitly opts into the debug provider with `APP_CHECK_DEBUG=true`, since Flutter device builds need AOT compilation and the current Apple account uses free provisioning. Register debug tokens privately. Do not distribute these development artifacts as production releases.

The native SDK integration test uses independent Firebase apps against disposable local Auth/Firestore emulators. It skips production Remote Config and blocks cloud AI. With an Android emulator running:

```sh
bash scripts/test-flutter-firebase.sh
```

The default target is `emulator-5554`, with host `10.0.2.2`. Override `FLUTTER_TEST_DEVICE` / `FIREBASE_TEST_HOST` for another target. The wrapper starts and stops backend emulators; do not run it over an already-running emulator suite on the same ports. Android debug network policy permits cleartext only to local emulator addresses. The test passed on API 35 and wrote `app/build/integration_response_data.json`. It verifies anonymous identities, invitations, shared cards, host options, forged/stale vote rejection and unanimous confirmation. It does not establish production credentials, App Check attestation or model responses. Rebuild the normal app after testing before distributing an APK.

The migration left the Firestore schema, authorization rules, eight-member cap, twelve host-option slots and atomic revision resets unchanged. Since then, the rules have gained an invitation-renewal path for the host and refuse a new proposal once a plan is confirmed. Run `npm run test:rules` and deploy them with `firebase deploy --only firestore:rules` before relying on server enforcement. The Remote Config template now lists `cloud_fallback_model`, and the client reads `max_group_size` (clamped to 2–8). Neither the rules nor the template has been deployed or published.

An additional native connection test is explicitly gated behind `RUN_FIREBASE_LIVE_TEST=true`. It uses the configured real project and requires `FIREBASE_TEST_DEBUG_TOKEN` from a privately registered App Check token. Supply both through an ignored, permission-restricted Dart define file:

```sh
bash scripts/flutter.sh drive --driver=test_driver/firebase_flow_driver.dart \
  --target=integration_test/firebase_live_test.dart -d emulator-5554 --no-dds \
  --dart-define-from-file=/absolute/path/to/private-test-defines.json
```

This test passed for Android anonymous Auth, a valid App Check token and server-backed approved-card writes/reads. Its optional `RUN_FIREBASE_AI_TEST=true` path also passed against `gemini-3.8-flash`, sending synthetic preferences and validating the returned draft. The report contains the temporary room, member and invite paths; remove those synthetic documents with authenticated administrative tooling after the test. Both verified runs' records were removed. Never package the test APK or its private defines; rebuild the normal application afterward. Ordinary unit tests and the demo emulator suite do not run this production test.

## AI consent and storage

Flutter uses explicit cloud consent for optional note drafting and shortlist explanations. Manual editing never calls a model. Raw notes remain in the editor, are cleared after drafting/review/disposal, and never enter local plan storage or Firestore. After consent they are transmitted to Google through Firebase AI Logic; this is not on-device inference. Provider data handling is governed by the configured service.

The primary `cloud_model` defaults to `gemini-3.8-flash`. Temporary capacity/quota failures and timeouts can use the supported `cloud_fallback_model`, defaulting to `gemini-3.5-flash-lite`. Each attempt has a 45-second deadline and closes its HTTP client; there is at most one fallback. Verification, API configuration and region failures do not switch models. Product errors distinguish these cases from connectivity, and receipts identify the model that actually answered. Both requests stay within the same explicitly approved Google/Firebase operation.

Approved cards, local rooms and feedback defaults use Flutter SharedPreferences under `meet.flutter.*`. They do not automatically import the previous HTML localStorage or native preferences. Existing Firestore live rooms use the same backend, but anonymous identities are platform-installation specific; rejoin with an invitation when necessary.

## Rollout and remaining product scope

`npm run build` packages Flutter into `dist/`, which the existing Firebase Hosting configuration already targets. The packaged worker retires old MeetHalfway caches, and the bootstrap unregisters the legacy worker. Hosting deployment remains an explicit later action. Flutter web assets need an initial network load; offline PWA caching is not implemented in this migration. Native apps bundle their sample catalogue and save local plans offline.

The legacy `web/` and `native/` sources remain as reference, with `*:legacy` npm commands. They are not parallel supported UI implementations. The migration preserves the planning flow; it does not turn sample data into live discovery or add Yumi’s account/friends/review system.
