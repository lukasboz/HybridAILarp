# MeetHalfway product specification

## Product promise

“Find a plan everyone can get behind, without making everyone explain themselves.”

MeetHalfway turns a group’s separate preferences into a real shared decision. The first audience is Toronto friends, roommates and small social groups who want an inexpensive afternoon or evening together and have different budgets, interests, starting areas and energy levels. The primary outcome is a mutually accepted activity and a calendar invitation.

The shared Flutter app offers downloaded local drafting and optional cloud AI with explicit consent. A person may ask the model to draft a preference card from a note, edit it, then review exactly what is shared. Cloud shortlist explanations require separate consent. Manual controls and deterministic planning work without AI. Raw notes are not saved by MeetHalfway.

## Why someone would use it twice

The organizer stops collecting conflicting answers in a chat. The person with the tightest budget can state a limit without explaining why. The person farthest away can compare travel burden. Everyone retains a clear veto before the plan is confirmed. After the meetup, local feedback seeds the next preference card.

Initial success should mean a real group can go from invitation to a confirmed, feasible plan with little prompting. The team should measure this with observed sessions, not invented conversion figures.

## Core scenario

Alex wants something creative, Maya needs to spend less than $25, and Jordan needs a reasonable trip from Liberty Village. They each review a card. The app computes an overlapping 90-minute window, excludes expensive or inconvenient choices, and ranks what remains with the least-satisfied person’s fit as the first criterion. The host proposes one option. Maya asks to discuss it, so confirmation remains disabled. The group revises the choice, every person accepts the new revision, and the host confirms it.

The reason behind a budget never needs to enter the room. The budget amount itself is a shared constraint and appears explicitly in the review screen. This distinction is essential to the privacy promise.

## Experience and screens

### My plans

A warm, task-focused home screen presents active plans, a clear Make a plan action, a Join a plan action, and an explorable sample group. A pale-blue canvas, ice-blue glass orb, activity-photo orbit and translucent controls follow Yumi’s web-dashboard design across desktop and mobile. The desktop has a stable sidebar; narrow screens use bottom navigation with reachable controls.

Sample content is visibly labelled. It is an interaction sandbox, not evidence of live friends or actual AI requests.

### Create or join

The host supplies a title, date and first name. A live room uses an anonymous Firebase identity so joining does not start with a registration wall. Invitation links are long random capabilities, expire after seven days, and admit at most eight people. When the current link has less than a day left, the host's next share creates a fresh one. The create and join screens tell people that invitees can read names and approved cards.

The local exploration mode is a separate choice that stores the room on the current device and supports sample participants. It must never present its invitation as a real cross-device link.

Anonymous identity is convenient but lacks account recovery after browser data is lost. Email/password account linking preserves a guest’s UID and memberships; account defaults sync privately. Hosts can transfer ownership to another current member. An existing-account sign-in is blocked until a guest preserves or leaves their rooms.

### Personal preferences

The person selects a coarse Toronto neighbourhood, a hard spending ceiling, a hard travel limit, transport mode, available time range, interests, and any quiet/indoor/confirmed-step-free requirements. The private note is optional and memory-only. It is not stored in Firestore or local storage.

After an explicit disclosure and affirmative consent, Firebase AI Logic can extract an editable card using a cloud model. Without that consent the note is not transmitted. Manual controls remain available. An optional downloaded model can also draft the card locally, with capability checks and no automatic cloud fallback.

The review screen lists exactly what will be shared, including the budget amount and neighbourhood. Sharing is an affirmative action. Updating the card reopens the group decision and invalidates previous votes.

### Activities and sourcing

The built-in Toronto catalogue demonstrates the product. Its price, schedule, access and travel properties are fixtures and are labelled accordingly. Venue links are verification destinations, not claims of partnerships or data freshness.

For an actual group, the host can add up to twelve activities with a name, venue, neighbourhood, per-person cost estimate, time window, main interest, setting, short description, source link and optional host-confirmed step-free access. Adding the first activity replaces the sample catalogue for that room. Host-reported access is distinguished from independently verified access.

