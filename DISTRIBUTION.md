# Tikrit - Distribution Guide

This guide explains how to build and distribute Tikrit for different platforms.

## Quick Start

### For Users

**Running the .love file (all platforms):**
1. Install [Love2D](https://love2d.org/) for your platform
2. Download `tikrit-X.X.X.love`
3. Run: `love tikrit-X.X.X.love`
   - Or drag the .love file onto the Love2D executable
   - Or double-click if Love2D is associated with .love files

### For Developers

**Building distribution packages:**

```bash
# Option 1: Interactive build script
./build.sh

# Option 2: Using make directly
make love-file      # Create .love file only
make macos          # Create macOS .app bundle
make release        # Create all available packages
```

## Build Requirements

### All Platforms
- Love2D 11.4 or higher
- zip utility (usually pre-installed)

### macOS
- Love2D.app installed in `/Applications/`
- `plutil` (pre-installed on macOS)

### Windows
- `love-release` tool (optional, for automated builds)
  ```bash
  luarocks install love-release
  ```

### Linux
- No additional requirements (distributes .love file)

## Distribution Packages

### .love File (Cross-platform)
The `.love` file is a zip archive containing the game source code.

**Created by:** `make love-file`

**Location:** `dist/tikrit-X.X.X.love`

**Usage:**
- Works on any platform with Love2D installed
- Smallest file size
- Requires users to install Love2D separately

### macOS .app Bundle
A native macOS application bundle.

**Created by:** `make macos`

**Location:** `dist/tikrit-X.X.X-macos.zip`

**Usage:**
- Double-click to run (no Love2D installation required)
- Self-contained application
- Larger file size (~10-15MB)

**Installation:**
1. Download and unzip `tikrit-X.X.X-macos.zip`
2. Drag `Tikrit.app` to Applications folder
3. First run: Right-click → Open (to bypass Gatekeeper)

### Windows .exe
A standalone Windows executable.

**Created by:** `make windows` (requires love-release)

**Manual Creation:**
1. Download Love2D Windows binaries
2. Concatenate: `copy /b love.exe+tikrit.love tikrit.exe`
3. Include SDL DLLs with executable

### Linux
Linux users can run the .love file directly.

**Created by:** `make linux`

**Usage:**
```bash
# Install Love2D (Ubuntu/Debian)
sudo apt-get install love

# Run game
love tikrit-X.X.X.love
```

## Version Management

**Updating version number:**
1. Edit `VERSION` file
2. Edit `makefile` VERSION variable
3. Update `CHANGELOG.md`
4. Commit changes
5. Create git tag: `git tag -a vX.X.X -m "Release vX.X.X"`

## Release Checklist

Before creating a release:

- [ ] Update VERSION file
- [ ] Update CHANGELOG.md with new features/fixes
- [ ] Test game on all target platforms
- [ ] Run `make reset` to ensure fresh maps
- [ ] Build distribution packages
- [ ] Test distribution packages
- [ ] Create GitHub release with packages
- [ ] Update README.md download links

## File Structure

```
dist/
├── tikrit-X.X.X.love              # Cross-platform Love2D package
├── tikrit-X.X.X-macos.zip         # macOS app bundle
├── tikrit-X.X.X-windows.zip       # Windows executable (if built)
└── macos/                          # macOS build artifacts
    └── Tikrit.app
```

## Troubleshooting

### macOS: "Tikrit.app is damaged and can't be opened"
This is Gatekeeper security. Right-click the app and select "Open".

### Windows: "Windows protected your PC"
Click "More info" → "Run anyway". The app is unsigned.

### Love2D version mismatch
Ensure you're using Love2D 11.4+ for compatibility.

## CI/CD Integration

For automated builds, integrate these commands:

```yaml
# GitHub Actions example
- name: Build .love file
  run: make love-file

- name: Build macOS package
  run: make macos
  if: runner.os == 'macOS'

- name: Upload artifacts
  uses: actions/upload-artifact@v2
  with:
    name: tikrit-builds
    path: dist/
```

## Publishing

### Itch.io
1. Create project at https://itch.io
2. Upload .love file for "Linux/Mac/Windows"
3. Set "This file will be played in the browser" = No
4. Set "Kind of project" = Downloadable

### GitHub Releases
1. Create tag: `git tag -a vX.X.X -m "Release vX.X.X"`
2. Push tag: `git push origin vX.X.X`
3. Create release on GitHub with built packages
4. Add release notes from CHANGELOG.md

## License

Remember to include LICENSE file in all distributions.
