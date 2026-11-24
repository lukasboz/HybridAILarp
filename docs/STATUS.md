# Project status

_As of November 23, 2026 · implementation version 0.3.0 (build 4)_

The canonical Flutter app is `app/`. `web/` and `native/` are historical clients.
This implementation pass follows the agreed scope: local AI where capable,
free providers first, principal product flows, then multi-stop planning.

## Implemented in this pass

| Area | Implementation |
| --- | --- |
| On-device AI | Flutter Edge AI / LiteRT-LM; pinned Qwen3 0.6B (~345 MB) on ARM64 phones and Gemma 4 E2B web (~2 GB). Capability probe, explicit download, progress/cancel/delete, validated card review, model receipts and a 120-second generation deadline. No automatic cloud fallback. |
| Discovery | Toronto OSM/Overpass searches by neighbourhood and interest, bounded requests, 24-hour caching, source attribution and host-reviewed import. Unknown prices/access are not invented. |
| Routes | User-approved, on-demand Transitous transit/walk/bike checks for neighbourhood-to-venue trips, with attribution and cached results. Provider routes are separate from deterministic estimates. |
| Accounts | Email/password sign-in, recovery, verification, anonymous-account linking, private approved-card/name sync and feedback defaults, sign-out, export and private account deletion. A guest with active plans must link an account or leave those plans before switching identities. |
| Plan management | Edit title/date and host options, variable activity length, rename self, leave/remove people, transfer host, revoke invitation capabilities and purge live plans. |
| Notifications | Live per-room Updates feed on the free plan; optional FCM installation registration, web worker, foreground/open handling, private inbox and bounded Cloud Functions delivery. Push remains disabled until explicitly configured. |
| Connectivity | Offline/cache notices, live header subscriptions and restored plans; versioned offline web shell after packaging. Model files use the inference library's separate cache. |
| Distribution | Android release key configuration without debug-key release fallback; ARM64 Android 11+ builds; native invitation handling; iOS distribution entitlements; real-identity app-link file generator. |
| Multi-stop | Ordered two/three-stop proposals, activity durations, cumulative costs and travel, shared-window/setting/access checks, same-revision unanimous approval, full-itinerary sharing/calendar export. |

## Activation still needed

No service deployment, billing change, account-provider activation, store upload,
or signing-key publication was performed.

1. Enable the configured email/password provider and deploy the updated rules
   before using the new account/lifecycle/schema paths against production.
2. Build/package and deploy Hosting to replace the older public client; publish
   the existing Remote Config template if it is still pending.
3. For background push only: opt into Blaze, deploy `functions/`, configure web
   VAPID/APNs credentials and set `pushEnabled` in the ignored client config.
   The Updates feed works without this service. See `functions/README.md`.
4. Supply actual Android release keys and an Apple distribution team/profile.
   Run `scripts/prepare-app-links.mjs` with real signing IDs and deploy the
   resulting `.well-known` files. Free iPhone development installs can use
   the custom invitation scheme; universal links/APNs need provisioned capabilities.
5. Review quotas before a public launch. Overpass and Transitous are community
   services; Transitous's public endpoint is limited to light, open-source,
   non-commercial use. Current requests are explicit and cached.

## Verification boundary

Functional tests, emulator flows, golden updates and physical-device validation
are deliberately deferred at the user's request. Static analysis, compilation
and rules syntax checks are tracked separately in `VERIFICATION.md`.

The earlier 34-test and real-Firebase/device results apply to v0.2 only. The
new navigation and screens will require updated visual baselines during the
later testing pass. A Mac runner is needed to compile the current iOS sources.

## Remaining product decisions

Friends/social graphs and reviews remain deferred. A commercial venue/events
provider, verified current prices/access and authoritative route-backed ranking
are separate from the implemented free lookup and host-review flow. Background
push/store distribution require external activation. Automatic reservations,
payments and private-note persistence are not part of this application.
