#!/usr/bin/env bash
# macOS preferences for development. Read every line before running.
# Re-running is harmless. Log out and back in afterwards for keyboard changes.

set -euo pipefail

echo "Applying macOS defaults..."

# --- Finder ---
defaults write NSGlobalDomain AppleShowAllExtensions -bool true      # always show .js, .env, etc.
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"  # search current folder, not whole Mac
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
# Hidden files: toggle with Cmd+Shift+. in Finder instead of showing them always.

# --- Keyboard ---
# Holding a key repeats it instead of showing the accent menu (é, ñ).
# Delete this line if you type in languages that need accents.
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# --- Kill "smart" typing (it corrupts code pasted between apps) ---
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# --- Screenshots out of the Desktop ---
# The folder is created here, but the location must be chosen BY HAND:
#   Cmd+Shift+5 > Options > Other Location... > ~/Screenshots
# Setting it with `defaults write` broke capture on macOS 26 ("Unable to capture
# desktop image"), most likely because choosing it in the UI grants folder access
# that a defaults write can't.
mkdir -p "$HOME/Screenshots"

# --- Dock ---
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock show-recents -bool false

killall Finder Dock SystemUIServer 2>/dev/null || true
echo "Done. Log out and back in for key repeat changes to take effect."
echo "MANUAL STEP: set screenshot location via Cmd+Shift+5 > Options > Other Location."
