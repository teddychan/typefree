#!/bin/bash
# Build the install bundle used for local installation.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$SCRIPT_DIR/dist/Handfree Install.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
FRAMEWORKS="$CONTENTS/Frameworks"
PROJECT_PATH="$SCRIPT_DIR/VoicePolish.xcodeproj"
SCHEME="VoicePolish"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-/tmp/VoicePolishDerived}"

# 本机私有构建参数（不进仓库）：试用服务器地址/证书指纹、签名身份。见 local.build.env.example。
# 没有这个文件也能编译——只是编出来的版本没有试用通道（开源自编译版就是这样）。
if [ -f "$SCRIPT_DIR/local.build.env" ]; then
    # shellcheck disable=SC1091
    . "$SCRIPT_DIR/local.build.env"
fi
VP_TRIAL_API_BASE="${VP_TRIAL_API_BASE:-}"
VP_TRIAL_CERT_SHA256="${VP_TRIAL_CERT_SHA256:-}"
SIGNING_NOTE="Note: local builds are ad hoc signed; distribution still needs Developer ID signing and notarization."

print_summary() {
    local app_size
    app_size="$(du -sh "$APP_DIR" | cut -f1)"
    echo ""
    echo "✅ Handfree install bundle built successfully ($app_size)"
    echo "   Location: $APP_DIR"
    echo "   $SIGNING_NOTE"
    echo ""
    echo "To install:"
    echo "   bash \"$SCRIPT_DIR/scripts/install_app.sh\""
}

copy_xcode_build_to_dist() {
    local built_app="$1"

    codesign --verify --deep --strict "$built_app"

    rm -rf "$APP_DIR"
    mkdir -p "$(dirname "$APP_DIR")"
    ditto "$built_app" "$APP_DIR"
    xattr -cr "$APP_DIR" 2>/dev/null || true
    xattr -d com.apple.FinderInfo "$APP_DIR" 2>/dev/null || true
    xattr -d "com.apple.fileprovider.fpfs#P" "$APP_DIR" 2>/dev/null || true

    if ! codesign --verify --deep --strict "$APP_DIR"; then
        echo "⚠️  Exported app picked up workspace metadata after copy; source app signature was verified before export."
    fi
}

# 本地构建也用 Developer ID 重签（与正式发版同一身份）：
# macOS 把麦克风/辅助功能授权绑在「bundle ID + 签名身份」上，
# 测试版与正式版签名一致，来回安装才不会反复要求重新授权。
DEVELOPER_ID_IDENTITY="${DEVELOPER_ID_IDENTITY:-}"
# RELEASE_BUILD=1（scripts/release.sh 设置）：签名加 --timestamp 以便公证，且必须用 Developer ID。
RELEASE_BUILD="${RELEASE_BUILD:-0}"

developer_id_available() {
    [ -n "$DEVELOPER_ID_IDENTITY" ] || return 1
    security find-identity -v -p codesigning 2>/dev/null | grep -q "$DEVELOPER_ID_IDENTITY"
}

resign_with_developer_id() {
    local app="$1"
    local entitlements="$SCRIPT_DIR/Resources/VoicePolish.entitlements"
    # 与 release_dmg.sh 同序：先签 Sparkle 嵌套组件（由内到外），最后签 app 本体。
    # 本地构建不加 --timestamp（无需公证，离线也能签）；发版构建必须加。
    local sign=(codesign --force --options runtime --sign "$DEVELOPER_ID_IDENTITY")
    [ "$RELEASE_BUILD" = "1" ] && sign+=(--timestamp)
    local sp_v="$app/Contents/Frameworks/Sparkle.framework/Versions/B"
    if [ -d "$sp_v" ]; then
        for xpc in "$sp_v/XPCServices/"*.xpc; do
            [ -e "$xpc" ] && "${sign[@]}" "$xpc"
        done
        [ -e "$sp_v/Autoupdate" ]  && "${sign[@]}" "$sp_v/Autoupdate"
        [ -e "$sp_v/Updater.app" ] && "${sign[@]}" "$sp_v/Updater.app"
        "${sign[@]}" "$app/Contents/Frameworks/Sparkle.framework"
    fi
    "${sign[@]}" --entitlements "$entitlements" "$app"
    codesign --verify --strict "$app"
}

