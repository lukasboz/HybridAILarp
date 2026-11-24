# Historical submission strategy

This file records the earlier hybrid-AI design for the separate native clients. The canonical application has since migrated to Flutter. The v0.3 implementation adds downloadable on-device drafting and separately approved cloud AI; the system-model hardware claims in the script below still describe the older native clients. See STATUS.md for current implementation and verification boundaries. The script and claims below are historical planning material, not evidence that the Flutter build satisfies any competition’s current rules. Reassess eligibility against the current official rules before using it.

# Submission and demonstration strategy

## Positioning

**MeetHalfway: private preferences, fairer plans.**

Pitch: “Every group has someone who compromises first. MeetHalfway helps friends find a plan that respects everyone’s limits. Local AI understands the private explanation. You approve a simple card. Cloud AI helps the group understand the options, and nobody is counted in until they say yes.”

This is a product and demonstration strategy, not a prediction that the entry will win. The strongest evidence will be a working cross-platform session and observed use by real groups.

## Match the judging criteria

| Criterion | Demonstrate | Evidence to collect |
| --- | --- | --- |
| Technological implementation | A successful local-only model call, a distinct cloud explanation, and one shared room across devices | Actual inference receipts, running SDK calls, emulator tests, cross-device recording |
| Design | One complete flow from invitation to calendar invitation | Phone and desktop footage; coherent empty, offline and unsupported-device states |
| Potential impact | A specific constrained group reaches an acceptable decision | Three observed group sessions, participant quotes with permission, honest timings |
| Quality of idea | Private explanations become approved shared constraints; the least-satisfied person matters | A budget change that removes an attractive option, no hidden relaxation, stale-vote rejection |

The [official rules](https://firebasehybridaihackathon.devpost.com/rules) require actual Firebase AI Logic runtime use, supported platform integration, App Check, an open-source repository and a public demonstration video of at most three minutes. The deadline is November 30, 2026 at 2 p.m. Pacific / 5 p.m. Toronto time. Recheck the live rules before submitting.

## Three-minute demo script

| Time | What the viewer sees | What to say |
| --- | --- | --- |
| 0:00–0:20 | A real planning problem and three different devices | “Three friends, three different limits, one afternoon. Nobody wants another fifty-message planning chat.” |
| 0:20–0:50 | Supported device: enter a private note; run local extraction; show editable card and receipt | “The explanation stays here. Only the card I approve is shared.” |
| 0:50–1:15 | Android, iPhone and desktop join the same live room | “Everyone can participate. This iPhone uses the downloaded model when supported, with the same manual controls available on every device.” |
| 1:15–1:45 | Raise/lower one hard limit; show the shortlist change and ruled-out explanation | “A good average doesn’t erase someone’s limit. We look after the least-satisfied person first.” |
| 1:45–2:05 | Disclosed cloud explanation; show an honest tradeoff | “The cloud sees approved cards and eligible options. It explains the decision; it can’t override the constraints.” |
| 2:05–2:35 | One person asks to discuss, a new proposal is made, stale votes disappear, all three accept | “No silent yes. A changed plan needs a new agreement.” |
| 2:35–2:50 | Confirmed plan and native calendar/share sheet | “Now it’s a real plan.” |
| 2:50–3:00 | Concise architecture and observed-user result | “Three platforms. Local privacy. Cloud coordination. A little closer to a good time.” |

Use real inference footage. If a recorded clip was captured on different hardware, label it. Never rename a deterministic sample calculation as AI or suggest sample catalogue data is live.

## Submission text outline

1. Inspiration: the organizer’s coordination work and the person who repeatedly compromises.
2. What it does: one concrete group journey, including a veto and a successful calendar invitation.
3. Hybrid architecture: the raw-note boundary, Firebase platform SDK calls, approved Firestore cards, optional cloud explanations and explicit inference modes.
4. Technical challenge: revision-based consent and bounded eight-person rules; explain the emulator-detected evaluation-limit fix.
5. Impact: observed group results, sample size and limits.
6. What was built during the contest: shared product interface, solver, native adapters, Firebase model and tests; disclose pre-existing tools and inspiration.
7. Testing instructions: hosted URL, exact build/install commands, hardware requirements and honest sample/live behavior.

## Evidence gates before calling this submission-ready

- Complete Google/Firebase provisioning and register App Check for every app.
- Deploy the website and verify an invitation across two independent browsers and both native apps.
- Install the canonical Flutter Android build and the locally signed Flutter iOS build, then verify their live-room and lifecycle behavior.
- Borrow compatible hardware and record successful native local inference where claimed.
- Add real group activities with checked source details for the actual demonstration.
- Review prototype rules and confirm all emulator tests pass.
- Perform visual QA at desktop and narrow phone widths and with keyboard/screen reader navigation.
- Record the three-minute video and prepare an open-source repository with instructions and license.

## Work sequence to the deadline

Finish deployment and physical-device verification first. Then run three real group sessions and fix confusion found in those sessions. Freeze core functionality before recording. Spend the final days on reliability, clear evidence, submission instructions and the video. A sourced venue/routing integration is valuable only after the full existing loop reliably works.
