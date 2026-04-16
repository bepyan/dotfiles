#!/usr/bin/env bash
# meta: source=native updateDate=2026-04-16
#
# Claude Code statusLine renderer.
# Invoked per-refresh by Claude Code with hook payload on stdin.
# Reference: https://docs.anthropic.com/en/docs/claude-code/settings#statusline
#
# Output example:
#   bepyan:~/vscode/dotfiles main* ctx:27% [CAVEMAN:LITE]

set -u

input=$(cat)
cwd=$(echo "$input"     | jq -r '.workspace.current_dir' | sed "s|$HOME|~|g")
ctx_used=$(echo "$input" | jq -r '.context_window.remaining_percentage // 100')
ctx_used=$((100 - ctx_used))

cd "$(echo "$input" | jq -r '.workspace.current_dir')" 2>/dev/null
user=$(git config user.name 2>/dev/null || whoami)
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')
status=''
[ -n "$branch" ] && [ -n "$(git status --porcelain 2>/dev/null)" ] && status='*'

# truecolor palette
B='\033[38;2;30;102;245m'   # blue    — directory path
G='\033[38;2;64;160;43m'    # green   — git branch
Y='\033[38;2;223;142;29m'   # yellow  — dirty marker
C='\033[38;2;23;146;153m'   # cyan    — username
K='\033[38;2;139;148;158m'  # gray    — ctx
R='\033[0m'

printf "${C}${user}${R}:${B}${cwd}${R}"
[ -n "$branch" ]    && printf " ${G}${branch}${Y}${status}${R}"
printf " ${K}ctx:${ctx_used}%%${R}"

# ── Caveman badge suffix ─────────────────────────────────────────
# Original source: https://github.com/JuliusBrussee/caveman/blob/main/hooks/README.md
# 활성화되지 않으면 빈 문자열을 반환하므로 조건 없이 suffix 로 붙여도 안전.
caveman_text=""
caveman_flag="$HOME/.claude/.caveman-active"
if [ -f "$caveman_flag" ]; then
  caveman_mode=$(cat "$caveman_flag" 2>/dev/null)
  if [ "$caveman_mode" = "full" ] || [ -z "$caveman_mode" ]; then
    caveman_text=$'\033[38;5;172m[CAVEMAN]\033[0m'
  else
    caveman_suffix=$(echo "$caveman_mode" | tr '[:lower:]' '[:upper:]')
    caveman_text=$'\033[38;5;172m[CAVEMAN:'"${caveman_suffix}"$']\033[0m'
  fi
fi

echo
