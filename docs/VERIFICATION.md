# Verification status — Flutter migration

The canonical application is now `app/`. Results below concern that application unless explicitly marked as legacy.

| Area | Evidence |
| --- | --- |
| Static analysis | `bash scripts/flutter.sh analyze`: no issues. |
| Flutter tests | 21 tests passed in a normal run after baseline generation. |
| Planner parity | Seven Dart cases match the original shared JavaScript rankings and scores exactly: sample, zero budget, quiet/indoors, confirmed access, no overlap, missing card and walking. |
| Domain boundaries | Tests reject private-note fields and invalid cards, require exact-revision unanimous consent, enforce host-option constraints and check calendar rollover/escaping. |
| State | Tests exercise three-person consensus, preference updates invalidating votes/proposals, local persistence and switching sample perspectives. |
| UI flow | Widget tests exercise composer-to-local-plan creation and a sample group from proposal through discussion, all three votes, confirmation and calendar availability. |
| Cloud consent | A recording adapter verifies no note request before consent or after cancellation, one request after approval, and no raw-note canary in saved preferences. This is a consent test, not a live model response. |
| Visual baselines | Updated to navy `#001B2E`, periwinkle `#6279B8` and ice blue `#C1DFF0`, including matching platform app icons and launch backgrounds. Bundled Inter and Material icon fonts plus predecoded photographs. Android and iOS target-platform settings match the same 390×844 phone baseline. A 1440×1000 desktop baseline and phone room baseline are also checked. These are widget renderer tests, not physical device screenshots. |
| Accessibility layout | 320×640 phone with 1.5× text scaling passes without layout overflow; navigation remains usable. Reduced-motion disables orb breathing. |
| Android | `build apk --debug` succeeds with the local Android SDK and complete Java 21 JDK. The debug APK is packaged under `artifacts/`. No Android device/emulator runtime has been inspected in this migration. |
| Web | Release web build succeeds, including the Wasm compatibility dry run. It is packaged in `dist/`; the HTTP preview on port 4173 serves the Flutter bootstrap successfully. |
| Browser walkthrough | Attempted through the cloud-desktop skill. CUA returned no browsers and `The browser access host is unavailable`. No live browser walkthrough or browser screenshot is claimed. Generated widget screenshots were visually inspected. |
| iPhone connection | USB device detected and pairing validated, iOS 26.5. This establishes connectivity, not a Flutter app installation. |
| Native iOS | Standard Flutter runner and macOS CI compile job prepared. No native Flutter iOS build, signed installation or runtime has been verified. Requires macOS/Xcode and Apple signing. |
| Firebase client config | Existing public web client configuration recovered from the deployed app. Native client retrieval was attempted; Firebase CLI reported `Failed to authenticate, have you run firebase login?`. Native sample/manual mode remains available. |
| Flutter live services | Firebase Auth/Firestore/App Check/Remote Config/AI Logic adapters compile for Android and web. Live Flutter room/model requests are not verified. Production web App Check excludes localhost, and native configuration/debug tokens still need setup. |
| Firestore rules | Unchanged by migration. The retained legacy emulator suite previously passed 12 tests; it was not rerun during this migration. That history is not new Flutter service evidence. |
| Production | No Flutter deployment, rules deployment, Remote Config change, hosted CI run, signing-key upload or billing change performed. The existing public Hosting deployment is still the earlier client until separately deployed. |

The former HTML client’s 17 passing domain/UI tests, historical live Firebase tests, native Compose compile and Swift planner checks remain useful prior evidence. They do not establish a working native Flutter iPhone build or real Flutter inference.

Remaining product scope includes live activity/event sourcing, persistent learned accounts, friends/review history, multi-stop planning, retention/deletion controls and production service review. The catalogue remains labelled sample data. Flutter uses consent-based cloud AI; the legacy local-only inference implementation is not part of its runtime.
