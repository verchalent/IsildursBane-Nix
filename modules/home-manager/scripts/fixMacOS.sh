#!/usr/bin/env bash

# Script to change additional MacOS and app settings outside of nix

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

# Set Wallpaper
osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"$(dirname "$PWD")/wallpaper/JackFrost.jpg\""

# Dock
defaults write com.apple.dock persistent-apps -array # Remove all persistent apps from the Dock  !!ONLY RUN ON FIRST RUN!!


#Desktop Services
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true # Avoid creating .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true # Avoid creating .DS_Store files on USB volumes

# Finder
defaults write com.apple.finder FXInfoPanesExpanded -dict \
	General -bool true \
	OpenWith -bool true \
	Privileges -bool true

# Disable Notification Center and remove the menu bar icon
launchctl unload -w /System/Library/LaunchAgents/com.apple.notificationcenterui.plist 2> /dev/null #need to test this