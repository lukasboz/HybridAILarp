#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
test_device="${FLUTTER_TEST_DEVICE:-emulator-5554}"
test_host="${FIREBASE_TEST_HOST:-10.0.2.2}"
if [[ ! "$test_device" =~ ^[A-Za-z0-9:._-]+$ || ! "$test_host" =~ ^[A-Za-z0-9:._-]+$ ]]; then
  echo 'Use a device ID and emulator hostname containing only letters, digits, colons, dots, underscores or hyphens.' >&2
  exit 1
fi
export JAVA_HOME="${JAVA_HOME:-$repo_root/.cache/jdk21}"
export PATH="$JAVA_HOME/bin:$PATH"
# The disposable demo project prevents the test from accessing production rooms.
npx --cache "$repo_root/.cache/npm" --yes firebase-tools@latest emulators:exec \
  --only auth,firestore --project demo-meethalfway \
  "bash scripts/flutter.sh drive --driver=test_driver/firebase_flow_driver.dart --target=integration_test/firebase_flow_test.dart -d $test_device --no-dds --dart-define=FIREBASE_EMULATOR_HOST=$test_host"
