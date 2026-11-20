# Platform build and verification notes

## Shared design, native interfaces

The iPhone interface is SwiftUI, Android is Jetpack Compose, and web is HTML/CSS. They share generated design tokens, identical Inter font files, activity photographs, catalogue data and seven planner fixtures. Swift and Kotlin implement the deterministic planning algorithm and match the web-generated expected rankings. All three use their platform Firebase SDK for Auth, Firestore, App Check, Remote Config and AI Logic.

The web version can be installed as a PWA. A PWA running in Safari on an iPhone is not a substitute for the native Apple local-model integration.

## Android

The Android project targets SDK 35, supports API 26+, and uses Java 17 bytecode. Build with a recent JDK such as 21 and the standard Gradle wrapper:

```sh
npm ci
npm run build
cd native/android
./gradlew assembleDebug
```

On Windows, use `gradlew.bat`. Supply `ANDROID_HOME` or an ignored `local.properties`. `google-services.json` is retrieved by the Firebase setup helper. Without configuration the app can run its manual sample flow; Firebase-dependent requests report an unavailable state.

The Android app uses native Compose screens, a native Firebase repository and system sharing. Calendar files are shared through a bounded FileProvider cache directory. External HTTPS venue links open in the system browser. Debug App Check is enabled only for debug builds; release builds use Play Integrity. Backup is disabled.

Gemini Nano requires supported physical hardware and a downloaded model. An ordinary emulator is useful for layout, navigation and group-flow testing, but cannot establish that the on-device model works.

## iPhone: xtool on Linux

Install and configure xtool using its [Linux/Windows guide](https://github.com/xtool-org/xtool/blob/main/Documentation/xtool.docc/Installation-Linux.md). This repository does not install a system Swift toolchain, Apple SDK, USB driver or signing credentials for you.

```sh
npm ci
npm run build
cd native/ios
xtool dev
```

`Package.swift` defines a dynamic Swift package product; `xtool.yml` supplies bundle identity and top-level resources. No `.xcodeproj`, CocoaPods or Ruby manipulation is used. The resource build happens on any host with Node; signing, installation and runtime verification happen on your xtool Linux host with your plugged-in iPhone.

The app bundles `Resources/Shared/`, `Resources/Fonts/` and `Resources/NativeConfig.plist`. The shared-resource build generates the catalogue and copies the photos and fonts; the configured xtool archive already includes them. An empty native config supports the sample/manual UI. A real native config comes from the registered Firebase iOS app’s CLI output. Firebase’s `-ObjC` linker setting is included.

### iOS 26 compatibility decision

Firebase **12.19.3**, the newest published 12.x patch observed during this work, retains the iOS 26 `FirebaseAI.SystemLanguageModel` and `generativeModelSession` APIs. Firebase 13.2’s newer integration uses the iOS 27 Foundation Models model protocol. This project therefore pins the compatible 12.19.3 package for the specified iOS 26.3 target. The pin is deliberate and must not be replaced by a major-version range without migrating the adapter.

Source evidence: [12.19.3 system model wrapper](https://github.com/firebase/firebase-ios-sdk/blob/12.19.3/FirebaseAI/Sources/Types/Public/SystemLanguageModel.swift), [13.2 integration](https://github.com/firebase/firebase-ios-sdk/blob/13.2.0/FirebaseAI/Sources/Extensions/Public/FirebaseAI%2BGeminiLanguageModel.swift), and the [Firebase iOS hybrid guide](https://firebase.google.com/docs/ai-logic/hybrid/ios/get-started).

The Swift compiler must include the relevant Apple SDK and support at least Swift 6.2.3. Follow xtool’s current toolchain requirements. The Firebase 12.x local-model wrappers are compile-gated by compiler and platform support.

### Your iPhone 13

Your iPhone 13 with iOS 26.3 can exercise installation, the SwiftUI interface, private manual controls, live-room synchronization, cloud explanations, native sharing and calendar sharing. It cannot run Apple Intelligence. The app displays that limitation and never silently uploads a private note.

Borrow a supported Apple Intelligence device to verify and record the iOS local-model path. [Apple’s device requirements](https://support.apple.com/en-us/121115) identify eligible hardware.

### Signing and bundle identifiers

xtool may prefix the signed bundle ID when using free provisioning. Register that exact signed bundle ID for the final Firebase iOS app and App Check configuration. The setup helper accepts `--ios-bundle-id`. Do not treat a base-ID debug build as proof that production App Attest will work with a differently signed identifier.

### xtool dependency risks

Firebase includes dependencies that may exercise xtool/SwiftPM support for Apple frameworks. Current upstream issues describe differences between toolchain versions. Avoid claiming an iOS build succeeded until `xtool dev` completes on the actual Linux host and the installed app is opened. If framework resolution fails, capture the exact error and tool versions; do not replace the native Firebase adapter with a web-only claim of equivalent local execution.

## Web

`npm run dev` serves the development app at http://127.0.0.1:4173. `npm run build` generates a standalone static distribution at `dist/`. `node scripts/serve.mjs --dist` can serve that output.

The local AI path uses supported Chrome desktop hardware and Firebase’s `ONLY_ON_DEVICE` mode. It checks model availability, initializes the device model after a user action, and awaits the actual inference result. Firefox, Safari and unsupported Chromium devices retain manual controls and disclosed cloud explanation features.

HTTPS or localhost is required for web local AI, clipboard and service-worker behavior. The production web app needs its Firebase configuration and App Check site key. Native apps share invitations using the public Hosting URL. A recipient can join on web or paste the invitation into either native app.

## Native verification

The Compose app compiles and its three JVM tests pass: seven planner scenarios match web, private-note/invalid card fields are rejected, and confirmation requires current unanimous votes. Swift 6.2.3 on Linux parses the SwiftUI sources and compiles/runs the Foundation planner contract checks. This is not an iOS SDK type-check, linked iOS app build, installation or native screenshot verification.

A no-cost Firebase Test Lab attempt reached device selection, but APK upload was rejected because the storage project has no billing account. No billing was linked. Native visual QA still requires an actual device, configured emulator, or an available cloud test upload path.
