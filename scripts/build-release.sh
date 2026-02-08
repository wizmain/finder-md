#!/usr/bin/env bash
#
# build-release.sh — FinderMD Release Builder
#
# Builds the FinderMD app and packages it into a DMG installer.
#
# Usage:
#   ./scripts/build-release.sh              # unsigned build
#   ./scripts/build-release.sh --sign       # Developer ID signed build
#   ./scripts/build-release.sh --sign --notarize  # signed + Apple notarization
#

set -euo pipefail

# ─── Configuration ────────────────────────────────────────────────────────────

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
XCODE_PROJECT="$PROJECT_DIR/agent-claude-code/FinderMD.xcodeproj"
SCHEME="FinderMD"
CONFIGURATION="Release"

BUILD_DIR="$PROJECT_DIR/build/release"
ARCHIVE_PATH="$BUILD_DIR/FinderMD.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
APP_NAME="FinderMD.app"
EXPORT_OPTIONS="$PROJECT_DIR/scripts/ExportOptions.plist"

SIGN=false
NOTARIZE=false

# ─── Parse arguments ─────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
    case "$1" in
        --sign)
            SIGN=true
            shift
            ;;
        --notarize)
            NOTARIZE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--sign] [--notarize]"
            echo ""
            echo "  --sign       Code-sign with Developer ID"
            echo "  --notarize   Submit to Apple notarization (implies --sign)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [[ "$NOTARIZE" == true ]]; then
    SIGN=true
fi

# ─── Helpers ──────────────────────────────────────────────────────────────────

info()  { echo "▸ $*"; }
error() { echo "✖ $*" >&2; exit 1; }

# ─── Preflight checks ────────────────────────────────────────────────────────

command -v xcodebuild >/dev/null 2>&1 || error "xcodebuild not found. Install Xcode."
command -v hdiutil    >/dev/null 2>&1 || error "hdiutil not found."

[[ -d "$XCODE_PROJECT" ]] || error "Xcode project not found at $XCODE_PROJECT"

# ─── Extract version from project ────────────────────────────────────────────

APP_VERSION=$(xcodebuild -project "$XCODE_PROJECT" \
    -scheme "$SCHEME" \
    -showBuildSettings 2>/dev/null \
    | grep 'MARKETING_VERSION' \
    | head -1 \
    | sed 's/.*= //')

APP_VERSION="${APP_VERSION:-1.0.0}"
DMG_NAME="FinderMD-${APP_VERSION}.dmg"

info "Building FinderMD v${APP_VERSION}"
info "Sign: $SIGN | Notarize: $NOTARIZE"

# ─── Clean previous build ────────────────────────────────────────────────────

info "Cleaning previous build artifacts..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# ─── Step 1: Archive ─────────────────────────────────────────────────────────

info "Archiving (this may take a while)..."

ARCHIVE_ARGS=(
    -project "$XCODE_PROJECT"
    -scheme "$SCHEME"
    -configuration "$CONFIGURATION"
    -archivePath "$ARCHIVE_PATH"
    archive
)

if [[ "$SIGN" == false ]]; then
    ARCHIVE_ARGS+=(
        CODE_SIGN_IDENTITY="-"
        CODE_SIGNING_REQUIRED=NO
        CODE_SIGNING_ALLOWED=NO
    )
fi

xcodebuild "${ARCHIVE_ARGS[@]}" | tail -5

[[ -d "$ARCHIVE_PATH" ]] || error "Archive failed — $ARCHIVE_PATH not found"
info "Archive created: $ARCHIVE_PATH"

# ─── Step 2: Export app ──────────────────────────────────────────────────────

if [[ "$SIGN" == true ]]; then
    info "Exporting signed app..."
    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_DIR" \
        -exportOptionsPlist "$EXPORT_OPTIONS" \
        | tail -5

    APP_PATH="$EXPORT_DIR/$APP_NAME"
else
    info "Extracting app from archive (unsigned)..."
    APP_PATH="$BUILD_DIR/$APP_NAME"
    cp -R "$ARCHIVE_PATH/Products/Applications/$APP_NAME" "$APP_PATH"
fi

[[ -d "$APP_PATH" ]] || error "Export failed — $APP_NAME not found"
info "App exported: $APP_PATH"

# ─── Step 3: (Optional) Notarize ─────────────────────────────────────────────

if [[ "$NOTARIZE" == true ]]; then
    info "Submitting for notarization..."

    # Create a zip for notarization submission
    NOTARIZE_ZIP="$BUILD_DIR/FinderMD-notarize.zip"
    ditto -c -k --keepParent "$APP_PATH" "$NOTARIZE_ZIP"

    xcrun notarytool submit "$NOTARIZE_ZIP" \
        --keychain-profile "FinderMD" \
        --wait

    info "Stapling notarization ticket..."
    xcrun stapler staple "$APP_PATH"

    rm -f "$NOTARIZE_ZIP"
    info "Notarization complete"
fi

# ─── Step 4: Create DMG ──────────────────────────────────────────────────────

info "Creating DMG..."

DMG_STAGING="$BUILD_DIR/dmg-staging"
DMG_PATH="$BUILD_DIR/$DMG_NAME"

mkdir -p "$DMG_STAGING"
cp -R "$APP_PATH" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

hdiutil create \
    -volname "FinderMD" \
    -srcfolder "$DMG_STAGING" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

rm -rf "$DMG_STAGING"

[[ -f "$DMG_PATH" ]] || error "DMG creation failed"

# ─── Done ─────────────────────────────────────────────────────────────────────

DMG_SIZE=$(du -h "$DMG_PATH" | cut -f1)

echo ""
echo "══════════════════════════════════════════════"
echo "  Build complete!"
echo "  App:  $BUILD_DIR/$APP_NAME"
echo "  DMG:  $DMG_PATH ($DMG_SIZE)"
echo "══════════════════════════════════════════════"
