#!/bin/bash
set -euo pipefail

MNEME_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if ! command -v uv >/dev/null 2>&1; then
    echo "Install uv from https://docs.astral.sh/uv/getting-started/installation/ first."
    exit 1
fi
if [ ! -x "$MNEME_ROOT/.venv/bin/python3" ]; then
    uv venv --python 3.12 "$MNEME_ROOT/.venv"
fi
uv pip install --python "$MNEME_ROOT/.venv/bin/python3" -r "$MNEME_ROOT/python/requirements.txt"
echo "Python helper dependencies installed. No app build or tests were run."
