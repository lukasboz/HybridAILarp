# MeetHalfway

**Private preferences. Fairer plans. Good times together.**

MeetHalfway helps a group of 2–8 people choose a Toronto activity without an endless group chat. Each person reviews a preference card, the app excludes options that break anyone’s limits, and the group accepts a specific proposal before it becomes a plan.

The repository contains a **native SwiftUI iPhone app**, a **native Jetpack Compose Android app**, and a responsive web app. The iPhone app builds as a Swift Package with **xtool on Linux**. All three follow one shared Yumi-inspired design contract and use the same Inter fonts, activity images, catalogue, navigation labels and planner fixtures. Each platform calls Firebase through its own SDK.

**Live preview:** https://meethalfway-2026-e43ca6.web.app

The interface follows Yumi’s discovery design: white canvas, a translucent sidebar, purple glass orb, activity-photo orbit, participant bubbles and a floating plan composer. Phone layouts use a floating bottom navigation bar. Activity photos are illustrative; see [visual sources](docs/DESIGN.md).

The new Firebase project is `meethalfway-2026-e43ca6`. All three apps are registered; anonymous Auth, Toronto Firestore, AI Logic, approved Remote Config defaults and Hosting are provisioned. Web reCAPTCHA Enterprise is domain-restricted, and AI Logic requires App Check. Live independent-user invitation, voting and confirmation checks and a real cloud response succeeded. Native device inference and an xtool build still need device evidence.

## Run locally

Use **Node 24.12 or newer**. On this Windows machine, nvm-windows is already installed:

```powershell
nvm install 24
nvm use 24
npm ci
npm run dev
```

Open **http://127.0.0.1:4173**. No Firebase account is needed to explore the sample group. Sample rooms are labelled as stored on this device and cannot invite real people on other devices.

```text
npm test
npm run check
npm run build
npm run test:rules
```

The rules command starts the official Firestore emulator using a disposable `demo-meethalfway` project. It requires Java 21+. Ordinary `npm test` skips emulator-dependent rules tests if the emulator is absent; it does not imply those rules passed. `npm run build` produces `dist/` and synchronizes native design tokens, catalogue data, photos and planner fixtures. Native screens are implemented in SwiftUI and Compose.

## What works

- Preference controls and a precise review-before-share boundary.
- Private-note extraction wired to Firebase **only-on-device** inference, with no cloud fallback.
- Honest capability detection and manual controls on unsupported devices.
- Deterministic hard-constraint filtering and ranking by the lowest individual fit first.
- A shortlist, an illustrative map, per-person travel estimates, and rejected-option explanations.
- Clearly labelled Toronto sample options, plus host-provided activities for actual group decisions.
- Live-room Firebase adapters: anonymous Auth, Firestore subscriptions, capability invitations, per-person votes, and revision-bound unanimous confirmation.
- Optional Firebase AI Logic cloud explanations using only approved shared cards and eligible candidates.
- Native sharing, calendar invitations in Toronto time, and local feedback for future preferences.
- App Check integration and Remote Config defaults.

The catalogue is **not a live venue feed**. Sample prices, hours and access data are fixtures. Host-added options identify their source; travel remains an estimate from neighbourhood centres. The app makes no reservation and does not claim current TTC routes or availability.

## Firebase setup

This workspace is already configured. The following instructions are for a fresh checkout or a different project.

Complete Google sign-in yourself:

```text
npx -y firebase-tools@latest login
```

Then use the setup helper, which creates a Spark project when `--create` is provided, registers the three platform apps, retrieves native configurations via the CLI, and provisions AI Logic:

```text
node scripts/configure-firebase.mjs --project YOUR_UNIQUE_PROJECT_ID --create
```

The helper does not enable paid billing. It stops on failed commands. The current CLI asks you to select an app during AI Logic provisioning; choose MeetHalfway-Web. **`npx -y firebase-tools@latest init ailogic --project YOUR_PROJECT_ID` is required**; app registration alone does not provision AI Logic.

For web App Check, supply a reCAPTCHA Enterprise site key in the generated `web/firebase-config.local.json` and register the web app/provider in Firebase App Check. For local development, use the SDK’s debug provider with a privately registered debug token; never commit a debug token. Native development builds generate their own debug token. Register each token privately in Firebase App Check.

Deploy after testing and App Check configuration:

```text
npm run build
npx -y firebase-tools@latest deploy --only auth,firestore,hosting --project YOUR_PROJECT_ID
```

Review `remoteconfig.template.json` before deploying Remote Config separately. The installed Firebase skill requires explicit user review. The defaults in the current project were reviewed and approved on November 19, 2026.

On localhost, the production reCAPTCHA key deliberately does not attest that domain. Sample rooms remain available. Test live web features on the hosted URL; keep any local debug-provider credentials private.

## Android

```text
npm run build
cd native/android
./gradlew assembleDebug
```

On Windows, use `gradlew.bat`. Set `ANDROID_HOME` or create an ignored `local.properties` containing `sdk.dir`. The APK is `app/build/outputs/apk/debug/app-debug.apk`. A supported physical Android device is required to verify Gemini Nano; an emulator can still test manual preferences and group planning.

## iPhone with xtool on Linux

```text
npm ci
npm run build
cd native/ios
xtool dev
```

The Swift package uses `xtool.yml`, native SwiftUI components, iOS 26 Liquid Glass with a material fallback, bundled resources, and a `-ObjC` linker flag. It requires a properly configured xtool installation with Apple’s SDK and device pairing. See [platform details](docs/PLATFORMS.md), including the iOS 26 SDK compatibility pin and signed bundle-ID handling.

The owner-ready `artifacts/MeetHalfway-xtool-configured.zip` includes the SwiftUI sources, shared design resources, fonts and public Firebase client identifiers. Extract it on Linux and run `xtool dev` after configuring the toolchain and device pairing. No Node build is needed for that export. Register the native SDK’s generated App Check debug token privately before cloud AI testing.

**An iPhone 13 on iOS 26.3 can test the app and cloud features, but does not support Apple Intelligence.** The app reports this and keeps private preferences editable. Borrow a compatible Apple Intelligence device to verify the iOS on-device path. No local-model run is fabricated.

## Product and submission material

- [Complete product specification](docs/PRODUCT.md)
- [Architecture and data boundaries](docs/ARCHITECTURE.md)
- [Platform builds and verification](docs/PLATFORMS.md)
- [Three-minute demo and judging strategy](docs/HACKATHON.md)
- [Verification status](docs/VERIFICATION.md)

This project uses the workflow patterns in the installed Firebase AI Logic, Authentication, Firestore, Security Rules, Remote Config and Hosting skills. It takes product inspiration from [Yumi](https://github.com/scrappydevs/Yumi); no Yumi source code or assets are incorporated.
