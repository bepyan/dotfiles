#!/usr/bin/env bash

YELLOW='\033[1;33m' # switching section
GRAY='\033[1;30m'   # info
PURPLE='\033[1;35m' # making change
NC='\033[0m'        # No Color

set -euo pipefail

# capture the current directory
current_dir=$(pwd)

##############################################################
# Setup the dotfiles symlinks
##############################################################

echo -e "\n${YELLOW}---- Setting up .config${NC}"
files_to_link=(
    .config/ghostty
    .config/zsh
    .config/vscode
)
mkdir -p "$HOME/.config"
for file in "${files_to_link[@]}"; do
    echo -e "${PURPLE}••••••• symlinking $current_dir/$file -> $HOME/$file ${NC}"
    rm -rf "$HOME/$file"
    ln -sfn "$current_dir/$file" "$HOME/$file"
done

echo -e "\n${YELLOW}---- Setting up VSCode & Cursor${NC}"
vscode_settings="$current_dir/.config/vscode/settings.json"
vscode_targets=(
    "$HOME/Library/Application Support/Code/User/settings.json"
    "$HOME/Library/Application Support/Cursor/User/settings.json"
)
for target in "${vscode_targets[@]}"; do
    rm -f "$target"
    echo -e "${PURPLE}••••••• symlinking $vscode_settings -> $target${NC}"
    ln -sfn "$vscode_settings" "$target"
done

##############################################################
# Setup Development Environment
##############################################################

echo -e "\n${YELLOW}---- Setting up zsh${NC}"
DOTFILES_LINE='source "$HOME/.config/zsh/init.zsh"'
if ! grep -qF "$DOTFILES_LINE" ~/.zshrc 2>/dev/null; then
    echo "$DOTFILES_LINE" >> ~/.zshrc
fi

echo -e "\n${YELLOW}---- Setting up Node${NC}"
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
else
    echo -e "${GRAY}---- nvm already installed, skipping${NC}"
fi
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

nvm install 24
corepack enable pnpm

echo -e "\n${YELLOW}---- Setting up Bun${NC}"
if [ ! -d "$HOME/.bun" ]; then
    curl -fsSL https://bun.com/install | bash
else
    echo -e "${GRAY}---- bun already installed, skipping${NC}"
fi

echo -e "\n${YELLOW}---- Setting up Rust${NC}"
if [ ! -d "$HOME/.rustup" ]; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
else
    echo -e "${GRAY}---- rustup already installed, skipping${NC}"
fi

echo -e "\n${YELLOW}---- Setting up Python${NC}"
if ! command -v uv &>/dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
else
    echo -e "${GRAY}---- uv already installed, skipping${NC}"
fi
uv python install 3.13

echo -e "\n${YELLOW}---- Setting up Claude Code${NC}"
if ! command -v claude &>/dev/null; then
    curl -fsSL https://claude.ai/install.sh | bash
else
    echo -e "${GRAY}---- claude code already installed, skipping${NC}"
fi

echo -e "\n${YELLOW}---- Setting up gh${NC}"
if gh auth status &>/dev/null; then
    echo -e "${GRAY}---- logged in to github${NC}"
else
    echo -e "${PURPLE}---- you need to setup github, follow the prompts now ${NC}"
    gh auth login
fi

##############################################################
# MISC.
##############################################################

source "$current_dir/.setup.agents.sh"
# source $HOME/.macos.sh
# source $HOME/.cleanup.sh
