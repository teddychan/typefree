#!/usr/bin/env bash
# List Chinese UI strings with no translation (fork: UI display language), e.g. after pulling upstream.
# Writes them as table lines to fill in (source<TAB><TAB><TAB># file:line) and prints them.
# Add each to VoicePolishCore/Sources/VoicePolishCore/UILocalization/UITranslations+*.swift,
# or to Tests/VoicePolishCoreTests/UILocalizationIgnoreList.swift when it is not UI text.
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/VoicePolishCore"
out="${1:-$PWD/.build/untranslated.tsv}"
mkdir -p "$(dirname "$out")"
: > "$out"
UI_L10N_DUMP="$out" swift test --filter UILocalizationCoverageTests >/dev/null 2>&1 || true
if [[ -s "$out" ]]; then
  cat "$out"
  echo "==> $(wc -l < "$out" | tr -d ' ') untranslated string(s), written to $out" >&2
  exit 1
fi
echo "==> every Chinese UI string has a translation" >&2
