# MeetHalfway

**Good plans, together. One Flutter interface for web, Android and iOS.**

MeetHalfway helps a group choose an activity that respects everyone’s budget, travel limit, availability and interests. Its visual reference is [Yumi’s web dashboard](https://www.aarushagarwal.dev/projects/Yumi): a pale-blue canvas, translucent navigation, ice-blue glass orb, activity-photo orbit and floating composer.

The canonical application is **[`app/`](app/)**. All three platforms use the same Dart widgets, bundled Inter fonts, icons, photos, controls and planner. Layout changes depend on viewport size, not operating system. Phone navigation becomes a sidebar at 760 logical pixels. Cloud preference drafting and shortlist explanations require separate, explicit consent.

## Run

Use Flutter **3.50.1** (Dart 3.14), Python 3, and Java 21 plus an Android SDK for Android builds. The workspace’s Flutter, Java and Android tools are installed under ignored `.cache/`; the wrapper detects these, or uses Flutter on PATH.

```sh
bash scripts/flutter.sh pub get
bash scripts/flutter.sh run -d web-server --web-hostname 0.0.0.0 --web-port 4173
```

Open http://127.0.0.1:4173. Manual preferences, sample people and local plans work without Firebase configuration. Changes made in the old HTML/native implementations are not automatically imported into Flutter’s separate local storage.

```sh
bash scripts/flutter.sh analyze
bash scripts/flutter.sh test
bash scripts/flutter.sh build web --release --no-web-resources-cdn
python3 scripts/package-flutter-web.py
bash scripts/flutter.sh build apk --debug
```

The web build is packaged in `dist/`, retaining the existing Firebase Hosting target. The APK is `app/build/app/outputs/flutter-apk/app-debug.apk`. Root `npm run dev`, `build`, `check`, `test` and `build:android` invoke these Flutter workflows. `npm run preview` serves a packaged build on port 4173.

## What is implemented

- Responsive discovery dashboard with tappable activity orbit, sample participants and a plan composer.
- Local plans, sample perspectives, manual preference editing and review before sharing.
- Deterministic hard-limit filtering and ranking that prioritizes the least-satisfied person.
- Host-provided activity options, rejected-option explanations, revision-bound voting and unanimous confirmation.
- Firebase anonymous Auth, live Firestore rooms and invitations, App Check, Remote Config, and Firebase AI Logic adapters.
- Explicitly approved cloud note-to-card drafting and optional cloud shortlist explanations. Raw notes are not saved by the app.
- Calendar `.ics` sharing, invitation sharing/copying and local feedback for future preferences.
- Contract tests against the original shared planner fixtures, consent tests and phone/desktop visual baselines.

The twelve Toronto activities are **sample data**, not live discovery. Their photos, prices, hours, access and travel are illustrative or estimated. Learned account profiles, a friends graph, live event/venue search and multi-stop itineraries remain separate product work.

## Firebase

`scripts/sync-flutter-assets.py` bundles public client configuration from the existing ignored web JSON, Android `google-services.json`, and iOS `GoogleService-Info.plist`. It generates ignored `app/assets/firebase.json`; source archives and CI builds without these files retain local/sample functionality.

This checkout has authenticated Firebase access and the native client configurations have been retrieved through the official plugin into ignored files. Android uses `app.meethalfway.mobile`. Apple free provisioning prefixes the installed iPhone identifier, so a separate development iOS registration matches that signed identity. For another checkout, sign in and run `node scripts/fetch-firebase-configs.mjs --ios-bundle-id SIGNED_ID` to retrieve existing registrations. See [Flutter configuration and migration](docs/FLUTTER.md).

App Check’s production web key excludes localhost. Live AI on localhost needs a properly registered debug provider or a permitted HTTPS domain. Native debug App Check tokens must be registered privately. Never commit tokens or service-account credentials. No deployment or Firebase project changes are performed by the build.

## iPhone from Linux

Flutter’s native iOS compilation requires **macOS and Xcode**, supplied here by GitHub’s hosted Mac runner. The [hosted workflow](https://github.com/lukasboz/HybridAILarp/actions/runs/44657697039) passed web verification, Android compilation and the arm64 iOS development build.

[The CI workflow](.github/workflows/flutter.yml) produces an unsigned development artifact. Download it and unpack its tarball to `artifacts/ios/`, then connect and unlock a paired iPhone and run `bash scripts/install-ios.sh`. The helper refreshes its public Firebase data asset, and `xtool` signs the app locally before installing; Apple credentials stay off the hosted runner. Installation succeeded and the user confirmed that the dashboard opens after trusting their development certificate. The subsequent Firebase-configured update is pending recovery from a Linux USB configuration error. The development artifact uses App Check’s debug provider, whose device token needs private registration for protected services.

## Repository layout

- `app/lib/`: canonical Flutter app, planner, state and Firebase adapters.
- `app/android/`, `app/ios/`, `app/web/`: platform runners for that same UI.
- `shared/`: source catalogue, design tokens and language-independent planner fixtures.
- `scripts/flutter.sh`: asset synchronization and Flutter command wrapper.
- `web/`, `native/`: retained legacy HTML, SwiftUI and Compose implementations for reference. They are not the Flutter app’s runtime.
- `tests/`: legacy JavaScript/Swift contracts and Firestore rules tests. Use `npm run test:legacy` or `npm run test:rules` as appropriate.

[Architecture](docs/ARCHITECTURE.md) · [Build platforms](docs/PLATFORMS.md) · [Verification](docs/VERIFICATION.md) · [Design sources](docs/DESIGN.md)
