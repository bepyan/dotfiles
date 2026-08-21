#!/usr/bin/env bash
# meta: source=ITlearning/claude-statusline-memes-derived updateDate=2026-04-17
#
# Claude Code statusLine renderer. Two-line output, invoked per-refresh.
# Line 1: user:cwd branch[*] [CAVEMAN]
# Line 2: ctx ██░░░░ NN% │ model
# Reference: https://docs.anthropic.com/en/docs/claude-code/settings#statusline

set -u

input=$(cat)
cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir' | sed "s|$HOME|~|g")
ctx_remaining=$(printf '%s' "$input" | jq -r '.context_window.remaining_percentage // 100')
ctx_used=$((100 - ctx_remaining))
model=$(printf '%s' "$input" | jq -r '.model.display_name // empty')
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty')

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

# ─── Line 2: ctx + model ────────────────────────────────────────────
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

# transcript에서 현 세션 최신 plan 파일 절대경로 추출 → ~ 축약.
# awk single-pass = 마지막 매치만 취함(BSD/GNU 무관, tac 불필요).
current_plan_file() {
  [ -n "$transcript" ] && [ -f "$transcript" ] || return 1
  local p
  p=$(awk -F'"planFilePath":"' 'NF>1{split($2,a,"\""); p=a[1]} END{print p}' "$transcript")
  [ -n "$p" ] && [ -f "$p" ] || return 1   # planExists(stale) 대신 실시간 검사
  printf '%s' "$p" | sed "s|$HOME|~|"      # line1 cwd 표기와 동일 관례
}

render_seg "ctx" "$ctx_used" 6
[ -n "$model" ] && printf '%s │ %s%s' "$K" "$model" "$R"
echo

# ─── Line 3: 현재 세션 계획서 (있을 때만) ───────────────────────
if plan_path=$(current_plan_file); then
  printf '%splan: %s%s\n' "$K" "$plan_path" "$R"
fi
