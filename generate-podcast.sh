#!/bin/bash

# Check if an argument was provided
if [ -z "$1" ]; then
    echo "Please provide a subject for the podcast."
    exit 1
fi

# Run kokoro container
echo "Start kokoro container..."
docker container start kokoro

# Generate podcast
echo "Generating podcast for subject: $1"
claude -p "/create-podcast $1"

# Stop kokoro container
echo "Stopping kokoro container..."
docker container stop kokoro

# Move new podcast audio files to iCloud Podcasts folder
echo "Copying podcast to iCloud..."
mv ./output/*.mp3 /Users/stefandimov/Library/Mobile\ Documents/com\~apple\~CloudDocs/Podcasts

# Delete leftover podcast script text files from the output folder
echo "Deleting podcast scripts..."
rm -f ./output/*.txt

echo "🔉 Enjoy your podcast!"
