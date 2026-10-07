#!/usr/bin/env bash
# Renders the app icons (and, with `marketing`, the App Store screenshots) from the same
# BrandMark.swift the app uses. Usage:
#   scripts/render-assets.sh icons
#   scripts/render-assets.sh marketing   # after updating appstore/raw (see appstore/README.md)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$(mktemp -d)/render-assets"

xcrun --sdk macosx swiftc -parse-as-library -O \
  "$ROOT/design/render-assets.swift" "$ROOT/design/Marketing.swift" "$ROOT/ZeroWaste/UI/BrandMark.swift" \
  -o "$BIN" 2>&1 | grep -v "^$" || true
[[ -x "$BIN" ]] || { echo "build failed" >&2; exit 1; }

case "${1:-icons}" in
  icons)
    "$BIN" icons "$ROOT/ZeroWaste/Assets.xcassets/AppIcon.appiconset"
    ;;
  marketing)
    "$BIN" marketing "$ROOT/appstore/raw" "$ROOT/appstore/screenshots"
    ;;
esac
