#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -x "$repo_root/.cache/flutter/bin/flutter" ]]; then
  flutter_bin="$repo_root/.cache/flutter/bin/flutter"
else
  flutter_bin="$(command -v flutter || true)"
fi
if [[ -z "$flutter_bin" ]]; then
  echo 'Install the Flutter SDK and put flutter on PATH, or extract it to .cache/flutter.' >&2
  exit 1
fi
python3 "$repo_root/scripts/sync-flutter-assets.py"
export PUB_CACHE="${PUB_CACHE:-$repo_root/.cache/pub}"
export FLUTTER_SUPPRESS_ANALYTICS=true
export GRADLE_USER_HOME="${GRADLE_USER_HOME:-$repo_root/.cache/gradle}"
if [[ -d "$repo_root/.cache/android-sdk" ]]; then
  export ANDROID_HOME="${ANDROID_HOME:-$repo_root/.cache/android-sdk}"
fi
if [[ -x "$repo_root/.cache/jdk21/bin/javac" ]]; then
  export JAVA_HOME="${JAVA_HOME:-$repo_root/.cache/jdk21}"
fi
cd "$repo_root/app"
exec "$flutter_bin" "$@"
