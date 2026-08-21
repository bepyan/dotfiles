#!/usr/bin/env bash
#
# macOS Setup Script
#
# Sources:
# - https://macos-defaults.com
# - https://github.com/mathiasbynens/dotfiles
# - https://github.com/driesvints/dotfiles
# - https://grishy.dev/en/posts/macOS-setup-2025
#

set -Eeuo pipefail

YELLOW='\033[1;33m' # switching section
GRAY='\033[1;30m'   # info
PURPLE='\033[1;35m' # making change
NC='\033[0m'        # No Color

log() { echo -e "${GRAY}---- $1${NC}"; }

echo -e "\n${YELLOW}---- MacOS related changes${NC}"

OS_VERSION=$(sw_vers -productVersion)
log "Detected macOS version: $OS_VERSION"

log "Close System Settings"
osascript -e 'tell application "System Settings" to quit'

log "Request administrator password"
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

log "Quit Finder via ⌘Q"
defaults write com.apple.finder QuitMenuItem -bool true

log "Show all filename extensions"
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
log "Show hidden files"
defaults write com.apple.finder AppleShowAllFiles -bool true
log "Show status bar"
defaults write com.apple.finder ShowStatusBar -bool true
log "Show path bar"
defaults write com.apple.finder ShowPathbar -bool true
log "POSIX path in Finder title"
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

log "Keep folders on top"
defaults write com.apple.finder _FXSortFoldersFirstOnDesktop -bool true
defaults write com.apple.finder _FXSortFoldersFirst -bool true
log "Preferred view: List"
defaults write com.apple.finder FXPreferredViewStyle -string Nlsv
log "Search current folder by default"
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

log "Disable Finder animations"
defaults write com.apple.finder DisableAllAnimations -bool true

log "Spring-loading for directories"
defaults write NSGlobalDomain com.apple.springing.enabled -bool true
log "Spring-loading delay: 0"
defaults write NSGlobalDomain com.apple.springing.delay -float 0

log "No .DS_Store on network/USB volumes"
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

###############################################################################
# Dock
###############################################################################

echo -e "${PURPLE}---- Configuring Dock settings...${NC}"

log "Dock autohide delay: 0"
defaults write com.apple.dock autohide-delay -float 0
log "Dock autohide animation: 0"
defaults write com.apple.dock autohide-time-modifier -float 0
log "Autohide Dock"
defaults write com.apple.dock autohide -bool true

###############################################################################
# Date & Time
###############################################################################

echo -e "${PURPLE}---- Configuring Date & Time settings...${NC}"

log "24-hour time (user)"
defaults write NSGlobalDomain AppleICUForce24HourTime -bool true
log "24-hour time (login screen / FileVault)"
sudo defaults write /Library/Preferences/.GlobalPreferences AppleICUForce24HourTime -bool true

###############################################################################
# Trackpad
###############################################################################

echo -e "${PURPLE}---- Configuring Trackpad settings...${NC}"

log "Three-finger drag"
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true

###############################################################################
# Keyboard
###############################################################################

echo -e "${PURPLE}---- Configuring Keyboard settings...${NC}"

log "Caps Lock → No Action"
defaults -currentHost write -g com.apple.keyboard.modifiermapping.0-0-0 -array \
  '<dict><key>HIDKeyboardModifierMappingSrc</key><integer>30064771129</integer><key>HIDKeyboardModifierMappingDst</key><integer>30064771072</integer></dict>'

log "Spotlight ⌘Space off"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 \
  '<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>49</integer><integer>1048576</integer></array><key>type</key><string>standard</string></dict></dict>'
log "Finder search ⌘⌥Space off"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 65 \
  '<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>49</integer><integer>1572864</integer></array><key>type</key><string>standard</string></dict></dict>'
log "Previous input source → ⌘Space"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 \
  '<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>1048576</integer></array><key>type</key><string>standard</string></dict></dict>'
log "Reload keyboard shortcuts"
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

###############################################################################
# Activity Monitor
###############################################################################

echo -e "${PURPLE}---- Configuring Activity Monitor settings...${NC}"

log "Show all processes"
defaults write com.apple.ActivityMonitor ShowCategory -int 0
log "Sort by CPU usage"
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0
log "Update every 2 seconds"
defaults write com.apple.ActivityMonitor UpdatePeriod -int 2

###############################################################################
# PRIVACY & SECURITY
###############################################################################

echo -e "${PURPLE}---- Configuring Privacy & Security settings...${NC}"

log "Disable Spotlight web search"
defaults write com.apple.lookup.shared LookupSuggestionsDisabled -bool true
log "Disable crash reporter dialog"
defaults write com.apple.CrashReporter DialogType -string "none"

###############################################################################

echo -e "\n${GRAY}---- macOS related changes done. Note that some of these changes require a logout/restart to take effect.${NC}\n"
