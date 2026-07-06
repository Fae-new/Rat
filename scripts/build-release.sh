#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Rat"
BUNDLE_ID="com.fae.Rat"
BUILD_DIR="$ROOT_DIR/build"
APP_DIR="$BUILD_DIR/Release/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

swift "$ROOT_DIR/scripts/generate-icons.swift"
iconutil -c icns "$BUILD_DIR/RatIcon.iconset" -o "$ROOT_DIR/Rat/Resources/RatIcon.icns"

swiftc \
  -parse-as-library \
  -target arm64-apple-macosx13.0 \
  -O \
  $(find "$ROOT_DIR/Rat" -name '*.swift' | sort) \
  -o "$MACOS_DIR/$APP_NAME"

cp "$ROOT_DIR/Rat/Resources/RatMenuBarIcon.png" "$RESOURCES_DIR/"
cp "$ROOT_DIR/Rat/Resources/RatLogo.png" "$RESOURCES_DIR/"
cp "$ROOT_DIR/Rat/Resources/RatIcon.icns" "$RESOURCES_DIR/"

/usr/libexec/PlistBuddy -c "Clear dict" "$CONTENTS_DIR/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleDevelopmentRegion string en" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string $APP_NAME" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string $BUNDLE_ID" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleInfoDictionaryVersion string 6.0" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleName string $APP_NAME" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string APPL" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string 1.0" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string 1" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string RatIcon" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Add :LSMinimumSystemVersion string 13.0" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Add :LSUIElement bool true" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Add :NSAccessibilityUsageDescription string Rat needs Accessibility permission to listen for mouse buttons and run desktop navigation shortcuts." "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Add :NSInputMonitoringUsageDescription string Rat needs Input Monitoring permission to detect extra mouse buttons." "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Add :NSAppleEventsUsageDescription string Rat needs permission to ask System Events to run desktop navigation keyboard shortcuts." "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Add :NSPrincipalClass string NSApplication" "$CONTENTS_DIR/Info.plist"

plutil -convert xml1 "$CONTENTS_DIR/Info.plist"
codesign --force --deep --sign - "$APP_DIR"

echo "$APP_DIR"