# Sparkle 比较的是 CFBundleVersion：每次构建写入 git 提交数，保证单调递增；
# 同时写入 fork 版号（mac/CUSTOM_BUILD），关于页显示「<上游版本>-custom-<N>」。
stamp_bundle() {
    local plist="$1/Contents/Info.plist"
    local pb=/usr/libexec/PlistBuddy
    local build_number custom_build
    build_number="$(git -C "$SCRIPT_DIR" rev-list --count HEAD 2>/dev/null || echo 1)"
    custom_build="$(tr -d '[:space:]' < "$SCRIPT_DIR/CUSTOM_BUILD")"
    "$pb" -c "Set :CFBundleVersion $build_number" "$plist"
    "$pb" -c "Set :TypefreeCustomBuild $custom_build" "$plist" 2>/dev/null \
        || "$pb" -c "Add :TypefreeCustomBuild string $custom_build" "$plist"

    # GPL-3.0 与 Sparkle（MIT/BSD）要求二进制分发附带许可与版权声明
    local legal="$1/Contents/Resources/Licenses"
    mkdir -p "$legal"
    cp "$SCRIPT_DIR/LICENSE" "$legal/LICENSE.txt"
    cp "$SCRIPT_DIR/../NOTICE" "$legal/NOTICE.txt"
    cp "$SCRIPT_DIR/THIRD_PARTY_LICENSES/"*.txt "$legal/"
}

xcode_signing_ready() {
    [ -d "/Applications/Xcode.app" ] || return 1
    [ -d "$PROJECT_PATH" ] || return 1

    local settings
    settings="$(xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" -showBuildSettings 2>/dev/null)" || return 1

    local team
    local identity
    team="$(printf '%s\n' "$settings" | awk -F' = ' '/DEVELOPMENT_TEAM = / { print $2; exit }')"
    identity="$(printf '%s\n' "$settings" | awk -F' = ' '/CODE_SIGN_IDENTITY = / { print $2; exit }')"

    [ -n "$team" ] || return 1
    [ "$team" != "\"\"" ] || return 1
    [ -n "$identity" ] || return 1
    [ "$identity" != "-" ] || return 1
}

build_with_xcode() {
    echo "🔨 Building Handfree with Xcode-managed signing..."

    xcodebuild \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -configuration Release \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        ARCHS=arm64 \
        ONLY_ACTIVE_ARCH=YES \
        VP_TRIAL_API_BASE="$VP_TRIAL_API_BASE" \
        VP_TRIAL_CERT_SHA256="$VP_TRIAL_CERT_SHA256" \
        build
    local xcode_exit=$?
    if [ $xcode_exit -ne 0 ]; then
        echo "❌ xcodebuild failed with exit code $xcode_exit"
        return 1
    fi

    local built_app="$DERIVED_DATA_PATH/Build/Products/Release/Handfree.app"
    if [ ! -d "$built_app" ]; then
        echo "❌ Xcode build completed without producing $built_app"
        return 1
    fi

    stamp_bundle "$built_app"

    if developer_id_available; then
        echo "🔏 Re-signing with Developer ID (same identity as official releases)..."
        resign_with_developer_id "$built_app"
        SIGNING_NOTE="Note: signed with Developer ID（与正式版同签名，覆盖安装不会重新要权限）."
        echo "✅ Signed with Developer ID identity"
    elif [ "$RELEASE_BUILD" = "1" ]; then
        echo "❌ RELEASE_BUILD=1 needs a Developer ID Application identity (DEVELOPER_ID_IDENTITY=\"$DEVELOPER_ID_IDENTITY\")."
        return 1
    else
        local signing_line
        signing_line="$(codesign -dv --verbose=2 "$built_app" 2>&1 | awk -F= '/^Authority=Apple Development:/ { print $2; exit }')"
        # stamp_bundle 改了 Info.plist、加了许可文件，外层要用同一身份重签
        codesign --force --options runtime \
            --entitlements "$SCRIPT_DIR/Resources/VoicePolish.entitlements" \
            --sign "${signing_line:--}" "$built_app"
        SIGNING_NOTE="Note: build uses Xcode-managed signing (${signing_line:-Apple Development})."
        echo "✅ Signed with Xcode-managed Apple Development identity (Developer ID cert not found)"
    fi

    copy_xcode_build_to_dist "$built_app"
}

build_manually() {
    echo "❌ Manual swiftc fallback has been removed."
    echo "   The macOS build now relies on the Xcode project + VoicePolishCore Swift Package."
    echo "   Install Xcode (or run on a machine that has it) and re-run this script."
    exit 1
}

if [ "${FORCE_MANUAL_BUILD:-0}" != "1" ] && xcode_signing_ready; then
    if build_with_xcode; then
        print_summary
        exit 0
    fi
    echo "⚠️  Xcode-managed build failed; falling back to manual build."
    # 清理可能残留的旧产物，避免误安装旧版
    rm -rf "$DERIVED_DATA_PATH"
fi

build_manually
print_summary
