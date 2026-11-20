# MeetHalfway Flutter app

This is the canonical app for web, Android and iOS. The platform folders host the same UI implemented in `lib/`.

From the repository root:

```sh
bash scripts/flutter.sh pub get
bash scripts/flutter.sh run -d web-server --web-port 4173
bash scripts/flutter.sh test
bash scripts/flutter.sh analyze
bash scripts/flutter.sh build apk --debug
```

Use the wrapper to synchronize shared assets and public Firebase client configuration. See the [root README](../README.md) and [migration guide](../docs/FLUTTER.md) for iOS signing, Firebase configuration and the distinction between shared visual tests and native device verification.
