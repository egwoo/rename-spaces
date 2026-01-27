#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
APP_BUNDLE_NAME="Rename Spaces"
EXECUTABLE_NAME="SpacesRenamer"
BUNDLE_ID="com.egwoo.spaces-renamer"

BUILD_DIR="$ROOT_DIR/.build/release"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_BUNDLE_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

cd "$ROOT_DIR"

swift build -c release

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BUILD_DIR/SpacesRenamerApp" "$MACOS_DIR/$EXECUTABLE_NAME"
chmod +x "$MACOS_DIR/$EXECUTABLE_NAME"

cp "$ROOT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
if [ -f "$ROOT_DIR/Resources/AppIcon.icns" ]; then
  cp "$ROOT_DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$CONTENTS_DIR/Info.plist" >/dev/null

printf "Built %s\n" "$APP_DIR"
