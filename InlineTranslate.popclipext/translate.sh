#!/usr/bin/env bash
# Inline Translate — omapop / PopClip shell-script extension
# Translates POPCLIP_TEXT and prints the result for show-result.
# Engines: local Ollama (default, offline) -> Bing -> Google (translate-shell).
set -u

text="${POPCLIP_TEXT:-}"
target="${POPCLIP_OPTION_TARGET:-auto}"
engine="${POPCLIP_OPTION_ENGINE:-auto}"
model="${POPCLIP_OPTION_MODEL:-qwen3.5:0.8b}"
ollama_url="http://127.0.0.1:11434"

fail() { printf '%s\n' "$1"; exit 0; }

# Guard against absurdly long selections.
text=$(printf '%s' "$text" | head -c 4000)

# "auto" target: Chinese in -> English out, anything else -> Simplified Chinese.
if [[ "$target" == "auto" ]]; then
  if printf '%s' "$text" | /usr/bin/python3 -c '
import sys
cjk = any("\u3400" <= ch <= "\u9fff" or "\uf900" <= ch <= "\ufaff" for ch in sys.stdin.read())
sys.exit(0 if cjk else 1)
  '; then
    target="en"
  else
    target="zh-Hans"
  fi
fi

langname() {
  case "$1" in
    zh-Hans) echo "Simplified Chinese" ;;
    zh-Hant) echo "Traditional Chinese" ;;
    en) echo "English" ;;
    ja) echo "Japanese" ;;
    ko) echo "Korean" ;;
    de) echo "German" ;;
    fr) echo "French" ;;
    es) echo "Spanish" ;;
    ru) echo "Russian" ;;
    pt) echo "Portuguese" ;;
    *) echo "$1" ;;
  esac
}

show() { # $1 = translated text, $2 = engine label
  local arrow="$target"
  [[ "$arrow" == "zh-Hans" ]] && arrow="简体中文"
  [[ "$arrow" == "zh-Hant" ]] && arrow="繁體中文"
  printf '⇄ %s · %s\n\n%s\n' "$arrow" "$2" "$1"
  exit 0
}

ollama_alive() {
  /usr/bin/curl -sf --noproxy '*' --max-time 2 "$ollama_url/api/tags" >/dev/null 2>&1
}

translate_ollama() {
  local out
  out=$(/usr/bin/curl -sf --noproxy '*' --max-time 75 "$ollama_url/api/chat" \
    -d "$(/usr/bin/jq -cn \
        --arg m "$model" \
        --arg p "Translate the text below into $(langname "$target"). Output ONLY the translation — no explanations, no quotes, no notes.

$text" \
        '{model:$m,think:false,messages:[{role:"user",content:$p}],stream:false,
          options:{temperature:0,num_predict:800}}')" 2>/dev/null \
    | /usr/bin/jq -r 'if .error then empty else (.message.content // empty) end' 2>/dev/null)
  [[ -n "${out// }" ]] && { show "$out" "${model} (local)"; }
}

translate_trans() { # $1 = engine name
  command -v trans >/dev/null 2>&1 || return 1
  local out
  out=$(timeout 30 /usr/bin/trans -no-ansi -b -e "$1" -t "$target" -- "$text" 2>/dev/null)
  [[ -n "${out// }" ]] && { show "$out" "$1"; }
}

case "$engine" in
  ollama) translate_ollama || fail "Ollama failed. Is it running? (ollama serve / systemctl start ollama)" ;;
  bing)   translate_trans bing || fail "Bing translation failed (translate-shell)." ;;
  google) translate_trans google || fail "Google translation failed (translate-shell)." ;;
  *) # auto: local first, then network engines
     ollama_alive && translate_ollama
     translate_trans bing
     translate_trans google
     fail "All engines failed. Install/start Ollama, or install translate-shell (sudo pacman -S translate-shell), and check your network." ;;
esac
