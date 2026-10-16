#!/bin/bash
# Build, notarize and package a Handfree direct-download release.
#
#   bash scripts/release.sh             # dry run: build → sign → notarize → staple → .zip + .pkg
#                                       #          → EdDSA-sign the zip → write the appcast item locally
#   bash scripts/release.sh --publish   # the same, then push the tag and create the GitHub Release
#
# Version comes from the built bundle: tag v<CFBundleShortVersionString>-custom-<build number>,
# where the build number is CFBundleVersion = sparkle:version (git commit count). --publish needs a clean tree with that
# tag on HEAD; the updated docs/handfree/appcast.xml is left for you to commit (the feed reads main).
set -euo pipefail

PUBLISH=0
case "${1:-}" in
    "") ;;
    --publish) PUBLISH=1 ;;
    *) echo "usage: $0 [--publish]" >&2; exit 2 ;;
esac

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAC_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MAC_DIR/.." && pwd)"
APPCAST="$REPO_ROOT/docs/handfree/appcast.xml"
GITHUB_REPO="teddychan/typefree"
TEAM_ID="4AF3KGGV29"
APP_NAME="Handfree"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-/tmp/VoicePolishDerived}"

die() { echo "❌ $*" >&2; exit 1; }

# --- Credentials -------------------------------------------------------------
# Notary API key (+ issuer) live outside the repo; override with NOTARY_KEY_ID/NOTARY_ISSUER/NOTARY_KEY_P8.
NOTARY_CONFIG="${NOTARY_CONFIG:-$HOME/.claude/skills/update-macos-appstore/config.sh}"
if [ -z "${NOTARY_KEY_ID:-}" ] && [ -f "$NOTARY_CONFIG" ]; then
    # shellcheck disable=SC1090
    . "$NOTARY_CONFIG"
fi
NOTARY_KEY_ID="${NOTARY_KEY_ID:-${CM_API_KEY_ID:-}}"
NOTARY_ISSUER="${NOTARY_ISSUER:-${CM_API_ISSUER_ID:-}}"
NOTARY_KEY_P8="${NOTARY_KEY_P8:-${CM_API_KEY_P8:-}}"
[ -n "$NOTARY_KEY_ID" ] && [ -n "$NOTARY_ISSUER" ] && [ -f "$NOTARY_KEY_P8" ] \
    || die "notarytool API key not found (set NOTARY_KEY_ID, NOTARY_ISSUER, NOTARY_KEY_P8)"

find_identity() {
    security find-identity -v ${2:+-p "$2"} 2>/dev/null \
        | sed -n "s/.*\"\($1: .* ($TEAM_ID)\)\"/\1/p" | head -1
}
DEVELOPER_ID_IDENTITY="${DEVELOPER_ID_IDENTITY:-$(find_identity "Developer ID Application" codesigning)}"
INSTALLER_IDENTITY="${INSTALLER_IDENTITY:-$(find_identity "Developer ID Installer")}"
[ -n "$DEVELOPER_ID_IDENTITY" ] || die "no Developer ID Application identity for team $TEAM_ID in the keychain"
[ -n "$INSTALLER_IDENTITY" ] || die "no Developer ID Installer identity for team $TEAM_ID in the keychain"

if [ "$PUBLISH" = "1" ]; then
    [ -z "$(git -C "$REPO_ROOT" status --porcelain)" ] || die "--publish needs a clean working tree"
    command -v gh >/dev/null || die "--publish needs the GitHub CLI (gh)"
    TAG="v$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$MAC_DIR/Info.plist")-custom-$(git -C "$REPO_ROOT" rev-list --count HEAD)"
    [ "$(git -C "$REPO_ROOT" rev-parse -q --verify "refs/tags/$TAG^{commit}")" = "$(git -C "$REPO_ROOT" rev-parse HEAD)" ] \
        || die "tag $TAG must exist and point at HEAD (git tag $TAG)"
fi

# --- Build -------------------------------------------------------------------
echo "🔨 Release build (Developer ID: $DEVELOPER_ID_IDENTITY)"
RELEASE_BUILD=1 DEVELOPER_ID_IDENTITY="$DEVELOPER_ID_IDENTITY" bash "$MAC_DIR/build.sh"

BUILT_APP="$MAC_DIR/dist/$APP_NAME Install.app"
PLIST="$BUILT_APP/Contents/Info.plist"
pb() { /usr/libexec/PlistBuddy -c "Print :$1" "$PLIST"; }
UPSTREAM_VERSION="$(pb CFBundleShortVersionString)"
BUILD_NUMBER="$(pb CFBundleVersion)"
MIN_SYSTEM="$(pb LSMinimumSystemVersion)"
VERSION="$UPSTREAM_VERSION-custom-$(pb TypefreeCustomBuild)"
[ "$PUBLISH" = "0" ] || [ "$TAG" = "v$VERSION" ] || die "built version $VERSION does not match tag $TAG"
TAG="v$VERSION"

OUT="$MAC_DIR/dist/release/$VERSION"
rm -rf "$OUT"
mkdir -p "$OUT/stage"
APP="$OUT/stage/$APP_NAME.app"
ditto "$BUILT_APP" "$APP"

codesign --verify --deep --strict "$APP"
[[ "$(codesign -dvv "$APP" 2>&1)" == *$'\nTimestamp='* ]] || die "app signature has no secure timestamp"
ARCHS="$(lipo -archs "$APP/Contents/MacOS/$(pb CFBundleExecutable)")"

