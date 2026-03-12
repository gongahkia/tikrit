#!/bin/bash

set -e

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

if ! command -v love >/dev/null 2>&1; then
    echo "- Missing: Love2D"
    missing=1
else
    echo "- Found: Love2D"
fi

if [ "$missing" -ne 0 ]; then
    echo ""
    echo "Install the missing tools, then run this script again."
    exit 1
fi

echo ""
echo "Running syntax checks and tests..."
make test

echo ""
echo "Tikrit is ready to run with: make"
