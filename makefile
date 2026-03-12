compiler := love
VERSION := $(shell cat VERSION)
LOVE_APP_PATH ?= /Applications/love.app

all: build

build: src
	$(compiler) src

debug: src
	(time love src) 2>&1 | tee test/log.txt

clean:
	rm -f test/log.txt
	rm -rf dist/

syntax:
	@for file in src/main.lua src/config.lua src/modules/*.lua test/test_runner.lua test/run_tests.lua test/spec/*.lua; do \
		luac -p $$file || exit 1; \
	done

# Build distribution packages
dist: clean-dist verify-love-file
	@echo "Building distribution packages..."
	mkdir -p dist

# Create .love file (cross-platform Love2D package)
love-file:
	@echo "Creating .love file..."
	mkdir -p dist
	cd src && zip -9 -r ../dist/tikrit-$(VERSION).love .
	@echo "Created dist/tikrit-$(VERSION).love"

verify-love-file: love-file
	@echo "Verifying .love archive..."
	unzip -tqq dist/tikrit-$(VERSION).love
	@echo "Verified dist/tikrit-$(VERSION).love"

# macOS .app bundle
macos: love-file
	@echo "Building macOS app..."
	mkdir -p dist/macos
	if [ -d "$(LOVE_APP_PATH)" ]; then \
		cp -r "$(LOVE_APP_PATH)" dist/macos/Tikrit.app; \
		cat dist/macos/Tikrit.app/Contents/MacOS/love dist/tikrit-$(VERSION).love > dist/macos/Tikrit.app/Contents/MacOS/tikrit; \
		chmod +x dist/macos/Tikrit.app/Contents/MacOS/tikrit; \
		rm dist/macos/Tikrit.app/Contents/MacOS/love; \
		plutil -replace CFBundleName -string "Tikrit" dist/macos/Tikrit.app/Contents/Info.plist; \
		plutil -replace CFBundleIdentifier -string "com.gongahkia.tikrit" dist/macos/Tikrit.app/Contents/Info.plist; \
		plutil -replace CFBundleVersion -string "$(VERSION)" dist/macos/Tikrit.app/Contents/Info.plist; \
		cd dist/macos && zip -9 -r ../tikrit-$(VERSION)-macos.zip Tikrit.app; \
	else \
		cp dist/tikrit-$(VERSION).love dist/macos/; \
		printf "Install Love2D for macOS, then run:\nlove tikrit-$(VERSION).love\n" > dist/macos/README.txt; \
		cd dist/macos && zip -9 -r ../tikrit-$(VERSION)-macos.zip tikrit-$(VERSION).love README.txt; \
	fi
	@echo "Created dist/tikrit-$(VERSION)-macos.zip"

# Windows portable package
windows: love-file
	@echo "Creating Windows portable package..."
	mkdir -p dist/windows
	cp dist/tikrit-$(VERSION).love dist/windows/
	printf "Install Love2D for Windows, then open or run:\nlove tikrit-$(VERSION).love\n" > dist/windows/README.txt
	cd dist/windows && zip -9 -r ../tikrit-$(VERSION)-windows.zip tikrit-$(VERSION).love README.txt
	@echo "Created dist/tikrit-$(VERSION)-windows.zip"

# Linux portable package
linux: love-file
	@echo "Creating Linux portable package..."
	mkdir -p dist/linux
	cp dist/tikrit-$(VERSION).love dist/linux/
	printf "Install Love2D for Linux, then run:\nlove tikrit-$(VERSION).love\n" > dist/linux/README.txt
	cd dist/linux && zip -9 -r ../tikrit-$(VERSION)-linux.zip tikrit-$(VERSION).love README.txt
	@echo "Created dist/tikrit-$(VERSION)-linux.zip"

# Build all platforms
release: verify-love-file macos windows linux
	@echo "Release build complete!"
	@echo "Packages created in dist/"
	@ls -lh dist/

# Clean distribution files
clean-dist:
	rm -rf dist/

# Run automated tests
test: syntax
	@echo "Running Tikrit test suite..."
	@lua test/run_tests.lua

# Run tests with verbose output
test-verbose:
	@echo "Running Tikrit test suite (verbose)..."
	@lua test/run_tests.lua -v

.PHONY: all build debug clean syntax dist love-file verify-love-file macos windows linux release clean-dist test test-verbose
