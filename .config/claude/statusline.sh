#!/usr/bin/env bash
# meta: source=ITlearning/claude-statusline-memes-derived updateDate=2026-04-17
#
# Claude Code statusLine renderer. Two-line output, invoked per-refresh.
# Line 1: user:cwd branch[*] [CAVEMAN]
# Line 2: ctx ██░░░░ NN% │ $146 / $200
# Reference: https://docs.anthropic.com/en/docs/claude-code/settings#statusline

set -u

input=$(cat)
cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir' | sed "s|$HOME|~|g")
ctx_remaining=$(printf '%s' "$input" | jq -r '.context_window.remaining_percentage // 100')
ctx_used=$((100 - ctx_remaining))
model=$(printf '%s' "$input" | jq -r '.model.display_name // empty')

cd "$(printf '%s' "$input" | jq -r '.workspace.current_dir')" 2>/dev/null
user=$(git config user.name 2>/dev/null || whoami)
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')
dirty=''
[ -n "$branch" ] && [ -n "$(git status --porcelain 2>/dev/null)" ] && dirty='*'

# Truecolor palette — ANSI-C quoting so vars hold real ESC bytes
# (safe to pass as %s args or through awk, unlike literal '\033...').
# https://github.com/anomalyco/opencode/blob/dev/packages/ui/src/theme/themes/vesper.json
B=$'\033[38;2;255;199;153m'   # #FFC799 primary  — directory
G=$'\033[38;2;153;255;228m'   # #99FFE4 success  — branch
Y=$'\033[38;2;255;199;153m'   # #FFC799 warning  — dirty marker
C=$'\033[38;2;255;255;255m'   # #FFFFFF ink      — username
K=$'\033[38;2;139;139;139m'   # #8B8B8B comment  — labels / separators / bars
R=$'\033[0m'

# ─── Line 1: user:cwd branch[*] [CAVEMAN] ──────────────────────────
printf '%s%s%s:%s%s%s' "$C" "$user" "$R" "$B" "$cwd" "$R"
[ -n "$branch" ] && printf ' %s%s%s%s%s' "$G" "$branch" "$Y" "$dirty" "$R"

caveman_flag="$HOME/.claude/.caveman-active"
if [ -f "$caveman_flag" ]; then
  caveman_mode=$(cat "$caveman_flag" 2>/dev/null)
  if [ "$caveman_mode" = "full" ] || [ -z "$caveman_mode" ]; then
    printf ' \033[38;5;172m[CAVEMAN]\033[0m'
  else
    caveman_suffix=$(printf '%s' "$caveman_mode" | tr '[:lower:]' '[:upper:]')
    printf ' \033[38;5;172m[CAVEMAN:%s]\033[0m' "$caveman_suffix"
  fi
fi
echo

# ─── Line 2: ctx + LiteLLM usage ────────────────────────────────────
llm_usage_cache="$HOME/.cache/jdai/llm-usage.json"

bar() {
  local p=$1 w=$2 f e i out=''
  f=$(awk -v p="$p" -v w="$w" \
      'BEGIN{x=int(p*w/100+0.5); if(x<0)x=0; if(x>w)x=w; print x}')
  e=$((w - f))
  for ((i=0; i<f; i++)); do out+='█'; done
  for ((i=0; i<e; i++)); do out+='░'; done
  printf '%s' "$out"
}

# render_seg <label> <pct> <width>
render_seg() {
  local label=$1 pct=${2:-} width=$3
  local b; b=$(bar "${pct:-0}" "$width")
  if [ -z "$pct" ]; then
    printf '%s%s %s --%%%s' "$K" "$label" "$b" "$R"
  else
    printf '%s%s %s %3.0f%%%s' "$K" "$label" "$b" "$pct" "$R"
  fi
}

format_usd() {
  awk -v n="$1" 'BEGIN {
    if (n == "") exit 1
    if (n == int(n)) printf "$%.0f", n
    else printf "$%.2f", n
  }'
}

_cache_mtime() {
  # BSD stat (macOS) 또는 GNU stat
  stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0
}

_refresh_script="$(dirname "$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "$0")")/llm-usage-refresh.sh"

render_litellm_usage() {
  command -v jq >/dev/null 2>&1 || return 1
  [ -f "$llm_usage_cache" ] || return 1

  local now mtime age stale=0
  now=$(date +%s)
  mtime=$(_cache_mtime "$llm_usage_cache")
  age=$((now - mtime))

  # 600-1800s: stale 값 표시 + 백그라운드 refresh
  if [ "$age" -gt 600 ] && [ -f "$_refresh_script" ]; then
    bash "$_refresh_script" &>/dev/null &
  fi
  # 1800s+: stale 플래그
  [ "$age" -gt 1800 ] && stale=1

  local spend budget spend_label budget_label remaining_pct used_pct
  spend=$(jq -r '(.conservative_spend_usd // .user_period_spend_usd // .key_spend_usd // empty) | tonumber? // empty' "$llm_usage_cache" 2>/dev/null)
  budget=$(jq -r '(.budget_usd // empty) | tonumber? // empty' "$llm_usage_cache" 2>/dev/null)
  [ -n "$spend" ] && [ -n "$budget" ] || return 1

  spend_label=$(format_usd "$spend") || return 1
  budget_label=$(format_usd "$budget") || return 1
  remaining_pct=$(jq -r '(.remaining_budget_pct // empty) | tonumber? // empty' "$llm_usage_cache" 2>/dev/null)
  used_pct=$(awk -v r="${remaining_pct:-0}" 'BEGIN{printf "%.0f", 100 - r}')

  # 색상: <80% dim / 80-89% yellow / >=90% red / stale gray
  local color
  if [ "$stale" -eq 1 ]; then
    color=$K
  elif [ "$used_pct" -lt 80 ]; then
    color=$K
  elif [ "$used_pct" -lt 90 ]; then
    color=$Y
  else
    color=$'\033[38;2;255;100;100m'
  fi

  if [ "$stale" -eq 1 ]; then
    printf '%s%s / %s (stale)%s' "$color" "$spend_label" "$budget_label" "$R"
  else
    printf '%s%s / %s%s' "$color" "$spend_label" "$budget_label" "$R"
  fi
}

render_seg "ctx" "$ctx_used" 6
[ -n "$model" ] && printf '%s │ %s%s' "$K" "$model" "$R"
if llm_usage=$(render_litellm_usage); then
  printf '%s │ %s' "$K" "$R"
  printf '%s' "$llm_usage"
fi
echo
