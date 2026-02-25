#!/usr/bin/env bash

set -euo pipefail

YELLOW='\033[1;33m' # switching section
GRAY='\033[1;30m'   # info
PURPLE='\033[1;35m' # making change
NC='\033[0m'        # No Color

DOTFILES_REPO="https://github.com/bepyan/dotfiles.git"
DOTFILES_DIR="$HOME/vscode/dotfiles"

# 1) Install Xcode Command Line Tools (we can use git)
echo -e "${YELLOW}---- Installing Xcode Command Line Tools${NC}"
if ! xcode-select -p &>/dev/null; then
    xcode-select --install
    until xcode-select -p &>/dev/null; do
        sleep 5
    done
fi
echo -e "${GRAY}---- Xcode Command Line Tools installed${NC}"

# 2) Clone the repo
echo -e "${YELLOW}---- Cloning the Dotfiles repo${NC}"
if [ -d "$DOTFILES_DIR" ]; then
    echo -e "${PURPLE}---- dotfiles already exists, pulling latest...${NC}"
    git -C "$DOTFILES_DIR" pull
    echo -e "${GRAY}---- dotfiles pulled latest${NC}"
else
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    echo -e "${GRAY}---- dotfiles cloned successfully${NC}"
fi

# 3) Install Packages & Apps
source "$current_dir/.brew.sh"

# 4) Run the main setup script
cd "$DOTFILES_DIR"
exec ./.setup.main.sh
