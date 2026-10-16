# Handfree — macOS source

The complete macOS app, GPL-3.0 ([LICENSE](LICENSE)). Handfree is a modified version of
[Typefree](https://github.com/kdsz001/typefree); see [NOTICE](../NOTICE) for what changed.

## Build

Requires macOS 14.0+ and Xcode 26.3 (Swift 6).

```bash
cd mac
./build.sh                       # dist/Handfree Install.app
bash scripts/install_app.sh      # installs to /Applications/Handfree.app
bash scripts/run-debug.sh        # "Handfree Debug" (com.dragonapp.handfree.macos.debug), updates off
cd VoicePolishCore && swift test # core library tests
```

Or open `VoicePolish.xcodeproj`, scheme `VoicePolish`.

`build.sh` reads optional private settings from `local.build.env` (see `local.build.env.example`). Set
`DEVELOPER_ID_IDENTITY` there to sign with your Developer ID; leave the trial variables empty — Handfree has
no hosted trial server. Every build stamps `CFBundleVersion` with the git commit count (Sparkle compares it)
and writes the same number into `TypefreeCustomBuild`, so About shows `<upstream>-custom-<build number>`. It
also copies `LICENSE`, `NOTICE` and `THIRD_PARTY_LICENSES/` into `Contents/Resources/Licenses`.

## Identity

| | Release | Debug |
|---|---|---|
| Name | Handfree | Handfree Debug |
| Bundle id | `com.dragonapp.handfree.macos` | `com.dragonapp.handfree.macos.debug` |
| Team | `4AF3KGGV29` | signed locally by `run-debug.sh` |

Data lives in `~/.config/handfree/` (fallback `~/Library/Application Support/Handfree/`), secrets in the
Keychain under service `com.dragonapp.handfree.secret`, shared defaults in `group.com.dragonapp.handfree.shared`,
and the log in `~/Library/Logs/Handfree.log` — none of it is shared with an installed Typefree.

## Updates

Sparkle reads `https://raw.githubusercontent.com/teddychan/typefree/main/docs/handfree/appcast.xml`
([docs/handfree/appcast.xml](../docs/handfree/appcast.xml)), signed with the shared Dragon EdDSA key.

## Release

```bash
cd mac
bash scripts/release.sh            # dry run: build, notarize, package, write the appcast item locally
bash scripts/release.sh --publish  # also push the tag and create the GitHub Release
```

The script runs `build.sh` with `RELEASE_BUILD=1` (Developer ID signing with `--timestamp` and hardened
runtime, nested Sparkle components first). It then notarizes and staples the app, and builds the two
artifacts in `dist/release/<version>/`:

- `Handfree-<version>.zip` — the Sparkle update
- `Handfree-<version>.pkg` — the notarized installer for people, which installs to `/Applications`

It signs the zip with Sparkle's `sign_update` and adds an `<item>` at the top of
`docs/handfree/appcast.xml`. A re-run replaces the item for the same build number.

- **Version:** `<CFBundleShortVersionString>-custom-<build number>` (e.g. `3.0.13-custom-112`), tag `v<version>`.
  The build number is the git commit count, the same as `CFBundleVersion` and `sparkle:version`.
- **Needs:** the `Developer ID Application` and `Developer ID Installer` certificates for team `4AF3KGGV29`
  in the keychain (override with `DEVELOPER_ID_IDENTITY` / `INSTALLER_IDENTITY`), and the Sparkle EdDSA
  private key in the login keychain. It also needs a notarytool API key, read from
  `~/.claude/skills/update-macos-appstore/config.sh` or from `NOTARY_KEY_ID`, `NOTARY_ISSUER` and
  `NOTARY_KEY_P8`.
- **Publishing:** commit what you want to ship. Then run
  `git tag v<version>` on that commit and `bash scripts/release.sh --publish` from a clean tree. That pushes
  the tag and creates the GitHub Release with the zip, the pkg, `LICENSE.txt` and `NOTICE.txt`, which
  GPL-3.0 requires us to ship. Last, commit the updated `docs/handfree/appcast.xml` and merge it to `main`;
  the feed only goes live once the item is on `main`.
- **Arm64 only:** `build.sh` builds for arm64 only, so the item carries
  `sparkle:hardwareRequirements arm64`.

## Layout

- `Sources/` — the menu-bar app (AppKit + SwiftUI)
- `VoicePolishCore/` — core library (recording, speech recognition, AI cleanup, vocabulary, encrypted history)
- `Resources/` — icon, entitlements, What's New page
- `build.sh`, `scripts/` — build, install, debug build, release

Internal type and module names (`VoicePolish*`, `Typefree*`) are kept as upstream has them so merges from
upstream stay small; they never appear in the UI.
