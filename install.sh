#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOVE_FINDER="$SCRIPT_DIR/scripts/find_love.sh"

echo "Checking Tikrit prerequisites"
echo "============================="

missing=0

if ! command -v lua >/dev/null 2>&1; then
    echo "- Missing: lua"
    missing=1
else
    echo "- Found: lua"
fi

if ! command -v luac >/dev/null 2>&1; then
    echo "- Missing: luac"
    missing=1
else
    echo "- Found: luac"
fi

if ! command -v make >/dev/null 2>&1; then
    echo "- Missing: make"
    missing=1
else
    echo "- Found: make"
fi

love_binary="$("$LOVE_FINDER" 2>/dev/null || true)"
if [ -z "$love_binary" ]; then
    echo "- Warning: Love2D runtime not found"
else
    echo "- Found: Love2D ($love_binary)"
fi

if [ "$missing" -ne 0 ]; then
    echo ""
    echo "Install the missing tools, then run this script again."
    exit 1
fi

echo ""
echo "Running syntax checks and tests..."
make -C "$SCRIPT_DIR" test

echo ""
if [ -n "$love_binary" ]; then
    echo "Tikrit is ready to run with: make"
else
    echo "Tests passed. Install Love2D or set LOVE_APP_PATH to run the game with: make"
fi
