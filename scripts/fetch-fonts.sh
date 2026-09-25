#!/usr/bin/env bash
# Downloads GitHub's open-source Mona Sans (SIL OFL) variable font into the app bundle and
# regenerates the Xcode project so it is picked up. Safe to re-run.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/ZeroWaste/Resources/Fonts"
TMP="$(mktemp -d)"
URL="https://github.com/github/mona-sans/releases/latest/download/Mona-Sans.zip"

echo "Downloading Mona Sans from $URL"
curl -fsSL "$URL" -o "$TMP/mona-sans.zip"
unzip -q -o "$TMP/mona-sans.zip" -d "$TMP/unzipped"

# Prefer the single variable font; fall back to any Mona Sans TTF that isn't a static instance.
FONT="$(find "$TMP/unzipped" -iname 'Mona-Sans.ttf' -not -path '*static*' | head -n 1 || true)"
if [[ -z "$FONT" ]]; then
  FONT="$(find "$TMP/unzipped" -iname 'Mona*Sans*.ttf' -not -path '*static*' | head -n 1 || true)"
fi
if [[ -z "$FONT" ]]; then
  echo "Could not find a Mona Sans TTF in the archive." >&2
  exit 1
fi

mkdir -p "$DEST"
cp "$FONT" "$DEST/Mona-Sans.ttf"
echo "Installed $(basename "$FONT") → ZeroWaste/Resources/Fonts/Mona-Sans.ttf"

if command -v xcodegen >/dev/null 2>&1; then
  (cd "$ROOT" && xcodegen generate)
else
  echo "xcodegen not found — run 'xcodegen generate' in $ROOT to add the font to the project."
fi
rm -rf "$TMP"