# --- Notarize ----------------------------------------------------------------
notarize() {
    local file="$1" result status id
    echo "📤 Notarizing $(basename "$file")..."
    result="$(xcrun notarytool submit "$file" \
        --key "$NOTARY_KEY_P8" --key-id "$NOTARY_KEY_ID" --issuer "$NOTARY_ISSUER" \
        --wait --timeout 30m --output-format json)"
    status="$(plutil -extract status raw - <<<"$result")"
    id="$(plutil -extract id raw - <<<"$result")"
    if [ "$status" != "Accepted" ]; then
        xcrun notarytool log "$id" --key "$NOTARY_KEY_P8" --key-id "$NOTARY_KEY_ID" --issuer "$NOTARY_ISSUER" || true
        die "notarization of $(basename "$file") ended with status: $status ($id)"
    fi
    echo "✅ Notarized ($id)"
}

ditto -c -k --sequesterRsrc --keepParent "$APP" "$OUT/notarize.zip"
notarize "$OUT/notarize.zip"
rm "$OUT/notarize.zip"
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"
spctl --assess --type execute "$APP"

# --- Artifacts ---------------------------------------------------------------
ZIP="$OUT/$APP_NAME-$VERSION.zip"
PKG="$OUT/$APP_NAME-$VERSION.pkg"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"

# Non-relocatable, so the installer always writes /Applications/Handfree.app instead of
# "upgrading" some other copy it finds by bundle id.
pkgbuild --analyze --root "$OUT/stage" "$OUT/component.plist" >/dev/null
plutil -replace 0.BundleIsRelocatable -bool NO "$OUT/component.plist"
pkgbuild --root "$OUT/stage" --component-plist "$OUT/component.plist" \
    --install-location /Applications --identifier "$(pb CFBundleIdentifier).pkg" \
    --version "$BUILD_NUMBER" "$OUT/component.pkg"
productbuild --package "$OUT/component.pkg" --sign "$INSTALLER_IDENTITY" --timestamp "$PKG"
rm "$OUT/component.pkg" "$OUT/component.plist"
notarize "$PKG"
xcrun stapler staple "$PKG"
xcrun stapler validate "$PKG"
spctl --assess --type install "$PKG"

# GPL-3.0: ship the license and notice next to the binaries.
cp "$MAC_DIR/LICENSE" "$OUT/LICENSE.txt"
cp "$REPO_ROOT/NOTICE" "$OUT/NOTICE.txt"

# --- Appcast -----------------------------------------------------------------
SIGN_UPDATE="$DERIVED_DATA_PATH/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update"
[ -x "$SIGN_UPDATE" ] || die "Sparkle sign_update not found at $SIGN_UPDATE"
# Reads the shared Dragon EdDSA private key from the login keychain.
SIGNATURE_ATTRS="$("$SIGN_UPDATE" "$ZIP")"
case "$SIGNATURE_ATTRS" in *sparkle:edSignature=*length=*) ;; *) die "sign_update failed: $SIGNATURE_ATTRS" ;; esac

HARDWARE=""
[ "$ARCHS" = "arm64" ] && HARDWARE="
      <sparkle:hardwareRequirements>arm64</sparkle:hardwareRequirements>"
ITEM="    <item>
      <title>$APP_NAME $VERSION</title>
      <pubDate>$(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S +0000')</pubDate>
      <link>https://github.com/$GITHUB_REPO/releases/tag/$TAG</link>
      <sparkle:version>$BUILD_NUMBER</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>$MIN_SYSTEM</sparkle:minimumSystemVersion>$HARDWARE
      <enclosure url=\"https://github.com/$GITHUB_REPO/releases/download/$TAG/$(basename "$ZIP")\" type=\"application/octet-stream\" $SIGNATURE_ATTRS/>
    </item>"

# Newest first: drop any earlier item for this build number (a re-run), insert before the first <item>.
python3 -I - "$APPCAST" "$BUILD_NUMBER" "$ITEM" <<'PY'
import re, sys
path, build, item = sys.argv[1:]
xml = open(path, encoding="utf-8").read()
xml = re.sub(r"[ \t]*<item>(?:(?!</item>).)*?<sparkle:version>%s</sparkle:version>.*?</item>\n" % re.escape(build),
             "", xml, flags=re.S)
anchor = xml.find("    <item>")
if anchor < 0:
    anchor = xml.index("  </channel>")
xml = xml[:anchor] + item + "\n" + xml[anchor:]
open(path, "w", encoding="utf-8").write(xml)
PY
xmllint --noout "$APPCAST"
echo "📝 Appcast item for build $BUILD_NUMBER written to $APPCAST"

# --- Publish -----------------------------------------------------------------
if [ "$PUBLISH" = "1" ]; then
    git -C "$REPO_ROOT" push origin "refs/tags/$TAG"
    gh release create "$TAG" --repo "$GITHUB_REPO" --verify-tag \
        --title "$APP_NAME $VERSION" \
        --notes "$APP_NAME $VERSION — based on Typefree $UPSTREAM_VERSION. Notarized; requires macOS $MIN_SYSTEM+ ($ARCHS). Licensed GPL-3.0: see LICENSE.txt and NOTICE.txt; source is this tag." \
        "$ZIP" "$PKG" "$OUT/LICENSE.txt" "$OUT/NOTICE.txt"
    echo "🚀 Published https://github.com/$GITHUB_REPO/releases/tag/$TAG"
    echo "   Next: commit docs/handfree/appcast.xml and merge it to main — Sparkle reads the feed from main."
else
    echo ""
    echo "✅ Dry run complete — nothing pushed or published."
fi
echo "   Version:   $VERSION (build $BUILD_NUMBER, $ARCHS, macOS $MIN_SYSTEM+)"
echo "   Tag:       $TAG"
echo "   Artifacts: $OUT"
