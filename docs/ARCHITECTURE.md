# Architecture and data boundaries

## Canonical application

One Flutter app in `app/` targets web, Android and iOS. `lib/app.dart` owns the responsive shell and system Back handling; `design.dart`, `orbit.dart` and `travel_map.dart` define shared controls and visuals; `screens.dart` and `dialogs.dart` implement user flows. Platform runners contain no independent product screen layouts.

`shared/experience.json`, `shared/design-tokens.json`, photographs and Inter fonts are synchronized into Flutter assets. `lib/domain.dart` ports the deterministic planner; its seven shared fixture scenarios must match the original JavaScript results exactly.

## State and services

`MeetStore` coordinates local plans, sample people, approved cards, revisions, votes and transient AI receipts. It saves local rooms/defaults through SharedPreferences and never saves raw note text. A changed card or activity resets the current proposal and votes, and the room shows why the decision reopened. Proposing and confirming recheck local eligibility; a confirmed plan cannot be re-proposed. Devices that have used a live plan reload their live plans on launch.

`FirebaseService` initializes platform-specific public FirebaseOptions only when needed. It implements anonymous Auth, App Check, Firestore live subscriptions, Remote Config and Firebase AI Logic. Missing configuration does not block sample/manual planning. Service failures are shown as recoverable product messages.

## AI boundary

Manual controls are fully functional without AI. Optional note drafting sends the note and current card to Google’s cloud model only after the person accepts an explicit disclosure. The result must parse into the exact allowlisted card schema and pass validation before review. The note is not persisted by MeetHalfway. LocalAI in `local_ai.dart` separately runs downloaded models through LiteRT-LM. It owns capability checks, installation/cancellation and short-lived sessions; local errors never call Firebase AI. Web uses a dedicated web model export and WebGPU; phones use a small ARM64 model on CPU.

Shortlist explanation requires its own consent. Its payload contains approved cards under neutral labels (no member IDs) and the top three eligible candidates. Unknown/duplicate candidate IDs, invalid fields and oversized response text are rejected. A response is discarded if the plan revision changes while the request is running. The model never owns ranking, eligibility, permissions, votes or confirmation.

## Shared backend protocol

The migration kept the existing schema and rules. The v0.4 rules add private accounts/devices, activity events, invitation revocation, plan/member lifecycle operations, provenance and bounded itinerary stops. The current rules and indexes were deployed in this implementation pass.

- `rooms/{roomId}`: title, date, Toronto city, owner ID, member IDs, status, revision, current proposal, invitation reference, creation timestamp.
- `rooms/{roomId}/members/{uid}`: bounded display name, approved card, invitation reference and update timestamp.
- `rooms/{roomId}/votes/{uid}`: choice, candidate ID, proposal revision and update timestamp.
- `rooms/{roomId}/options/option-01` through `option-12`: bounded host activity data with source and setting fields.
- `invites/{48-hex-token}`: room ID, title, creator and expiry. Only the current unexpired capability admits guests. The host can enumerate and purge invitations for their own room.

Creation and joining use atomic batches. Preference/option updates atomically increment revision and clear the proposal. Proposals use a transaction to reject stale revisions and are refused once a plan is confirmed. When the shared invitation has less than a day left, the host's next share atomically points `lastJoinInviteId` at a new invite for the same room. Expired or unknown invitations, and joins past eight people, produce specific messages. Each participant writes only their own vote. Firestore rules require every current member’s acceptance of the same candidate and revision before the host confirms. Group size remains bounded at eight.

No raw-note, email, street-address or live-location field exists in shared room documents. Invitees can see approved room information; invitation links are capabilities that should be shared intentionally.

## Platform boundaries

The same Dart widgets render app content on every target. Sharing, URL launching, storage, Firebase SDK internals, keyboards and OS permissions use platform integrations. Calendar export is an `.ics` file with Toronto time-zone rules and date rollover handling. Android and iOS retain the registered identifier `app.meethalfway.mobile`.

Flutter’s native iOS runner requires macOS/Xcode and signing. Linux xtool can locally sign/install a precompiled development app; compilation still requires the Mac runner. See [platform details](PLATFORMS.md) and [verification](VERIFICATION.md).

## Accounts, notifications and external data

`firebase_accounts.dart` links a new email/password account to the existing
anonymous UID and stores only approved defaults/name in `users/{uid}`. These
profiles, device installation IDs and server inboxes are owner-readable only;
room cards remain intentionally shared. Existing-account sign-in verifies the destination password in a secondary Auth session. A short-lived target-authorized migration proof allows the original guest to transfer only its own memberships, preserving the destination's existing cards. Each transferred room reopens consent. Account deletion requires leaving/transferring/deleting
rooms, recent authentication, then purges private collections before Auth deletion.

`firebase_plans.dart` implements lifecycle transactions and room purging. A
`deleting` marker freezes child writes; the owner can retry interrupted purges.
Activity events contain only allowlisted type, actor UID, revision and timestamp.
IDs coalesce one event per actor/type/revision. The store watches bounded recent
events for Updates; optional Cloud Functions send generic FCM notifications with
per-recipient/room throttling, room-scoped inbox IDs, retryable delivery leases and collapse identifiers.

`discovery_service.dart` bounds and caches public OSM lookups and Transitous
requests. Imported places retain source URL, retrieval date and actual venue
coordinates. A person must supply/review estimates for missing cost, time,
setting and access. Route requests require a disclosure and contain coarse
locations/modes, not member names or notes. Lookup results never bypass the
planner. No server API keys are embedded in the client.

`Proposal.stops` optionally stores two/three ordered candidate IDs, start times,
durations and transfer times. All votes still bind to one proposal revision.
The host rechecks aggregate eligibility and the exact schedule on confirmation.

`social_service.dart` manages explicit friendship capabilities, two-person relationships and plan invitations. `social_store.dart` archives confirmed snapshots privately under `users/{uid}/history`; ratings are owner-only and deleted entries have private tombstones so active confirmed rooms cannot recreate them. Export/deletion includes social and history collections.

`rooms/{id}/routes` contains host-submitted Transitous travel facts keyed by origin/destination, with per-member times, a hash of the approved planning inputs, exact arrival minute and a fifteen-minute expiry. Sourced mode excludes missing, mismatched and expired facts. Refreshing routes changes the revision; estimates require an explicit source switch. Transfer schedules are recalculated until stable, with a bounded number of requests. The provider queue is paced and limited to 100 uncached requests per device per UTC day.

## Product limits

The region remains Toronto. Venue costs, hours, quietness and access are sample or host-reviewed facts. External route provenance is transparent but host submissions are not cryptographically authenticated by Security Rules. No booking or payment is performed. Native local planning and downloaded inference work offline; packaged web loads have a versioned shell cache and separate model cache. Background push needs an activated optional backend. Current authorization review is static; no new tests or device runtime checks were performed.
