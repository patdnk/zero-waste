#!/usr/bin/env bash
# Downloads GitHub's open-source Mona Sans (SIL OFL) variable font into the app bundle and
# regenerates the Xcode project so it is picked up. Safe to re-run.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/ZeroWaste/Resources/Fonts"
TMP="$(mktemp -d)"
# Asset names carry the version (e.g. mona-sans-variable-v2.0.27.zip), so resolve the
# latest variable-font archive through the GitHub API rather than a fixed URL.
URL="$(curl -fsSL https://api.github.com/repos/github/mona-sans/releases/latest \
  | grep -o '"browser_download_url": *"[^"]*variable[^"]*\.zip"' | head -n 1 | sed 's/.*"\(https[^"]*\)"/\1/')"
if [[ -z "$URL" ]]; then
  echo "Could not find the Mona Sans variable font in the latest release." >&2
  exit 1
fi

echo "Downloading Mona Sans from $URL"
curl -fsSL "$URL" -o "$TMP/mona-sans.zip"
unzip -q -o "$TMP/mona-sans.zip" -d "$TMP/unzipped"

# Prefer the upright, normal-width variable font (the archive also ships italic, mono and
# width/italic-axis variants whose defaults render slanted or expanded).
FONT="$(find "$TMP/unzipped" -name 'MonaSansVF\[opsz,wght\].ttf' | head -n 1 || true)"
if [[ -z "$FONT" ]]; then
  FONT="$(find "$TMP/unzipped" -iname 'Mona-Sans.ttf' -not -path '*static*' | head -n 1 || true)"
fi
if [[ -z "$FONT" ]]; then
  FONT="$(find "$TMP/unzipped" -iname 'Mona*Sans*.ttf' -not -path '*static*' -not -iname '*Italic*' -not -iname '*Mono*' | head -n 1 || true)"
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
