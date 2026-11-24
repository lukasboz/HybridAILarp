#!/usr/bin/env python3
"""Verify and package a signed ARM64 APK plus its optional Play bundle."""
from pathlib import Path
import hashlib
import json
import os
import re
import shutil
import subprocess

root = Path(__file__).resolve().parents[1]
apk = root / 'app/build/app/outputs/flutter-apk/app-release.apk'
bundle = root / 'app/build/app/outputs/bundle/release/app-release.aab'
if not apk.is_file() or not (root / 'dist/index.html').is_file():
    raise SystemExit('Build the signed release APK and package Flutter web first.')
sdk = Path(os.environ.get('ANDROID_HOME', root / '.cache/android-sdk'))
verifiers = sorted(sdk.glob('build-tools/*/apksigner'))
if not verifiers:
    raise SystemExit('Install Android SDK build-tools to verify the APK signature.')
result = subprocess.run([str(verifiers[-1]), 'verify', '--print-certs', str(apk)], check=True, capture_output=True, text=True)
match = re.search(r'Signer #1 certificate SHA-256 digest: ([a-fA-F0-9]{64})', result.stdout)
if not match:
    raise SystemExit('Could not identify the verified APK signing certificate.')
fingerprint = ':'.join(match[1][i:i+2].upper() for i in range(0, 64, 2))
version = re.search(r'^version: (.+)$', (root / 'app/pubspec.yaml').read_text(), re.M)[1]
output = root / 'artifacts/android'
downloads = root / 'dist/downloads'
output.mkdir(parents=True, exist_ok=True)
downloads.mkdir(parents=True, exist_ok=True)
files = {}
for source, extension in [(apk, 'apk'), (bundle, 'aab')]:
    if not source.exists():
        continue
    name = f'MeetHalfway-{version}.{extension}'
    shutil.copyfile(source, output / name)
    files[name] = {'bytes': source.stat().st_size, 'sha256': hashlib.sha256(source.read_bytes()).hexdigest()}
# Spark Hosting rejects executable binaries. Keep installable files in the
# private release artifacts/App Distribution, never disguise their extension.
(downloads / 'meethalfway-android.apk').unlink(missing_ok=True)
manifest = {'version': version, 'androidMinVersion': 11, 'abi': 'arm64-v8a', 'certificateSha256': fingerprint, 'files': files}
(output / 'release.json').write_text(json.dumps(manifest, indent=2) + '\n')
(downloads / 'release.json').write_text(json.dumps(manifest, indent=2) + '\n')
subprocess.run(['node', str(root / 'scripts/prepare-app-links.mjs'), '--directory', str(root / 'dist'), '--android-sha256', fingerprint], check=True)
print(f'Packaged verified Android {version}; model files remain opt-in downloads inside the app.')
