#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
install_bundle="${1:-$repo_root/artifacts/ios/Runner.app}"
if [[ ! -d "$install_bundle" && ! -f "$install_bundle" ]]; then
  echo 'Download and unpack the iOS development artifact first; pass a .app or .ipa path.' >&2
  exit 1
fi
if ! command -v xtool >/dev/null || ! command -v idevice_id >/dev/null; then
  echo 'Install/configure xtool and libimobiledevice before running this helper.' >&2
  exit 1
fi
mapfile -t iphone_devices < <(idevice_id -l)
iphone_id="${IOS_DEVICE_ID:-}"
if [[ -z "$iphone_id" ]]; then
  if [[ "${#iphone_devices[@]}" -ne 1 ]]; then
    echo 'Connect and unlock one paired iPhone, or set IOS_DEVICE_ID to select it.' >&2
    exit 1
  fi
  iphone_id="${iphone_devices[0]}"
fi
# Public Firebase options are data assets; they can be refreshed before the
# downloaded Flutter app is signed locally, without recompiling Dart/Xcode.
firebase_asset="$install_bundle/Frameworks/App.framework/flutter_assets/assets/firebase.json"
if [[ -d "$install_bundle" && -f "$firebase_asset" ]]; then
  python3 "$repo_root/scripts/sync-flutter-assets.py"
  cp "$repo_root/app/assets/firebase.json" "$firebase_asset"
fi
# xtool signs locally with the existing Apple account and asks before revoking
# certificates. No Apple credential or signing key is sent to the build runner.
exec xtool install --usb --udid "$iphone_id" "$install_bundle"
