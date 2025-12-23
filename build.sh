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

# Clean previous builds
echo "Cleaning previous builds..."
make clean-dist

# Build .love file
echo ""
echo "Building .love file..."
make love-file

# Build platform-specific packages
echo ""
echo "Select platform to build:"
echo "1) macOS (.app bundle)"
echo "2) Linux (instructions)"
echo "3) Windows (requires love-release)"
echo "4) All platforms"
echo "5) .love file only (cross-platform)"
read -p "Enter choice (1-5): " choice

case $choice in
    1)
        echo "Building macOS package..."
        make macos
        ;;
    2)
        echo "Building Linux package..."
        make linux
        echo ""
        echo "Linux users can run: love dist/tikrit-$VERSION.love"
        ;;
    3)
        echo "Building Windows package..."
        if command -v love-release &> /dev/null; then
            make windows
        else
            echo "Error: love-release not found."
            echo "Install with: luarocks install love-release"
            echo "Or manually bundle dist/tikrit-$VERSION.love with Love2D Windows executable"
        fi
        ;;
    4)
        echo "Building all platforms..."
        make release
        ;;
    5)
        echo ".love file already created at dist/tikrit-$VERSION.love"
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "Build complete!"
echo "Distribution files:"
ls -lh dist/
