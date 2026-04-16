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

rm -rf "$HOME/.claude/skills"
ln -sfn "$HOME/.agents/skills" "$HOME/.claude/skills"

rm -rf "$HOME/.claude/settings.json"
ln -sfn "$dotfiles_dir/.config/claude/settings.json" "$HOME/.claude/settings.json"

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
# Verify hook scripts referenced in settings.json exist and are executable
##############################################################

if command -v jq >/dev/null 2>&1 && [ -f "$dotfiles_dir/.config/claude/settings.json" ]; then
    echo -e "\n${PURPLE}••••••• verifying hook scripts${NC}"
    # Strip JSONC line comments (`//`) since jq accepts only strict JSON
    sed -E 's:^[[:space:]]*//.*$::' "$dotfiles_dir/.config/claude/settings.json" \
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
fi

echo -e "\n${YELLOW}---- Agents setup complete ✔${NC}"
