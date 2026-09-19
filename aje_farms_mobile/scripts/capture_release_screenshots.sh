#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DATE="${1:-$(date +%Y-%m-%d)}"
OUT="$ROOT/../docs/release-screenshots/$DATE"
DEVICE="${ANDROID_DEVICE:-}"

mkdir -p "$OUT/light" "$OUT/dark"

cd "$ROOT"

DEVICE_ARGS=()
if [[ -n "$DEVICE" ]]; then
  DEVICE_ARGS=(-d "$DEVICE")
fi

echo "Running release screenshot tour on device ${DEVICE:-default}..."
flutter test integration_test/release_screenshot_tour_test.dart "${DEVICE_ARGS[@]}"

SRC="$ROOT/build/integration_test_screenshots/release_screenshot_tour_test"
if [[ -d "$SRC" ]]; then
  cp -f "$SRC"/*.png "$OUT/light/" 2>/dev/null || true
  echo "Copied PNGs to $OUT/light/"
  ls -1 "$OUT/light/"*.png 2>/dev/null || true
else
  echo "No screenshots at $SRC — run on a connected Android emulator/device."
  echo "Example: ANDROID_DEVICE=emulator-5554 $0"
  exit 1
fi

echo "Done. Review images and move *-dark captures to $OUT/dark/ if needed."
