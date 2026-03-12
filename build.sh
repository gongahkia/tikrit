#!/bin/bash
# Build script for Tikrit distribution packages

VERSION=$(cat VERSION)
echo "Building Tikrit v$VERSION"
echo "=========================="

# Check if Love2D is installed
if ! command -v love &> /dev/null; then
    echo "Error: Love2D not found. Please install Love2D first."
    echo "Visit: https://love2d.org/"
    exit 1
fi

echo "Running syntax checks and tests..."
make test

echo ""
echo "Cleaning previous builds..."
make clean-dist

echo ""
echo "Building .love file..."
make love-file

echo ""
echo "Build complete!"
echo "Distribution files:"
ls -lh dist/
