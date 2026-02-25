#!/usr/bin/env bash
#
# Install Applications & Packages & VSCode extensions via homebrew
# .brewfile is the manifest for the applications and packages to install
# 
# Can be run standalone or sourced from .setup.sh

YELLOW='\033[1;33m' # switching section
GRAY='\033[1;30m'   # info
PURPLE='\033[1;35m' # making change
NC='\033[0m'        # No Color

# Detect dotfiles directory: use $current_dir if set (sourced from .setup.sh),
# otherwise derive from this script's location
dotfiles_dir="${current_dir:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

echo -e "\n${YELLOW}---- Asking for an admin password upfront${NC}"
sudo -v

echo -e "\n${YELLOW}---- Homebrew updates${NC}"
echo -e "${GRAY}---- Turning homebrew analytics off.${NC}"
brew analytics off

echo -e "\n${PURPLE}---- clean up to match brewfile ${NC}"
brew bundle --force cleanup --file="$dotfiles_dir/.brewfile"

echo -e "\n${PURPLE}---- installing from brewfile${NC}"
brew bundle install -v --file="$dotfiles_dir/.brewfile"
brew bundle install -v --file="$dotfiles_dir/.brewfile.vscode"
HOMEBREW_BUNDLE_VSCODE_COMMAND="cursor" brew bundle install -v --file="$dotfiles_dir/.brewfile.vscode"

echo -e "\n${PURPLE}---- cask upgrade (via cu) ${NC}"
brew cu --all --cleanup --yes

echo -e "\n${PURPLE}---- updating formulae${NC}"
echo -e "${GRAY}update the local downloaded git repo with latest code${NC}"
brew update

echo -e "\n${PURPLE}---- upgrading packages${NC}"
echo -e "${GRAY}does the actual upgrade of packages to update formulate from above step${NC}"
brew upgrade

echo -e "\n${YELLOW}---- Homebrew setup complete ✔${NC}"
