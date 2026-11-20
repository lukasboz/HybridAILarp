"""Package only known build outputs; never include caches or account credentials."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import shutil

root=Path(__file__).resolve().parents[1]
out=root/"artifacts"
out.mkdir(exist_ok=True)
apk=root/"native/android/app/build/outputs/apk/debug/app-debug.apk"
if apk.exists():
    shutil.copy2(apk,out/"MeetHalfway-android-debug.apk")

ios=root/"native/ios"
with ZipFile(out/"MeetHalfway-xtool-source.zip","w",ZIP_DEFLATED) as archive:
    for file in ios.rglob("*"):
        if not file.is_file(): continue
        relative=file.relative_to(ios)
        if any(part.startswith(".") for part in relative.parts): continue
        if file.name in {"GoogleService-Info.plist","Package.resolved"}: continue
        # Only include an empty config template in the source export. Configured
        # binaries and SDK configurations can be prepared separately by the owner.
        if relative.as_posix()=="Resources/NativeConfig.plist":
            archive.writestr("MeetHalfway/Resources/NativeConfig.plist",'<?xml version="1.0"?><plist version="1.0"><dict></dict></plist>')
        elif file.name=="firebase-config.local.json":
            continue
        else:
            archive.write(file,Path("MeetHalfway")/relative)

with ZipFile(out/"MeetHalfway-web.zip","w",ZIP_DEFLATED) as archive:
    for file in (root/"dist").rglob("*"):
        if file.is_file() and file.name!="firebase-config.local.json":
            archive.write(file,file.relative_to(root/"dist"))

# Owner-ready export: public client identifiers, never account credentials,
# service account files, signing keys, App Check debug tokens, or caches.
with ZipFile(out/"MeetHalfway-xtool-configured.zip","w",ZIP_DEFLATED) as archive:
    for file in ios.rglob("*"):
        if not file.is_file(): continue
        relative=file.relative_to(ios)
        if any(part.startswith(".") for part in relative.parts): continue
        if file.name in {"GoogleService-Info.plist","Package.resolved"}: continue
        archive.write(file,Path("MeetHalfway")/relative)
    archive.writestr("MeetHalfway/START-HERE.md", """# MeetHalfway for xtool on Linux

This export includes native SwiftUI screens, shared Yumi-inspired design resources and public Firebase
client configuration for meethalfway-2026-e43ca6. No Node build is needed.

1. Configure xtool, Apple's SDK, device pairing, and your own signing account.
2. Plug in your iPhone and run `xtool dev` in this directory.
3. Register the SDK-generated App Check debug token privately in Firebase's
   App Check console before trying cloud AI. Never post that token publicly.
4. Open the app and try the sample group, then a live invitation.

iPhone 13 supports the manual interface and cloud features, but has no Apple
Intelligence local model. This source export has not yet been compiled with
xtool. Match the final signed bundle ID to Firebase before production App Attest.
""")
print("Packaged native Compose APK, SwiftUI xtool source packages, and web distribution.")
