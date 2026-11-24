# Platforms and distribution

One Flutter implementation in `app/` supplies all product screens. Layouts
respond to viewport size rather than OS. Platform integrations handle local
inference, storage, links, sharing, account SDKs and notification permissions.

## Web

```sh
npm run build
npm run preview
```

The release is packaged in `dist/`. Its versioned `sw.js` caches the app shell
after the first online visit. The downloaded model is stored separately by
Flutter Edge AI. Preparing a local model needs a secure WebGPU browser and about
2 GB for the dedicated Gemma 4 E2B web build; runtime/model setup must happen
online before offline inference is available. Ordinary manual planning does not
load the AI CDN runtime. Unsupported browsers retain manual and opt-in cloud AI.

The build synchronizer copies cache helpers from the locked dependency and
writes public Firebase messaging config. Web push is disabled unless the
optional backend and public VAPID key are configured. FCM has its own scoped
worker, separate from the offline shell worker. The web engine is pinned to
`@litert-lm/core@0.18.0`.

## Android

```sh
npm run build:android
```

The current local-runtime build targets ARM64 Android 11+ (`minSdk 30`). Its
Qwen3 0.6B download is about 345 MB and uses the conservative CPU backend. APK:
`app/build/app/outputs/flutter-apk/app-debug.apk`; application ID:
`app.meethalfway.mobile`. Other ABIs must retain the manual app through a
separate build without this native engine, rather than claim working inference.

To prepare distribution, copy `app/android/key.properties.example` to ignored
`app/android/key.properties`, with your actual keystore and passwords, then run
`npm run build:android:release`. Release builds no longer silently use debug keys.
Never commit or upload signing keys through source control.

Invitation handling supports the `meethalfway:` scheme and verified HTTPS links
on the configured Hosting domain. Verification needs the actual release signing
certificate fingerprint and a hosted assetlinks file.

## iOS

The shared Flutter source and ARM64 LiteRT-LM runtime require a Mac/Xcode runner
to compile. Qwen3 0.6B uses CPU; the baseline deployment target remains iOS 15.
The existing CI job builds an unsigned development app. It has not been run for
this implementation pass yet. Download its preserved `.app` tarball and use the
existing `scripts/install-ios.sh` on Linux for local development signing/install.

Custom-scheme invitations work without a paid domain-link entitlement. For
universal links, push and store distribution, provide a paid Apple team and
matching provisioning profile. Copy
`app/ios/Flutter/Distribution.example.xcconfig` to ignored `Distribution.xcconfig`
to opt into `Runner/Distribution.entitlements`. Set `DEVELOPMENT_TEAM` in the
signing environment. Use `APS_ENVIRONMENT=development` for an appropriately
provisioned development push build; distribution defaults to `production`.
Configure the matching APNs credential in Firebase before enabling push.

The Swift package/plugin dependencies are resolved by Flutter and the native
asset build hook. No manual PBX dependency edits are required.

## Verified invitation files

After building the website, supply real signing identities:

```sh
node scripts/prepare-app-links.mjs --android-sha256 YOUR_COLON_SEPARATED_FINGERPRINT
node scripts/prepare-app-links.mjs --apple-team-id YOUR_TEAM_ID --ios-bundle-id app.meethalfway.mobile
```

The generator rejects malformed identities and writes only the requested
platform files in `dist/.well-known/`. Deploy those files with Hosting and the
matching signed applications. Android Play App Signing uses the app-signing
certificate, not the upload certificate. Configure equivalent domains in the
manifests/entitlements when changing the Hosting URL.

## Build and verification boundary

This pass checks Dart analysis and compilation, not functional behavior. Tests,
new screenshots/goldens, model-quality measurements, offline reloads, browser
and phone permissions, real link verification, cross-device consensus and store
submission remain for the later testing/activation phase. Do not infer physical
platform verification from widget renderer tests or historical v0.2 results.
