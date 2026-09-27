# Inline Translate · 就地翻译

A [PopClip](https://www.popclip.app/)-format extension for
[Omapop](https://github.com/jondkinney/omapop) (the PopClip for
[Omarchy](https://omarchy.org/)) that translates the selected text **in place**:
the result appears in a small popup right next to the selection bar. No browser
tab, no API key.

一个 Omapop（Omarchy 的 PopClip）扩展：**划词后就地弹窗显示译文**，不打开网页、不需要 API key。

```
┌─────────────────────────────────────────┐
│ The quick brown fox jumps over the dog. │   ← select this
└─────────────────────────────────────────┘
        ┌──────────────────────┐
        │ ⇄ 简体中文 · bing     │
        │                      │
        │ 敏捷的棕色狐狸跳过狗。 │   ← popup result
        └──────────────────────┘
```

## Features / 特性

- **In-place popup** via PopClip's `show-result` — nothing opens, nothing steals focus
- **Smart direction**: `auto` target translates Chinese → English, everything else → Simplified Chinese (flip it by picking a fixed language)
- **China-friendly**: defaults to the **Bing** engine (reachable from mainland China), falls back to Google
- **No account, no API key** — plain [translate-shell](https://github.com/soimort/translate-shell)
- 11 target languages, selectable engine
- Also works on macOS PopClip itself (same extension format)

## Requirements / 依赖

| Dependency | Install |
|---|---|
| translate-shell | Arch/Omarchy: `sudo pacman -S translate-shell` · macOS: `brew install translate-shell` · Debian: `sudo apt install translate-shell` |
| bash, python3, coreutils (`timeout`) | already on Omarchy / macOS |

## Install (Omapop) / 安装

### Option A — snippet install (no git)

Open this file in your browser:
[`InlineTranslate.popcliptxt`](InlineTranslate.popcliptxt), select its **whole
content**, and Omapop's bar will offer **Install Extension “Inline Translate”**.
Confirm, then enable it from the bar icon → installed extensions.

### Option B — clone

```bash
git clone https://github.com/xvusrmqj/omapop-inline-translate.git
cp -r omapop-inline-translate/InlineTranslate.popclipext ~/.config/omapop/extensions/
```

Then click the Omapop bar icon → enable **Inline Translate**.

### Install on macOS PopClip

Double-click `InlineTranslate.popclipext` after unzipping, or select the
snippet text above and use PopClip's “Install Extension”.

## Options / 选项

Open the Omapop bar icon → gear next to Inline Translate:

| Option | Default | Values |
|---|---|---|
| Translate into | `auto` | auto, zh-Hans, zh-Hant, en, ja, ko, de, fr, es, ru, pt |
| Engine | `auto` | auto (bing→google), bing, google |

## How it works / 原理

A plain shell script (`translate.sh`) runs [translate-shell](https://github.com/soimort/translate-shell)
with the selection passed in `POPCLIP_TEXT`, detects CJK to pick the direction,
tries Bing then Google, and prints the result for `show-result`. Selections are
capped at 4000 chars; each engine call has a 30 s timeout.

## License

MIT — see [LICENSE](LICENSE).
