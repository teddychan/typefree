#!/usr/bin/env bash
# Build and launch a local "Typefree Debug" build that can sit beside an official Typefree:
# own bundle id (com.voicepolish.app.debug), own name, Debug channel label, updates off.
# The identity comes from the Debug build configuration; this script builds, stamps, signs, launches.
set -euo pipefail

SCHEME="VoicePolish"
CONFIG="Debug"
RELEASE_ID="com.voicepolish.app"
DEBUG_ID="$RELEASE_ID.debug"
DEBUG_NAME="Typefree Debug"

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA_PATH="$PWD/DerivedData"   # one bundle per checkout (gitignored)

[[ "$DEBUG_NAME" == *" Debug" && "$DEBUG_ID" == "$RELEASE_ID.debug" ]] \
  || { echo "error: refusing to build or clean a non-Debug identity" >&2; exit 1; }

echo "==> Building $SCHEME ($CONFIG)…"
# Signing happens below with your own identity: the project's team is the upstream author's.
xcodebuild -project VoicePolish.xcodeproj -scheme "$SCHEME" -configuration "$CONFIG" \
  -destination 'platform=macOS,arch=arm64' -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=NO build -quiet

app="$DERIVED_DATA_PATH/Build/Products/$CONFIG/$DEBUG_NAME.app"
plist="$app/Contents/Info.plist"
pb=/usr/libexec/PlistBuddy
[[ -d "$app" ]] || { echo "error: not found: $app" >&2; exit 1; }

built_id="$("$pb" -c "Print :CFBundleIdentifier" "$plist")"
if [[ "$built_id" != "$DEBUG_ID" ]]; then
  echo "error: built app has bundle id '$built_id', expected '$DEBUG_ID'." >&2
  exit 1
fi

echo "==> Stopping any running debug build…"
pkill -f "$app/Contents/MacOS/" 2>/dev/null || true
sleep 1

build_number="$(git rev-list --count HEAD 2>/dev/null || echo 1)"
commit="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
"$pb" -c "Set :CFBundleVersion $build_number" "$plist"

short_version="$("$pb" -c "Print :CFBundleShortVersionString" "$plist")"
[[ "$short_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  echo "error: version must be numeric X.Y.Z, got: $short_version" >&2
  exit 1
}
"$pb" -c "Set :TypefreeBuildChannel Debug" "$plist" 2>/dev/null \
  || "$pb" -c "Add :TypefreeBuildChannel string Debug" "$plist"

# Fork build counter (mac/CUSTOM_BUILD): bumped by one for every custom release, never reset.
# Shown in About as "<upstream version>-custom-<N>"; the git tag is v<upstream version>-custom-<N>.
custom_build="$(tr -d '[:space:]' < CUSTOM_BUILD)"
[[ "$custom_build" =~ ^[1-9][0-9]*$ ]] || {
  echo "error: mac/CUSTOM_BUILD must hold a positive integer, got: '$custom_build'" >&2
  exit 1
}
"$pb" -c "Set :TypefreeCustomBuild $custom_build" "$plist" 2>/dev/null \
  || "$pb" -c "Add :TypefreeCustomBuild string $custom_build" "$plist"
# Never let Sparkle replace this build with the official release, automatically or via "检查更新…".
"$pb" -c "Set :SUEnableAutomaticChecks false" "$plist"
"$pb" -c "Set :SUAutomaticallyUpdate false" "$plist"
"$pb" -c "Delete :SUFeedURL" "$plist" 2>/dev/null || true

# A stable identity keeps macOS's Microphone / Accessibility grants across rebuilds;
# ad hoc ("-") works too, but macOS asks again after every build.
identity="${TYPEFREE_DEBUG_SIGN_IDENTITY:-$(security find-identity -v -p codesigning 2>/dev/null \
  | awk -F'"' '/Apple Development:/ { print $2; exit }')}"
identity="${identity:--}"
echo "==> Signing as: $([[ "$identity" == "-" ]] && echo "ad hoc" || echo "$identity")"
codesign --force --deep --sign "$identity" "$app" >/dev/null
codesign --force --sign "$identity" --entitlements Resources/VoicePolish.entitlements "$app"
codesign --verify --deep --strict "$app"

echo "==> Launching $app"
open -n "$app"

cat <<EOF

Launched "$DEBUG_NAME" v$short_version-custom-$custom_build Debug (build $build_number, $commit)
  id:   $DEBUG_ID
  path: $app

- Grant Microphone / Accessibility to "$DEBUG_NAME" separately from any installed Typefree.
EOF
