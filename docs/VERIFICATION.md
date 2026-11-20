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
| Android | `build apk --debug` succeeds with the local Android SDK and complete Java 21 JDK. The debug APK is packaged under `artifacts/`. The native Firebase test runs successfully on an API 35 x86_64 Android emulator. This is SDK execution evidence, not a visual walkthrough. |
| Web | Release web build succeeds, including the Wasm compatibility dry run. It is packaged in `dist/`; the HTTP preview on port 4173 serves the Flutter bootstrap successfully. |
| Browser walkthrough | Attempted through the cloud-desktop skill. CUA returned no browsers and `The browser access host is unavailable`. No live browser walkthrough or browser screenshot is claimed. Generated widget screenshots were visually inspected. |
| iPhone connection | USB device previously detected and pairing validated, iOS 26.5. It is currently disconnected. This establishes prior connectivity, not a Flutter app installation. |
| Native iOS | [Hosted macOS build](https://github.com/lukasboz/HybridAILarp/actions/runs/44655868728) successfully compiled the release arm64 app. The unsigned artifact was downloaded and its Mach-O executable, plist and Flutter assets checked. Local `xtool install` can sign the existing app using the configured Apple free-provisioning account; installation/runtime are pending phone reconnection. The updated workflow explicitly selects App Check's debug provider for this development artifact. |
| Firebase client config | Existing public web client configuration recovered from the deployed app. Native client retrieval was attempted; Firebase CLI reported `Failed to authenticate, have you run firebase login?`. Native sample/manual mode remains available. |
| Native Firebase SDK flow | `flutter drive` integration test passed against local Auth + Firestore emulators using four independent native SDK clients. Verified anonymous IDs, outsider denials, invitation joins/rejoins, three shared cards, host option, proposal resets, forged/stale vote denials and unanimous confirmation observed by another client. `app/build/integration_response_data.json` records the result. The demo project blocks model requests and skips production Remote Config. |
| Production Firebase services | Auth/Firestore/App Check/Remote Config/AI Logic adapters compile for Android, iOS and web. Production room/model requests are not verified. Production web App Check excludes localhost, and native configurations/debug tokens still need setup. |
| Firestore rules | Unchanged. All 12 retained authorization tests were rerun and passed against the local emulator, including the eight-participant access-call limit. |
| CI | The first pushed workflow passed analysis/tests/web and iOS compilation; its cold-cache Android dependency lookup failed. The wrapper now supplies Maven Central/Google/plugin repositories to included Gradle builds; hosted revalidation is pending. |
| Production | Work is pushed to the separate `codex/flutter-integration` branch. No main-branch merge, Flutter Hosting deployment, rules deployment, Remote Config change, signing-key upload or billing change was performed. The existing public Hosting deployment is still the earlier client. |

The former HTML client’s 17 passing domain/UI tests, historical live Firebase tests, native Compose compile and Swift planner checks remain useful prior evidence. They do not establish a working native Flutter iPhone build or real Flutter inference.

Remaining product scope includes live activity/event sourcing, persistent learned accounts, friends/review history, multi-stop planning, retention/deletion controls and production service review. The catalogue remains labelled sample data. Flutter uses consent-based cloud AI; the legacy local-only inference implementation is not part of its runtime.
