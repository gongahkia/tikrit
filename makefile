compiler := love
VERSION := 2.5.0

all: reset

build: src
	clear && love src

reset:
	cp map/1-fresh.txt map/1.txt && cp map/2-fresh.txt map/2.txt && cp map/3-fresh.txt map/3.txt && cp map/4-fresh.txt map/4.txt && cp map/5-fresh.txt map/5.txt && cp map/6-fresh.txt map/6.txt && cp map/7-fresh.txt map/7.txt && cp map/8-fresh.txt map/8.txt && cp map/9-fresh.txt map/9.txt && cp map/10-fresh.txt map/10.txt && cp map/11-fresh.txt map/11.txt && cp map/12-fresh.txt map/12.txt && cp map/13-fresh.txt map/13.txt && cp map/14-fresh.txt map/14.txt && cp map/15-fresh.txt map/15.txt && cp map/16-fresh.txt map/16.txt

debug: src
	(time love src) 2>&1 | tee test/log.txt

clean:
	rm -f test/log.txt
	rm -rf dist/

# Build distribution packages
dist: clean-dist love-file
	@echo "Building distribution packages..."
	mkdir -p dist

# Create .love file (cross-platform Love2D package)
love-file:
	@echo "Creating .love file..."
	mkdir -p dist
	cd src && zip -9 -r ../dist/tikrit-$(VERSION).love .
	@echo "Created dist/tikrit-$(VERSION).love"

# macOS .app bundle
macos: love-file
	@echo "Building macOS app..."
	mkdir -p dist/macos
	cp -r /Applications/love.app dist/macos/Tikrit.app 2>/dev/null || \
		(echo "Error: love.app not found in /Applications. Please install Love2D first." && exit 1)
	cat dist/macos/Tikrit.app/Contents/MacOS/love dist/tikrit-$(VERSION).love > dist/macos/Tikrit.app/Contents/MacOS/tikrit
	chmod +x dist/macos/Tikrit.app/Contents/MacOS/tikrit
	rm dist/macos/Tikrit.app/Contents/MacOS/love
	# Update Info.plist
	plutil -replace CFBundleName -string "Tikrit" dist/macos/Tikrit.app/Contents/Info.plist
	plutil -replace CFBundleIdentifier -string "com.gongahkia.tikrit" dist/macos/Tikrit.app/Contents/Info.plist
	plutil -replace CFBundleVersion -string "$(VERSION)" dist/macos/Tikrit.app/Contents/Info.plist
	cd dist/macos && zip -9 -r ../tikrit-$(VERSION)-macos.zip Tikrit.app
	@echo "Created dist/tikrit-$(VERSION)-macos.zip"

# Windows .exe (requires love-release or manual bundling)
windows: love-file
	@echo "Windows build requires love-release tool or manual bundling"
	@echo "Install with: luarocks install love-release"
	@echo "Then run: love-release -W -M dist/tikrit-$(VERSION).love"

# Linux AppImage (simplified - just bundle .love with instructions)
linux: love-file
	@echo "Linux distribution package created"
	@echo "Users can run with: love dist/tikrit-$(VERSION).love"

# Build all platforms
release: love-file macos
	@echo "Release build complete!"
	@echo "Packages created in dist/"
	@ls -lh dist/

# Clean distribution files
clean-dist:
	rm -rf dist/

.PHONY: all build reset debug clean dist love-file macos windows linux release clean-dist

