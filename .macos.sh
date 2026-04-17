#!/usr/bin/env bash
#
# macOS Setup Script
#
# Sources:
# - https://macos-defaults.com
# - https://github.com/mathiasbynens/dotfiles
# - https://github.com/driesvints/dotfiles
# - https://grishy.dev/en/posts/macOS-setup-2025

set -Eeuo pipefail

YELLOW='\033[1;33m' # switching section
GRAY='\033[1;30m'   # info
PURPLE='\033[1;35m' # making change
NC='\033[0m'        # No Color

echo -e "\n${YELLOW}---- MacOS related changes${NC}"

# Detect macOS version
OS_VERSION=$(sw_vers -productVersion)
echo -e "${GRAY}---- Detected macOS version: $OS_VERSION${NC}"

# Close any open System Settings panes
osascript -e 'tell application "System Settings" to quit'

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until `macos` has finished
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done 2>/dev/null &

###############################################################################
# Finder                                                                      #
###############################################################################

echo -e "${PURPLE}---- Configuring Finder settings...${NC}"

# allow quitting via ⌘ + Q; doing so will also hide desktop icons
defaults write com.apple.finder QuitMenuItem -bool true

# show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true
# show status bar
defaults write com.apple.finder ShowStatusBar -bool true
# show path bar
defaults write com.apple.finder ShowPathbar -bool true
# Display full POSIX path as Finder window title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Finder: Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirstOnDesktop -bool true
defaults write com.apple.finder _FXSortFoldersFirst -bool true
# Finder: Preferred List view
defaults write com.apple.finder FXPreferredViewStyle -string Nlsv
# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Disable Finder animations for speed
defaults write com.apple.finder DisableAllAnimations -bool true

# Enable spring loading for directories
defaults write NSGlobalDomain com.apple.springing.enabled -bool true

# Remove the spring loading delay for directories
defaults write NSGlobalDomain com.apple.springing.delay -float 0

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

###############################################################################
# Dock
###############################################################################

echo -e "${PURPLE}---- Configuring Dock settings...${NC}"

# Remove the auto-hiding Dock delay
defaults write com.apple.dock autohide-delay -float 0
# Remove the animation when hiding/showing the Dock
defaults write com.apple.dock autohide-time-modifier -float 0

# Automatically hide and show the Dock
defaults write com.apple.dock autohide -bool true

###############################################################################
# Trackpad
###############################################################################

echo -e "${PURPLE}---- Configuring Trackpad settings...${NC}"

# Dragging with three finger drag
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true

###############################################################################
# Activity Monitor
###############################################################################

echo -e "${PURPLE}---- Configuring Activity Monitor settings...${NC}"

# Show all processes
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Sort by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

# Update frequency: Often (2 seconds)
defaults write com.apple.ActivityMonitor UpdatePeriod -int 2

###############################################################################
# PRIVACY & SECURITY
###############################################################################

echo -e "${PURPLE}---- Configuring Privacy & Security settings...${NC}"

# Disable Spotlight web search (keeps searches local)
defaults write com.apple.lookup.shared LookupSuggestionsDisabled -bool true

# Disable crash reporter dialog
defaults write com.apple.CrashReporter DialogType -string "none"

###############################################################################

echo -e "\n${GRAY}---- macOS related changes done. Note that some of these changes require a logout/restart to take effect.${NC}\n"

echo -e "\n${YELLOW}---- Do these settings manually${NC}"
echo -e "${PURPLE}---- 1. Keyboard > Keyboard Shortcuts > Spotlight${NC}"
echo -e "${PURPLE}----     disable \"show spotlight search\"${NC}"
echo -e "${PURPLE}----     disable \"show finder search window\"${NC}"
echo -e "${PURPLE}---- 2. Keyboard > Input Sources > cmd + space ${NC}"
