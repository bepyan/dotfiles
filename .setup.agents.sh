#!/usr/bin/env bash
#
# User-level (global) agent setup
# Sets up ~/.agents as the canonical intermediary, then wires each tool to it.
#
# Can be run standalone or sourced from .setup.sh

set -euo pipefail

YELLOW='\033[1;33m' # switching section
GRAY='\033[1;30m'   # info
PURPLE='\033[1;35m' # making change
NC='\033[0m'        # No Color

# Detect dotfiles directory: use $current_dir if set (sourced from .setup.sh),
# otherwise derive from this script's location
dotfiles_dir="${current_dir:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

echo -e "\n${YELLOW}---- Setting up agents symlinks${NC}"

##############################################################
# ~/.agents -> dotfiles/.agents (one canonical intermediary)
##############################################################

echo -e "\n${PURPLE}••••••• symlinking $dotfiles_dir/.agents -> $HOME/.agents ${NC}"
rm -rf "$HOME/.agents"
ln -sfn "$dotfiles_dir/.agents" "$HOME/.agents"

##############################################################
# Claude Code
# ~/.claude is a real directory (not a repo symlink)
# - agent assets go through ~/.agents intermediary
# - tool-specific files (statusline.sh) link directly to dotfiles repo
##############################################################

if [ -L "$HOME/.claude" ]; then
    echo -e "${PURPLE}••••••• removing legacy $HOME/.claude symlink ${NC}"
    rm "$HOME/.claude"
fi
mkdir -p "$HOME/.claude"

echo -e "${PURPLE}••••••• symlinking (claude) files${NC}"

rm -rf "$HOME/.claude/CLAUDE.md"
ln -sfn "$HOME/.agents/AGENTS.md" "$HOME/.claude/CLAUDE.md"

rm -rf "$HOME/.claude/commands"
ln -sfn "$HOME/.agents/commands" "$HOME/.claude/commands"

rm -rf "$HOME/.claude/rules"
ln -sfn "$HOME/.agents/rules" "$HOME/.claude/rules"

rm -rf "$HOME/.claude/agents"
ln -sfn "$HOME/.agents/agents" "$HOME/.claude/agents"

rm -rf "$HOME/.claude/skills"
ln -sfn "$HOME/.agents/skills" "$HOME/.claude/skills"

rm -rf "$HOME/.claude/settings.json"
ln -sfn "$dotfiles_dir/.config/claude/settings.json" "$HOME/.claude/settings.json"

rm -rf "$HOME/.claude/statusline.sh"
ln -sfn "$dotfiles_dir/.config/claude/statusline.sh" "$HOME/.claude/statusline.sh"

rm -rf "$HOME/.claude/statusline-fetch-rl.sh"
ln -sfn "$dotfiles_dir/.config/claude/statusline-fetch-rl.sh" "$HOME/.claude/statusline-fetch-rl.sh"

rm -rf "$HOME/.claude/llm-usage-refresh.sh"
ln -sfn "$dotfiles_dir/.config/claude/llm-usage-refresh.sh" "$HOME/.claude/llm-usage-refresh.sh"

##############################################################
# Codex
##############################################################

echo -e "${PURPLE}••••••• symlinking (codex) files${NC}"
mkdir -p "$HOME/.codex"

rm -rf "$HOME/.codex/AGENTS.md"
ln -sfn "$HOME/.agents/AGENTS.md" "$HOME/.codex/AGENTS.md"

rm -rf "$HOME/.codex/prompts"
ln -sfn "$HOME/.agents/commands" "$HOME/.codex/prompts"

rm -rf "$HOME/.codex/rules"
ln -sfn "$HOME/.agents/rules" "$HOME/.codex/rules"

# skills: codex reads $HOME/.agents/skills directly — no symlink needed

##############################################################
# Restore skills from rosie.lock
# Lock 등재 스킬은 git에 커밋하지 않으므로(.gitignore) fresh clone 에선 본체가 없다.
# rosie 가 lock 의 commit SHA 를 핀해 재현 가능하게 복원한다.
# `-a gemini-cli` 로 타깃을 .agents/skills 로 못박아 다른 agent 디렉터리로의
# fan-out(부산물) 을 막는다. rosie 는 이미 존재하는 스킬을 스킵하므로 멱등하며,
# upstream 없는 로컬 my-* 스킬은 lock 에 없어 건드리지 않는다.
##############################################################

rosie_lock="$dotfiles_dir/.agents/rosie.lock"
if command -v rosie >/dev/null 2>&1 && [ -f "$rosie_lock" ]; then
    echo -e "\n${PURPLE}••••••• restoring skills from rosie.lock${NC}"
    ( cd "$dotfiles_dir" && rosie install -a gemini-cli -y --no-audit ) >/dev/null 2>&1 \
        && echo -e "${GRAY}  ✓ rosie.lock 복원 완료${NC}" \
        || echo -e "  ✗ ${YELLOW}rosie 복원 실패 — 'cd $dotfiles_dir && rosie install -a gemini-cli' 수동 확인${NC}"
elif [ -f "$rosie_lock" ]; then
    echo -e "${YELLOW}••••••• rosie 미설치 — skills 복원 생략 (brew bundle 로 rosie 설치 후 재실행)${NC}"
fi

##############################################################
# Verify hook scripts referenced in settings.json exist and are executable
##############################################################

if command -v jq >/dev/null 2>&1 && [ -f "$dotfiles_dir/.config/claude/settings.json" ]; then
    echo -e "\n${PURPLE}••••••• verifying hook scripts${NC}"
    # Strip JSONC line comments (`//`) since jq accepts only strict JSON
    stripped=$(sed -E 's:^[[:space:]]*//.*$::' "$dotfiles_dir/.config/claude/settings.json")

    echo "$stripped" \
      | jq -r '.hooks // {} | to_entries[] | .value[]?.hooks[]?.command' 2>/dev/null \
      | while read -r cmd; do
            [ -z "$cmd" ] && continue
            expanded="${cmd//\$HOME/$HOME}"
            if [ -x "$expanded" ]; then
                echo -e "${GRAY}  ✓ $cmd${NC}"
            else
                echo -e "  ✗ $cmd ${YELLOW}(not found or not executable)${NC}"
            fi
        done || true

    # statusLine is invoked via `bash <script>`; only check file existence.
    status_cmd=$(echo "$stripped" | jq -r '.statusLine.command // empty' 2>/dev/null)
    if [ -n "$status_cmd" ]; then
        script_path=$(printf '%s' "$status_cmd" \
          | awk '{for(i=1;i<=NF;i++) if ($i ~ /\.(sh|py|bash)$/) {print $i; exit}}')
        expanded="${script_path//\$HOME/$HOME}"
        if [ -f "$expanded" ]; then
            echo -e "${GRAY}  ✓ statusLine: $script_path${NC}"
        else
            echo -e "  ✗ statusLine: $script_path ${YELLOW}(not found)${NC}"
        fi
    fi
fi

echo -e "\n${YELLOW}---- Agents setup complete ✔${NC}"
