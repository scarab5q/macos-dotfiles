#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Copy from Simulator
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 📱
# @raycast.packageName Simulator Clipboard

# Documentation:
# @raycast.description Copy iOS Simulator clipboard to Mac clipboard

xcrun simctl pbpaste booted | pbcopy
echo "Simulator clipboard copied to Mac"
