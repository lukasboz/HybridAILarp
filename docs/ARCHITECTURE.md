# Architecture and data boundaries

## Canonical application

One Flutter app in `app/` targets web, Android and iOS. `lib/app.dart` owns the responsive shell and system Back handling; `design.dart`, `orbit.dart` and `travel_map.dart` define shared controls and visuals; `screens.dart` and `dialogs.dart` implement user flows. Platform runners contain no independent product screen layouts.

`shared/experience.json`, `shared/design-tokens.json`, photographs and Inter fonts are synchronized into Flutter assets. `lib/domain.dart` ports the deterministic planner; its seven shared fixture scenarios must match the original JavaScript results exactly.

## State and services

`MeetStore` coordinates local plans, sample people, approved cards, revisions, votes and transient AI receipts. It saves local rooms/defaults through SharedPreferences and never saves raw note text. A changed card or activity resets the current proposal and votes, and the room shows why the decision reopened. Proposing and confirming recheck local eligibility; a confirmed plan cannot be re-proposed. Devices that have used a live plan reload their live plans on launch.

`FirebaseService` initializes platform-specific public FirebaseOptions only when needed. It implements anonymous Auth, App Check, Firestore live subscriptions, Remote Config and Firebase AI Logic. Missing configuration does not block sample/manual planning. Service failures are shown as recoverable product messages.

## AI boundary

Manual controls are fully functional without AI. Optional note drafting sends the note and current card to Google’s cloud model only after the person accepts an explicit disclosure. The result must parse into the exact allowlisted card schema and pass validation before review. The note is not persisted by MeetHalfway. This implementation does not perform on-device inference.

Shortlist explanation requires its own consent. Its payload contains approved cards under neutral labels (no member IDs) and the top three eligible candidates. Unknown/duplicate candidate IDs, invalid fields and oversized response text are rejected. A response is discarded if the plan revision changes while the request is running. The model never owns ranking, eligibility, permissions, votes or confirmation.

## Shared backend protocol

The migration kept the existing schema and rules. Two rule paths were added afterwards and must be deployed before the server enforces them (the client applies both either way): the host can renew an invitation, and a confirmed plan cannot be re-proposed.

- `rooms/{roomId}`: title, date, Toronto city, owner ID, member IDs, status, revision, current proposal, invitation reference, creation timestamp.
- `rooms/{roomId}/members/{uid}`: bounded display name, approved card, invitation reference and update timestamp.
- `rooms/{roomId}/votes/{uid}`: choice, candidate ID, proposal revision and update timestamp.
- `rooms/{roomId}/options/option-01` through `option-12`: bounded host activity data with source and setting fields.
- `invites/{48-hex-token}`: room ID, title, creator and expiry. Known unexpired capabilities can be retrieved; enumeration is denied.

Creation and joining use atomic batches. Preference/option updates atomically increment revision and clear the proposal. Proposals use a transaction to reject stale revisions and are refused once a plan is confirmed. When the shared invitation has less than a day left, the host's next share atomically points `lastJoinInviteId` at a new invite for the same room. Expired or unknown invitations, and joins past eight people, produce specific messages. Each participant writes only their own vote. Firestore rules require every current member’s acceptance of the same candidate and revision before the host confirms. Group size remains bounded at eight.

No raw-note, email, street-address or live-location field exists in shared room documents. Invitees can see approved room information; invitation links are capabilities that should be shared intentionally.

## Platform boundaries

The same Dart widgets render app content on every target. Sharing, URL launching, storage, Firebase SDK internals, keyboards and OS permissions use platform integrations. Calendar export is an `.ics` file with Toronto time-zone rules and date rollover handling. Android and iOS retain the registered identifier `app.meethalfway.mobile`.

Flutter’s native iOS runner requires macOS/Xcode and signing. Linux xtool applies only to retained legacy SwiftUI sources. See [platform details](PLATFORMS.md) and [verification](VERIFICATION.md).

## Product limits

Activity prices/hours/access are sample or host-provided; travel is estimated from neighbourhood centres. There is no live venue feed, route API, booking, account recovery, friends graph or cross-device private profile. Native offline local planning is supported; new Flutter web offline caching is not implemented. Rules remain a prototype requiring production review; tests establish specific behaviors rather than exhaustive security.
