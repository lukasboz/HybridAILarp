# MeetHalfway for xtool

This is a native SwiftUI application packaged with SwiftPM for xtool. The source
archive includes the catalogue, photographs and Inter fonts in `Resources/Shared`
and `Resources/Fonts`. On a configured xtool Linux host, build and install with:

```sh
xtool dev
```

For a source checkout, first run `npm ci` and `npm run build` from the repository
root. Use a Swift/Apple SDK toolchain that supports Firebase's iOS 26 API
(Swift 6.2.3+; follow current xtool toolchain requirements).

The iOS package pins Firebase 12.19.3 to retain the iOS 26 hybrid API. The app
uses Firebase's system model with no cloud fallback for private notes. An
iPhone 13 cannot run Apple Intelligence; it can exercise manual controls,
sharing, calendar export and configured cloud group features.

The configured archive includes public Firebase client configuration in
`Resources/NativeConfig.plist`; the unconfigured source archive has an empty
template. For a source checkout, run the repository's Firebase setup helper
after signing in to retrieve native SDK identifiers. Its output is ignored by
Git. App Check debug tokens are generated privately by
debug builds and must be registered in Firebase App Check; never hardcode one.

xtool may prefix the signed bundle ID. Register that final identifier with
Firebase before relying on production App Check. The setup helper accepts
`--ios-bundle-id` for that purpose.

This package has not yet been built or run on the user's Linux/iPhone setup.
That is a required verification step, not a claimed successful result.
