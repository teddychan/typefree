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
no hosted trial server. Every build stamps `CFBundleVersion` with the git commit count (Sparkle compares it),
writes the fork build counter from `CUSTOM_BUILD`, and copies `LICENSE`, `NOTICE` and
`THIRD_PARTY_LICENSES/` into `Contents/Resources/Licenses`.

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

## Layout

- `Sources/` — the menu-bar app (AppKit + SwiftUI)
- `VoicePolishCore/` — core library (recording, speech recognition, AI cleanup, vocabulary, encrypted history)
- `Resources/` — icon, entitlements, What's New page
- `build.sh`, `scripts/` — build, install, debug build

Internal type and module names (`VoicePolish*`, `Typefree*`) are kept as upstream has them so merges from
upstream stay small; they never appear in the UI.
