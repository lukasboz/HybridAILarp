# Project status

_As of November 21, 2026 · app version 0.2.1 (build 3) · branch `fix/integration-gaps`_

## What MeetHalfway is

MeetHalfway helps a group of friends pick one activity that respects everyone's budget, travel limit, free time, interests and access needs. Each person fills in a short preference card. The app removes any activity that breaks someone's limit, then ranks the rest so the least-satisfied person comes first. The host puts one idea to the group, everyone votes, and the plan is confirmed only when every member says yes.

It is one Flutter app (`app/`) that runs on web, Android and iOS with the same screens on every platform. The activity catalogue is **sample data for Toronto**, not live venue search.

## What works today

### Planning
- Discover screen with an activity orbit, a sample group (Alex, Maya, Jordan) and a plan composer.
- Plans that stay on the device, with sample people you can switch between to see each perspective.
- Preference cards: neighbourhood, spending and travel limits, travel mode, time window, interests, and quiet, indoor or step-free needs. People review the card before sharing it.
- Hard-limit filtering and fair ranking, plus an "Outside our limits" view that explains why each idea was excluded.
- The host can add up to 12 of their own activities, which replace the sample catalogue for that plan.
- Proposal, voting ("I'm in", "Discuss", "Change it") and unanimous confirmation tied to the current revision. Any change to a card, the members or the activities reopens the decision and says why.
- Plan details with an illustrative travel map, each person's travel time against their limit, and indoor, noise and step-free labels.
- Confirmed plans show cost, time and a "nothing is booked yet" reminder, with calendar (`.ics`) export and plan sharing.

### Live plans (Firebase)
- Anonymous sign-in, so nobody has to register before joining.
- Live rooms in Firestore for up to 8 people, joined with invitation links that last 7 days. When a link has less than a day left, the host's next share renews it.
- Clear messages for expired invitations and full plans. Live plans reload when the app opens.
- Firestore security rules covering membership, card validation, vote integrity, the 8-person cap and confirmation. They are tested on the emulator (13 tests).
- App Check, and Remote Config for model names, the explanation switch and group size.

### AI (cloud, consent-based)
- **Draft with AI** turns a free-text note into a preference card for the person to review. The note is sent only after they agree, and it is never saved.
- **Explain this shortlist** describes why the top three ideas fit and their tradeoffs, using anonymous labels instead of member IDs. A separate consent screen comes first.
- Primary model `gemini-3.8-flash`, with one fallback to `gemini-3.5-flash-lite` when the first is busy or slow. Requests time out after 45 seconds, and the Privacy screen lists which model handled each request.
- AI never changes rankings, limits, votes or confirmation. Manual controls work without it.

### Platforms, builds and tests
- Phone layouts checked from 320 to 430 px wide, including at 130% text size, with no overlaps or overflow.
- Web release build and Android debug APK build locally. iOS is compiled on GitHub's Mac runner and installed with `xtool`.
- CI (`.github/workflows/flutter.yml`): analyze, test, web build, Android APK, unsigned iOS build, and Firestore rules tests.
- 34 Flutter tests: planner results that match the shared JavaScript fixtures, store logic, AI fallback and error handling, consent, UI flows, and 4 screenshot baselines.

## Still to integrate or finish

### 1. Deploy what's already built
- **Firestore rules:** deploy with `firebase deploy --only firestore:rules`. Until then, invitation renewal and the confirmed-plan lock are enforced only by the app.
- **Remote Config:** publish `remoteconfig.template.json`, which adds `cloud_fallback_model`.
- **Hosting:** the public site still serves the earlier HTML client. Run `npm run build` and deploy `dist/` to switch it to Flutter.
- **App Check on web:** the production key excludes localhost. Confirm that the hosted domain is registered.

### 2. Verify on real devices and the live project
- Final on-iPhone check of the v0.2.1 build: AI drafting, voting and confirmation.
- A full cross-device run (create → join → share cards → vote → confirm) with real phones.
- Against the real Firebase project: invitation renewal, error messages for expired invitations and full plans, and live plans reloading on launch.
- Android system Back on a device, and web address-bar cleanup after joining through a link.

### 3. Platform and distribution
- **Invite links that open the installed app** (iOS universal links / Android App Links). This needs a paid Apple developer account, Android release signing and hosted verification files.
- Release signing and app-store distribution. The iOS build is currently development-only, with the App Check debug provider.
- Offline caching for the web app. Native apps already work offline for local plans.

### 4. Product features not built yet
- **Live activity data:** real venues, prices, hours, access and routes from a provider with provenance. Only Toronto is covered today.
- **Accounts:** durable sign-in, linking a guest to an account, and recovery after browser data is cleared.
- **Managing a plan:** editing or removing host activities, editing your display name, leaving a plan, removing members, transferring ownership and deleting a live plan.
- **Notifications:** none yet, so people must open the app to see new votes.
- An offline or connection-status banner.
- Friends, history and reviews; multi-stop plans; data-retention and deletion controls.
- A production review of services, quotas and costs.

### 5. Hackathon submission (deadline November 30, 2026, 2 p.m. Pacific)
- Recheck the [official rules](https://firebasehybridaihackathon.devpost.com/rules). The earlier design included on-device AI; this Flutter app uses **cloud AI only**. Confirm whether that still qualifies.
- Required items: Firebase AI Logic used at runtime, App Check, a public open-source repository, and a public demo video of 3 minutes or less. [HACKATHON.md](HACKATHON.md) has a demo script, though its AI claims predate the Flutter migration.

### Engineering notes
- **The 4 screenshot baselines are out of date** after the November 21 mobile layout pass, and CI will fail them until they're regenerated. Regenerate them on Linux with `flutter test --update-goldens`, because Windows renders differ by 1–3%.
- `scripts/flutter.sh` calls `python3`. On Windows, make sure that command exists.
- The legacy `web/` and `native/` clients remain only for reference and aren't maintained.

See also: [Architecture](ARCHITECTURE.md) · [Product](PRODUCT.md) · [Flutter setup](FLUTTER.md) · [Verification](VERIFICATION.md)
