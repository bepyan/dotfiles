#!/usr/bin/env bash
# meta: source=ITlearning/claude-statusline-memes-derived updateDate=2026-04-17
#
# Claude Code statusLine renderer. Two-line output, invoked per-refresh.
# Line 1: user:cwd branch[*] [CAVEMAN]
# Line 2: ctx ██░░░░ NN% │ 5h ░░░░░ NN% │ 7d ██░░░ NN%
# Reference: https://docs.anthropic.com/en/docs/claude-code/settings#statusline

set -u

input=$(cat)
cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir' | sed "s|$HOME|~|g")
ctx_remaining=$(printf '%s' "$input" | jq -r '.context_window.remaining_percentage // 100')
ctx_used=$((100 - ctx_remaining))

cd "$(printf '%s' "$input" | jq -r '.workspace.current_dir')" 2>/dev/null
user=$(git config user.name 2>/dev/null || whoami)
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')
dirty=''
[ -n "$branch" ] && [ -n "$(git status --porcelain 2>/dev/null)" ] && dirty='*'

# Truecolor palette — ANSI-C quoting so vars hold real ESC bytes
# (safe to pass as %s args or through awk, unlike literal '\033...').
B=$'\033[38;2;30;102;245m'    # blue    — directory
G=$'\033[38;2;64;160;43m'     # green   — branch / safe bar (<70%)
Y=$'\033[38;2;223;142;29m'    # yellow  — dirty marker / warn bar (≥70%)
RD=$'\033[38;2;220;50;47m'    # red     — crit bar (≥90%)
C=$'\033[38;2;23;146;153m'    # cyan    — username
K=$'\033[38;2;139;148;158m'   # gray    — labels / separators / empty bar
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

# ─── Line 2: ctx/5h/7d bars ─────────────────────────────────────────
cache="$HOME/.claude/statusline-rl-cache.json"
lock="$HOME/.claude/statusline-rl.lock"
CACHE_TTL=180   # seconds — cache freshness

# Live values from stdin (may be absent on older Claude Code builds).
fh_live=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
sd_live=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# Merge live values into cache so rendering is consistent across refreshes.
if [ -n "$fh_live" ] || [ -n "$sd_live" ]; then
  prev=$( [ -f "$cache" ] && cat "$cache" 2>/dev/null || echo '{}' )
  printf '%s' "$prev" | jq \
    --argjson fh "${fh_live:-null}" \
    --argjson sd "${sd_live:-null}" \
    '(if $fh != null then .five_hour.used_percentage = $fh else . end)
     | (if $sd != null then .seven_day.used_percentage = $sd else . end)' \
    > "$cache.tmp" 2>/dev/null && mv "$cache.tmp" "$cache" 2>/dev/null
fi

# Trigger background OAuth refresh when cache is stale AND no active lock,
# but only if stdin didn't already give us live values (no API call needed then).
now=$(date +%s)
last=$(jq -r '.api_fetched_at // 0' "$cache" 2>/dev/null)
last=${last%%.*}
[[ "$last" =~ ^[0-9]+$ ]] || last=0
lock_until=$(jq -r '.blocked_until // 0' "$lock" 2>/dev/null)
lock_until=${lock_until%%.*}
[[ "$lock_until" =~ ^[0-9]+$ ]] || lock_until=0

if [ -z "$fh_live" ] && [ -z "$sd_live" ] \
   && (( now - last > CACHE_TTL )) && (( now >= lock_until )); then
  nohup bash "$HOME/.claude/statusline-fetch-rl.sh" >/dev/null 2>&1 &
  disown 2>/dev/null || true
fi

# Resolved values: live wins, otherwise cache.
_fh=${fh_live:-$(jq -r '.five_hour.used_percentage // empty' "$cache" 2>/dev/null)}
_sd=${sd_live:-$(jq -r '.seven_day.used_percentage // empty' "$cache" 2>/dev/null)}

bar() {
  local p=$1 w=$2 f e i out=''
  f=$(awk -v p="$p" -v w="$w" \
      'BEGIN{x=int(p*w/100+0.5); if(x<0)x=0; if(x>w)x=w; print x}')
  e=$((w - f))
  for ((i=0; i<f; i++)); do out+='█'; done
  for ((i=0; i<e; i++)); do out+='░'; done
  printf '%s' "$out"
}

# Pick bar segment color by threshold; returns raw ESC bytes.
pick_color() {
  local p=${1:-}
  [ -z "$p" ] && { printf '%s' "$K"; return; }
  awk -v p="$p" -v g="$G" -v y="$Y" -v r="$RD" \
      'BEGIN{ if(p+0>=90)printf "%s",r; else if(p+0>=70)printf "%s",y; else printf "%s",g }'
}

# render_seg <label> <pct> <width>
render_seg() {
  local label=$1 pct=${2:-} width=$3
  local b; b=$(bar "${pct:-0}" "$width")
  if [ -z "$pct" ]; then
    printf '%s%s %s --%%%s' "$K" "$label" "$b" "$R"
  else
    local c; c=$(pick_color "$pct")
    printf '%s%s %s%s%s %s%3.0f%%%s' "$K" "$label" "$c" "$b" "$R" "$c" "$pct" "$R"
  fi
}

render_seg "ctx" "$ctx_used" 6
printf '%s │ %s' "$K" "$R"
render_seg "5h"  "$_fh"       5
printf '%s │ %s' "$K" "$R"
render_seg "7d"  "$_sd"       5
echo
