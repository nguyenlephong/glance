#!/usr/bin/env bash
#
# Build Glance.app (Release) + đóng gói thành Glance-<version>.dmg trong ./dist
#
# Yêu cầu: Xcode + xcodegen + hdiutil (built-in)
# Không cần Apple Developer account — ad-hoc codesign.
#
# Usage:  ./scripts/release.sh

set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT="Glance.xcodeproj"
SCHEME="Glance"
CONFIG="Release"
DIST_DIR="dist"
BUILD_DIR="build"
VERSION=$(grep -E "MARKETING_VERSION" project.yml | head -1 | sed -E 's/.*"(.+)".*/\1/')

echo "→ Generating Xcode project…"
xcodegen generate

echo "→ Cleaning previous build…"
rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$DIST_DIR"

echo "→ Building Release configuration…"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -destination 'platform=macOS' \
  -derivedDataPath "$BUILD_DIR" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGN_STYLE=Manual \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  build 2>&1 | tail -50

APP_PATH="$BUILD_DIR/Build/Products/$CONFIG/$SCHEME.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "✗ Build output not found at $APP_PATH"
  exit 1
fi
echo "✓ Built $APP_PATH"

# Ad-hoc codesign tất cả nested executables (đảm bảo SwiftUI/dylibs cũng signed)
echo "→ Ad-hoc codesigning…"
codesign --force --deep --sign - --options runtime "$APP_PATH" 2>&1 | tail -5 || true
codesign -dvv "$APP_PATH" 2>&1 | head -8

# Tạo DMG
DMG_NAME="Glance-$VERSION.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"
STAGE_DIR=$(mktemp -d)
cp -R "$APP_PATH" "$STAGE_DIR/"
ln -s /Applications "$STAGE_DIR/Applications"

echo "→ Tạo ${DMG_NAME}..."
hdiutil create \
  -volname "Glance" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

rm -rf "$STAGE_DIR"

# Cũng nén zip làm fallback
ZIP_PATH="$DIST_DIR/Glance-$VERSION.zip"
(cd "$BUILD_DIR/Build/Products/$CONFIG" && zip -qry "../../../../$ZIP_PATH" "$SCHEME.app")

SIZE_DMG=$(du -h "$DMG_PATH" | cut -f1)
SIZE_ZIP=$(du -h "$ZIP_PATH" | cut -f1)

echo
echo "════════════════════════════════════════════════════"
echo "  ✓ Build xong Glance $VERSION"
echo "    $DMG_PATH  ($SIZE_DMG)"
echo "    $ZIP_PATH  ($SIZE_ZIP)"
echo "════════════════════════════════════════════════════"
echo
echo "Send file kèm INSTALL.md để user biết cách bypass Gatekeeper."
