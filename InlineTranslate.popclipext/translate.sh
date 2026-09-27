#!/usr/bin/env bash
# Inline Translate — omapop / PopClip shell-script extension
# Reads the selection from POPCLIP_TEXT, translates it with translate-shell
# and prints the result for PopClip's "show-result" popup.
set -u

text="${POPCLIP_TEXT:-}"
target="${POPCLIP_OPTION_TARGET:-auto}"
engine="${POPCLIP_OPTION_ENGINE:-auto}"

fail() { printf '%s\n' "$1"; exit 0; }

command -v trans >/dev/null 2>&1 ||
  fail "translate-shell is not installed.
Arch/Omarchy:  sudo pacman -S translate-shell
macOS (brew):  brew install translate-shell
Debian/Ubuntu: sudo apt install translate-shell"

# Guard against absurdly long selections (keep it under ~1000 chars).
text=$(printf '%s' "$text" | head -c 4000)

# "auto" target: Chinese in -> English out, anything else -> Simplified Chinese.
if [[ "$target" == "auto" ]]; then
  if printf '%s' "$text" | python3 -c '
import sys
cjk = any("\u3400" <= ch <= "\u9fff" or "\uf900" <= ch <= "\ufaff" for ch in sys.stdin.read())
sys.exit(0 if cjk else 1)
  '; then
    target="en"
  else
    target="zh-Hans"
  fi
fi

# One engine, or a fallback chain for "auto".
if [[ "$engine" == "auto" ]]; then
  engines=(bing google)
else
  engines=("$engine")
fi

for e in "${engines[@]}"; do
  out=$(timeout 30 trans -no-ansi -b -e "$e" -t "$target" -- "$text" 2>/dev/null)
  if [[ -n "${out// }" ]]; then
    arrow="$target"
    [[ "$arrow" == "zh-Hans" ]] && arrow="简体中文"
    [[ "$arrow" == "zh-Hant" ]] && arrow="繁體中文"
    printf '⇄ %s · %s\n\n%s\n' "$arrow" "$e" "$out"
    exit 0
  fi
done

fail "Translation failed (engine(s): ${engines[*]}). Check your network or try another engine in the extension options."
