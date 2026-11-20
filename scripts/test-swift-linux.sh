#!/usr/bin/env bash
set -euo pipefail
workspace=$(pwd)
export LD_LIBRARY_PATH="$workspace/.cache/swift/runtime/lib/aarch64-linux-gnu:$workspace/.cache/swift/runtime/usr/lib/aarch64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
compiler=${SWIFTC:-$workspace/.cache/swift/swift-6.2.3-RELEASE-ubuntu24.04-aarch64/usr/bin/swiftc}
"$compiler" -frontend -parse native/ios/Sources/MeetHalfway/*.swift
if [[ "${1:-}" == "--parse-only" ]]; then
  echo "Swift source parsing passed (iOS SDK type checking still required)."
  exit 0
fi
"$compiler" native/ios/Sources/MeetHalfway/Models.swift tests/SwiftPlannerTests.swift -o .cache/swift-planner-tests
.cache/swift-planner-tests shared
