#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Copy to Simulator
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 📲
# @raycast.packageName Simulator Clipboard

# Documentation:
# @raycast.description Send Mac clipboard to the booted iOS Simulator clipboard

pbpaste | xcrun simctl pbcopy booted
echo "Clipboard sent to Simulator"
