# v0.4 implementation and release — November 24, 2026

No tests were written or updated for this implementation pass, as requested. Existing test files and visual baselines were left unchanged. Local functional suites were not run; publishing the branch triggered the pre-existing CI workflow. The historical results below apply to the earlier application.

- Flutter 3.50.1 / Dart 3.14 static analysis: no issues.
- Web release compilation and Wasm compatibility dry run: succeeded.
- Signed ARM64 Android release APK (~52 MB) and AAB (~51 MB): succeeded. APK signature verified with Android SDK `apksigner`; AAB signature verified with JDK `jarsigner`. LiteRT-LM's native library is present; unsupported-ABI JNI stubs are excluded.
- Firestore rules syntax validation: passed through Firebase. Static authorization review is recorded in `rules-audit.json`; it is not a substitute for the deferred authorization checks.
- Auth, Firestore rules/indexes and Remote Config deployments: succeeded. Hosting status is recorded in RELEASE.md.
- JavaScript/Python syntax checks and `git diff --check`: passed.
- iOS: the [Mac job](https://github.com/lukasboz/HybridAILarp/actions/runs/45330958856/job/138231793468) passed for source commit `6a573a7d85fdf3ec00a8a877cd63377d19c6bcb8`. The downloaded artifact digest matched GitHub. Its ARM64 Mach-O app is version 0.4.0/build 5 and includes LiteRT-LM frameworks. The public Firebase asset was refreshed locally for signing. Current app: `artifacts/ios/Runner.app`; configured unsigned archive: `artifacts/ios/MeetHalfway-0.4.0-configured-unsigned-app.tar.gz`. No physical-device claim is made.
- Existing CI: rules job passed; Flutter suite reported 29 passes and 5 failures. Four screenshot baselines differ after the new navigation/screens, and the cloud-drafting widget test refers to the old control. The harness also lacks connectivity plugin mocks. No test or golden changes were made.
- Functional flows, model downloads/inference, offline reloads, physical-device validation and updated goldens remain deferred. No prior v0.2 result is evidence that these new flows were exercised.


# Verification status — Flutter migration

The canonical application is now `app/`. Results below concern that application unless explicitly marked as legacy.

| Area | Evidence |
| --- | --- |
| Static analysis | `bash scripts/flutter.sh analyze`: no issues. |
| Flutter tests | 28 tests passed, including seven AI capacity/error regression cases. |
| Planner parity | Seven Dart cases match the original shared JavaScript rankings and scores exactly: sample, zero budget, quiet/indoors, confirmed access, no overlap, missing card and walking. |
| Domain boundaries | Tests reject private-note fields and invalid cards, require exact-revision unanimous consent, enforce host-option constraints and check calendar rollover/escaping. |
| State | Tests exercise three-person consensus, preference updates invalidating votes/proposals, local persistence and switching sample perspectives. |
| UI flow | Widget tests exercise composer-to-local-plan creation and a sample group from proposal through discussion, all three votes, confirmation and calendar availability. |
| Cloud consent | A recording adapter verifies no note request before consent or after cancellation, one request after approval, and no raw-note canary in saved preferences. This is a consent test, not a live model response. |
| Visual baselines | Updated to navy `#001B2E`, periwinkle `#6279B8` and ice blue `#C1DFF0`, including matching platform app icons and launch backgrounds. Bundled Inter and Material icon fonts plus predecoded photographs. Android and iOS target-platform settings match the same 390×844 phone baseline. A 1440×1000 desktop baseline and phone room baseline are also checked. These are widget renderer tests, not physical device screenshots. |
| Accessibility layout | 320×640 phone with 1.5× text scaling passes without layout overflow; navigation remains usable. Reduced-motion disables orb breathing. |
| Android | `build apk --debug` succeeds locally and on the hosted clean runner. The debug APK is packaged under `artifacts/`. The native Firebase test runs successfully on an API 35 x86_64 Android emulator. The normal application was separately installed and launched with `flutter run --no-resident`; startup reported no Flutter exception. This is runtime evidence, not a visual walkthrough. |
| Web | Release web build succeeds, including the Wasm compatibility dry run. It is packaged in `dist/`; the HTTP preview on port 4173 serves the Flutter bootstrap successfully. |
| Browser walkthrough | Attempted through the cloud-desktop skill. CUA returned no browsers and `The browser access host is unavailable`. No live browser walkthrough or browser screenshot is claimed. Generated widget screenshots were visually inspected. |
| iPhone connection | Pairing validated and installation succeeded on November 20, iOS 26.5. Later diagnostic connections intermittently returned lockdownd `-8`. The user has taken the phone while the AI fix builds; the final installation/check requires its return. |
| Native iOS | The main-branch Firebase-configured app installed successfully through local `xtool` signing. The user created a real live plan, confirmed by a server read. Fixed v0.2.1 build 3 compiled in [CI](https://github.com/lukasboz/HybridAILarp/actions/runs/44749125076) and is retained as the previous-version backup; its on-phone AI/confirmation check was pending at that time. |
| Firebase client config | Official Firebase plugin authenticated; public native configurations retrieved into ignored files. The iPhone uses a separate development registration matching its observed `XTL-TEAMID.` signed identifier. Its debug token was registered after explicit user approval. A protected limited-use token exchange succeeded. No token is committed. |
| Native Firebase SDK flow | `flutter drive` integration test passed against local Auth + Firestore emulators using four independent native SDK clients. Verified anonymous IDs, outsider denials, invitation joins/rejoins, three shared cards, host option, proposal resets, forged/stale vote denials and unanimous confirmation observed by another client. `app/build/integration_response_data.json` records the result. The demo project blocks model requests and skips production Remote Config. |
| Production Firebase services | Real Android SDK tests passed Auth, App Check, server-backed approved-card writes/reads and AI drafting. The v0.2.1 test exercised a 45-second primary timeout and a successful `gemini-3.5-flash-lite` fallback; returned preferences validated. Synthetic test documents were removed. An iPhone-registration server probe reproduced Gemini 3.8 high-demand HTTP 500 and succeeded with the fallback; that is backend evidence, not a successful native iPhone AI draft. AI Logic App Check enforcement remains enabled. |
| Cross-device runtime | An Android SDK client joined the iPhone-created plan and shared an allowlisted card. The phone’s preference draft failed on the old build during provider overload, so final real-device voting/confirmation remains pending. Temporary Android guests were removed while the user was away; the iPhone plan was preserved. |
| AI resilience | Primary and fallback requests have separate 45-second deadlines and closed HTTP clients. Only transient model failures use the fallback. Device verification/configuration errors remain explicit. Draft and explanation receipts report the model actually used. Seven regression tests cover these behaviors. |
| Firestore rules | At migration: unchanged, all 12 authorization tests passed against the local emulator, and the deployed rules matched the repository exactly. The repository rules have since gained invitation renewal and a confirmed-plan proposal lock (see below), so they now differ from the deployed rules until they are deployed. |
| CI | [Run 44749125076](https://github.com/lukasboz/HybridAILarp/actions/runs/44749125076) passed analysis/28 tests/web, Android APK and iOS development compilation for the AI fix. All artifact steps use Node 24 via `upload-artifact@v7`. |
| Production | The Flutter migration and verified AI fix are merged into main. No Flutter Hosting deployment, rules deployment, Remote Config publication, signing-key upload or billing change was performed. The public Hosting site is still the earlier client. |

## Integration fixes — November 20, 2026 (Windows 11 checkout)

| Area | Evidence |
| --- | --- |
| Static analysis | `bash scripts/flutter.sh analyze` with Flutter 3.50.1: no issues. |
| Flutter tests | 34 tests: all 30 non-golden tests pass. These include new cases for past dates, a confirmed-plan proposal lock, reopened-decision notices, live-plan restore on launch, the system Back route, confirmed-plan sharing, calendar folding and explanation payloads without member IDs. The 4 golden comparisons fail on Windows by 3.08%, 0.99% and 3.59%. Unmodified main fails by exactly the same amounts on this machine, so the baselines are Linux-rendered and CI remains the golden reference. |
| Firestore rules | `npm run test:rules` on a local emulator (Java 23, Node 22): 13 of 13 pass. These include host-only invitation renewal for the same room and a refused proposal after confirmation. The new rules have not been deployed. |
| Not verified here | No Firebase client configuration is present in this checkout. Live invitation renewal, join error messages, launch restore against a real project, browser address-bar cleanup, Android Back on a device, and the travel map on physical screens still need checking. |

The retained HTML, Compose and Swift planner checks are historical evidence for the older clients. The rows above record the separate Flutter build and runtime evidence.

At v0.2, local inference, durable accounts, social/history, lifecycle and multi-stop features were not yet implemented. These historical limitations are superseded by the v0.4 status above.
