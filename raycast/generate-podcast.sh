#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Generate Podcast
# @raycast.mode silent
# @raycast.argument1 { "type": "text", "placeholder": "Subject" }

# Optional parameters:
# @raycast.icon 🎙️
# @raycast.packageName Wiki Podcast
# @raycast.description Generate a podcast on a subject and copy it to iCloud

# Raycast doesn't load your shell profile, so make sure Homebrew tools are found
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

cd "$(dirname "$0")/.." || exit 1

# Run in the background so Raycast doesn't block; notify when done
nohup bash -c '
    if ./generate-podcast.sh "$1" > output/raycast.log 2>&1; then
        osascript -e "display notification \"Podcast on $1 is ready\" with title \"🔉 Wiki Podcast\""
    else
        osascript -e "display notification \"Failed — see output/raycast.log\" with title \"Wiki Podcast\""
    fi
' _ "$1" > /dev/null 2>&1 &

echo "Generating podcast: $1"
