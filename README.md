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
        ┌──────────────────────────────┐
        │ ⇄ 简体中文 · qwen3.5:0.8b     │
        │                              │
        │ 敏捷的棕色狐狸跳过狗。         │   ← popup result
        └──────────────────────────────┘
```

## Features / 特性

- **In-place popup** via PopClip's `show-result` — nothing opens, nothing steals focus
- **Local AI first**: if [Ollama](https://ollama.com) is running, translation happens fully **offline** on your machine (sub-second with a small model like `qwen3.5:0.8b`, `think:false` so reasoning models answer directly)
- **Smart direction**: `auto` target translates Chinese → English, everything else → Simplified Chinese (or pick a fixed language)
- **Fallback chain**: `auto` engine = Ollama → Bing → Google, so it keeps working offline *and* behind the Great Firewall (Bing is reachable from mainland China)
- **No account, no API key** — plain Ollama + [translate-shell](https://github.com/soimort/translate-shell)
- Runs under Omapop's hardened child-process environment (`shell mode: none`, minimal PATH, no proxy vars — local Ollama doesn't care)
- Also works on macOS PopClip itself (same extension format)

## Requirements / 依赖

Pick **one** (or both for fallback):

| Dependency | Install | Used by |
|---|---|---|
| [Ollama](https://ollama.com) + any chat model | `sudo pacman -S ollama` then `ollama pull qwen3.5:0.8b` | default engine, offline |
| translate-shell | Arch: `sudo pacman -S translate-shell` · macOS: `brew install translate-shell` | Bing/Google engines |

bash, curl, jq, python3, coreutils are expected (already on Omarchy).

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
| Engine | `auto` | auto (ollama→bing→google), ollama, bing, google |
| Ollama model | `qwen3.5:0.8b` | any local `ollama list` name, e.g. `qwen3:4b` |

**Tip / 提示**: a 0.8B model is fast but rough on idioms. For hard passages
set Engine to `bing` (or let `auto` fall through when Ollama is off).

## How it works / 原理

A plain shell script (`translate.sh`) runs under the selection's popup: it
detects CJK to pick the direction, then tries engines in order —

1. **Ollama** at `127.0.0.1:11434` via `/api/chat` with `think:false`,
   `temperature 0`, `num_predict 800`, bypassing any system proxy
   (`--noproxy '*'`)
2. **Bing** via `trans -e bing` (reachable in mainland China)
3. **Google** via `trans -e google`

— and prints the winner for `show-result`. Selections are capped at 4000 chars;
per-engine timeouts (Ollama 75 s, trans 30 s) stay inside Omapop's 120 s child
deadline.

## Troubleshooting / 排错

- **Spinner then nothing** — usually means the script died early: check that
  `ollama ps` shows your model (Ollama running) or that `trans` is installed.
- **Reasoning model returns empty text** — this extension sends `think:false`;
  if you use a model that ignores it, switch to Bing.
- **Network engines hang behind a proxy** — Omapop strips proxy variables from
  child processes on purpose; the local Ollama engine is immune to this.

## License

MIT — see [LICENSE](LICENSE).
