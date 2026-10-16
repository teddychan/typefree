# Handfree

**AI voice input for macOS: hold, talk, release — the text is cleaned up and typed at your cursor.**

Handfree is a modified version of [Typefree](https://github.com/kdsz001/typefree) by Rui Wang (kdsz001),
released under the same [GNU GPL-3.0](mac/LICENSE). It is not affiliated with or endorsed by Typefree.
What changed is listed in [NOTICE](NOTICE).

## What it does

In any app's text field, hold a hotkey or the mouse button and talk. When you let go, the transcript goes
through an LLM that strips filler words, fixes the sentence, adds punctuation and paragraphs, and types the
result at your cursor. You can also hold on empty space to ask AI a question, end a sentence with a language
command to translate it, and teach it your vocabulary. History is stored encrypted on your Mac.

## Bring your own key

Handfree has no hosted service, trial or membership. Paste your own API key under Settings → Models
(Volcengine / Qwen, or OpenAI, Gemini, Claude, or any OpenAI-compatible gateway). Audio and text go straight
to the provider you choose; keys stay in the macOS Keychain.

## Build from source

Requires macOS 14+ and Xcode 26.3.

```bash
cd mac
./build.sh                      # output in dist/Handfree Install.app
bash scripts/install_app.sh     # installs to /Applications/Handfree.app
bash scripts/run-debug.sh       # "Handfree Debug", runs beside the installed copy
```

Core library tests: `cd mac/VoicePolishCore && swift test`. More in [mac/README.md](mac/README.md).

## Repository layout

- `mac/` — the macOS app (Swift, GPL-3.0)
- `docs/handfree/appcast.xml` — Handfree's Sparkle update feed
- `docs/` (everything else), `readme-assets/` — upstream Typefree's website and media, left untouched
  only so upstream merges stay clean. They are not part of Handfree, not shipped in it, and not covered
  by the GPL.

## License

GPL-3.0 — see [mac/LICENSE](mac/LICENSE) and [NOTICE](NOTICE). The source for every Handfree release is
the matching tag in this repository.

---

## 中文

Handfree 是基于 [Typefree](https://github.com/kdsz001/typefree)（Rui Wang / kdsz001）修改的 macOS
AI 语音输入工具，同样以 GPL-3.0 开源，与 Typefree 无关联。没有托管服务、试用或会员：在「设置 → 模型」
填入你自己的 API Key 即可使用，音频与文字直接发给你选的模型厂商。构建方法见上文。
