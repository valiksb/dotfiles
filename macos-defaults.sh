#!/usr/bin/env bash
# Equivalent of system.defaults in configuration.nix, for the non-Nix setup.
# Safe to re-run. Settings enforced by an MDM profile may not take effect.
set -euo pipefail

defaults write NSGlobalDomain AppleInterfaceStyle -string Dark
defaults write NSGlobalDomain KeyRepeat -int 2            # fast key repeat
defaults write NSGlobalDomain InitialKeyRepeat -int 15    # short delay before repeat
defaults write NSGlobalDomain _HIHideMenuBar -bool false
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

defaults write com.apple.dock autohide -bool true

defaults write com.apple.finder FXPreferredViewStyle -string Nlsv  # list view
defaults write com.apple.finder CreateDesktop -bool false          # clean desktop

# tap to click
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# macOS 26: 3 = "Never" (always show menu bar)
defaults write com.apple.controlcenter AutoHideMenuBarOption -int 3

defaults -currentHost write com.apple.screensaver idleTime -int 300

killall Dock Finder 2>/dev/null || true
