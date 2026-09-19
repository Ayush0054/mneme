#!/bin/bash
set -euo pipefail

MNEME_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MNEME_APP="$MNEME_ROOT/dist/Mneme.app"
MNEME_PYTHON="$MNEME_ROOT/.venv/bin/python3"
MNEME_IDENTITY="${MNEME_SIGNING_IDENTITY:--}"

# This script builds code. Run it only after the user authorizes validation.
swift build --package-path "$MNEME_ROOT" -c release
MNEME_BIN="$(swift build --package-path "$MNEME_ROOT" -c release --show-bin-path)"
mkdir -p "$MNEME_APP/Contents/MacOS" "$MNEME_APP/Contents/Resources"
mkdir -p "$MNEME_APP/Contents/Resources/Fonts"
cp "$MNEME_BIN/Mneme" "$MNEME_APP/Contents/MacOS/Mneme"
cp "$MNEME_ROOT/Resources/Info.plist" "$MNEME_APP/Contents/Info.plist"
cp "$MNEME_ROOT/Resources/Fonts/"* "$MNEME_APP/Contents/Resources/Fonts/"
cp "$MNEME_ROOT/python/matcher.py" "$MNEME_APP/Contents/Resources/matcher.py"
printf '%s\n' "$MNEME_PYTHON" > "$MNEME_APP/Contents/Resources/python-path.txt"
# Record only the project location. Never copy the .env or its contents into the app.
printf '%s\n' "$MNEME_ROOT" > "$MNEME_APP/Contents/Resources/project-path.txt"
codesign --force --sign "$MNEME_IDENTITY" --identifier dev.mneme.clipboard "$MNEME_APP"
echo "Created $MNEME_APP"
if [ ! -x "$MNEME_PYTHON" ]; then
    echo "Ordered paste is available. Run scripts/setup.sh to enable the Python Smart Paste helper."
fi
echo "Launch with: open \"$MNEME_APP\""
echo "Keep this source folder in place: Smart Paste uses its Python environment."