An eventual commercial provider should supply provenance, current prices, opening hours and routes. That work is a release gate for claims of automatic live venue discovery. The current product does not silently substitute fictional availability.

### The shortlist

The engine excludes an activity if any member’s spending, travel, time, quiet, indoor or access requirement fails. Unknown step-free access fails a step-free requirement. If nobody fits, the product explains why. It never autonomously relaxes a hard limit.

Surviving activities are ordered by:

1. Highest lowest-person fit.
2. Highest mean fit when the lowest fits tie.
3. Lowest maximum travel burden.
4. Lowest cost.
5. A stable ID tie-breaker.

The fit estimate combines interest overlap, budget headroom and estimated travel convenience. It is not a probability or a prediction of happiness. A detail view makes each person’s fit visible using the room’s shared cards.

The detail view's map is an illustrative Toronto schematic. Its arcs show neighbourhood-to-activity relationships, and each person's estimated travel appears beside their own limit. It is not a navigation map. Travel is estimated from neighbourhood centres, not precise addresses or live TTC conditions.

Cloud explanations are optional and require a clear disclosure. The model receives allowlisted cards and eligible candidates, explains aggregate group fit and tradeoffs, and returns only known candidate IDs. It cannot add a venue or bypass the deterministic filter.

### A group decision

The host can put an eligible activity to the group. Each participant can accept, ask to discuss, or decline. Votes identify both candidate and proposal revision. Stale acceptance cannot confirm a different proposal. The host can confirm only when every current member accepts the current revision.

Changing a card, adding a person, or adding an activity reopens the decision. The product should communicate that change plainly, rather than showing old acceptance as current consent.

### Make it happen

A confirmed plan includes the day, Toronto local start time, venue, estimated cost and reminders to verify details or arrange booking. Calendar export includes the America/Toronto time zone and daylight-saving rules. Flutter sharing integrations use available OS/browser share targets, with invitation copying as a fallback.

There is no automatic reservation, payment, plan email, SMS or contact upload. Account verification and password recovery use Firebase email. Confirmation means the participants accepted a plan, not that a venue accepted a booking.

### Feedback

After a plan, the participant can ask for more like it or something different. That feedback changes only their defaults on the current device. It never rewrites another person’s preferences or adds a private review to cloud history.

## Hard product requirements

| Requirement | Acceptance condition |
| --- | --- |
| All three platforms | One Flutter implementation provides the same planning flow and visual controls on Android, iOS and web. Native iOS requires macOS/Xcode and signing. |
| Explicit AI consent | Raw notes are sent to cloud AI only after a person accepts the disclosure; they are never persisted in app storage or Firestore. |
| Sharing control | The exact allowlisted card is shown before publishing it. |
| Group fairness | One member’s hard limit can exclude an option regardless of average fit. |
| Consensus | A new proposal cannot inherit votes from an earlier revision. |
| Source honesty | Sample, host-provided, estimated and unverified data remain labelled. |
| Manual participation | All preference controls and deterministic planning work without AI; an unsent note stays in the editor. |
| AI honesty | A receipt appears only after a real inference response. |
| Access control | Uninvited identities cannot read a planning room or forge another member’s vote. |
| Accessibility | Keyboard focus, dialog focus trapping, semantic labels and reduced-motion styles support the primary flow. |

## Validation and impact evidence

Before the submission, recruit three small groups and observe a real planning task. Record time to agreement, changes requested, excluded options that would otherwise have caused friction, and whether participants understood the sharing screen. Ask the most constrained participant whether the shortlist respected their situation.

Do not claim a percentage improvement without collecting a baseline. Report the sample size and outcome plainly. A small, credible study is more useful than broad, unsupported market claims.

## Scope after the hackathon

The v0.3 implementation adds free place/route lookup, lifecycle flows, account linking, invite revocation, export/deletion, optional push and two/three-stop planning. Next consider a commercial data provider with independently verified prices/access, authoritative route-backed ranking, friends and reviews. Add weather-aware alternatives only with sourced weather data. Push notifications, chat, automatic reservations, contacts access and payments are separate decisions, not necessary dependencies of a good first plan.
