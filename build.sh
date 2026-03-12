#!/bin/bash
# Build script for Tikrit distribution packages

VERSION=$(cat VERSION)
echo "Building Tikrit v$VERSION"
echo "=========================="

# Check archive tooling
if ! command -v zip &> /dev/null || ! command -v unzip &> /dev/null; then
    echo "Error: zip and unzip are required to package Tikrit."
    exit 1
fi

echo "Running syntax checks and tests..."
make test

echo ""
echo "Cleaning previous builds..."
make clean-dist

echo ""
echo "Building and verifying .love file..."
make verify-love-file

echo ""
echo "Build complete!"
echo "Distribution files:"
ls -lh dist/
