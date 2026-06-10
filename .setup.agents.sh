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
# Restore skills from skills-lock.json
# Lock 등재 스킬은 git에 커밋하지 않으므로(.gitignore) fresh clone 에선 본체가 없다.
# `npx skills` CLI 로 복원하되, CLI 의 멀티-agent fan-out 으로 .agents 가 오염되는 걸
# 막으려 임시 디렉터리(skills-lock.json 만 존재)에서 돌린 뒤 누락분만 복사한다.
# 이미 존재하는 스킬(특히 upstream 없는 my-*)은 건드리지 않는다 — 멱등.
# 주의: lock 에 commit SHA 가 없어 복원은 항상 upstream 최신 HEAD 를 가져온다.
##############################################################

skills_lock="$dotfiles_dir/.agents/skills-lock.json"
if command -v npx >/dev/null 2>&1 && command -v jq >/dev/null 2>&1 && [ -f "$skills_lock" ]; then
    missing=$(jq -r '.skills | keys[]' "$skills_lock" | while read -r name; do
        [ -d "$dotfiles_dir/.agents/skills/$name" ] || echo "$name"
    done)

    if [ -n "$missing" ]; then
        echo -e "\n${PURPLE}••••••• restoring skills from skills-lock.json${NC}"
        mkdir -p "$dotfiles_dir/.agents/skills"
        staging=$(mktemp -d)
        cp "$skills_lock" "$staging/skills-lock.json"
        ( cd "$staging" && npx -y skills@latest experimental_install -y ) >/dev/null 2>&1 || true

        echo "$missing" | while read -r name; do
            [ -z "$name" ] && continue
            if [ -d "$staging/.agents/skills/$name" ]; then
                rm -rf "$dotfiles_dir/.agents/skills/$name"
                cp -R "$staging/.agents/skills/$name" "$dotfiles_dir/.agents/skills/$name"
                echo -e "${GRAY}  ✓ $name${NC}"
            else
                echo -e "  ✗ $name ${YELLOW}(복원 실패 — skills-lock.json 확인)${NC}"
            fi
        done

        rm -rf "$staging"
    else
        echo -e "${GRAY}••••••• skills 복원 불필요 (lock 등재분 전부 존재)${NC}"
    fi
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
