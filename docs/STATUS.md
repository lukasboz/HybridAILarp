# Project status

_As of November 24, 2026 · version 0.4.0 (build 5)_

The canonical Flutter app is `app/`. The implementation is published on
[`codex/complete-hybrid-experience`](https://github.com/lukasboz/HybridAILarp/tree/codex/complete-hybrid-experience).
The web app is deployed at https://meethalfway-2026-e43ca6.web.app/.

## Implemented

| Area | Current behavior |
| --- | --- |
| Local AI | Opt-in Qwen3 0.6B download (~345 MB) on ARM64 Android/iOS through LiteRT-LM; dedicated Gemma 4 E2B browser model (~2 GB) through WebGPU. Download progress, cancellation/removal, capability messages, strict card validation and local receipts. No automatic cloud fallback. |
| Cloud AI | Separately consented Firebase AI Logic drafting and shortlist explanations, bounded primary/fallback requests and model receipts. Manual controls work independently. |
| Accounts | Anonymous participation, email/password linking, existing-account login/recovery, proof of both identities before guest membership migration, private profile sync, export and deletion of private/social data. |
| Lifecycle | Edit title/date/options/name, leave/remove members, transfer host, revoke invitation links, resume interrupted room deletion and reopen decisions after shared changes. |
| Discovery | Explicit OSM/Overpass searches around Toronto neighbourhoods; bounded cached results, real coordinates, source URLs/retrieval times and source-reported hours/fees/access. Host review supplies plan-specific facts. |
| Sourced travel | Explicit host opt-in to Transitous routes for every participant. Fresh, input-bound results drive ranking and itinerary transfers. Missing/expired/mismatched routes fail eligibility. Requests are cached, paced and limited to 100 uncached requests per device/day. |
| People | Friendship links, revocation, saved two-person relationships, name updates, removal and direct shared-plan invitations. Friendship grants no room/card access by itself. |
| Private history | Confirmed snapshots, calendar export, personal star ratings and “again” feedback. Account sync and local-only storage; deleted cloud entries have tombstones to prevent accidental re-archiving. |
| Multi-stop | Ordered two/three-stop plans, activity duration, cumulative budget/travel, windows/settings/access checks, sourced transfer timing, exact-revision unanimous voting and full-itinerary sharing/calendar export. |
| Updates/offline | Live room activity, private invitations, connectivity/cache notices, optional push registration/backend and versioned offline web shell. Downloaded models have their own cache. |
| Distribution | Signed ARM64 Android APK/AAB, local private signing configuration, registered certificate, deployed Android app-link document, native deep links and iOS distribution setup. |

## Deployed and built

Email/password Auth, Firestore rules/indexes, Remote Config and Flutter Hosting
are deployed. The hosted release metadata and Android verification fingerprint
were read back and matched the local release.

Signed Android artifacts are in `artifacts/android/`. Spark Hosting rejects APK
files, so installable binaries are kept outside Hosting. App Distribution upload
is prepared but requires the owner's initial console onboarding.

The Mac CI build passed. Its verified unsigned iOS app is prepared locally at `artifacts/ios/Runner.app`, with the configured archive and installation steps in [release handoff](RELEASE.md). Physical-device operation is not claimed from a
successful compilation.

## Human-only activation

- Open App Distribution in the Firebase console and select **Get started** for
  the registered Android app. Then `npm run upload:android` uploads the build
  without adding recipients. Tester selection/invitations remain owner choices.
- Back up `.cache/signing/` and `app/android/key.properties` securely. These
  private files are ignored and never uploaded through source control.
- Connect/unlock a paired iPhone for local signing/install, or supply an Apple
  distribution team/profile for TestFlight/App Store, universal links and APNs.
- Complete store enrollment, production attestation/provider requirements and
  any required terms. For background push only, opt into billing, provision
  credentials, deploy the optional backend and enable its client flag.
- Review the published branch. The connected GitHub integration cannot open a
  PR (HTTP 403), and browser access is unavailable. Source publication itself
  succeeded through the existing SSH identity.

## Scope and verification boundary

No tests or golden baselines were written or changed. Local analysis and release
compilation passed. The existing CI workflow ran its existing suites: rules
passed; the old Flutter widget/golden checks include stale selectors/baselines
and missing plugin mocks. Their update is deferred as requested; see
[verification](VERIFICATION.md) for exact results.

New device flows and actual local inference have not been exercised on hardware.
The region remains Toronto. Independent venue verification, commercial provider
contracts, bookings, payments, contact imports and chat are separate product
choices, not unfinished dependencies of this planning experience.
