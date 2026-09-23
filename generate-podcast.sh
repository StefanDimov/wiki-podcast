#!/bin/bash

# Check if an argument was provided
if [ -z "$1" ]; then
    echo "Please provide a subject for the podcast."
    exit 1
fi

# Load local settings
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

if [ -z "$PODCAST_DESTINATION" ]; then
    echo "PODCAST_DESTINATION is not set. Copy .env.example to .env and set it."
    exit 1
fi

if [ ! -d "$PODCAST_DESTINATION" ]; then
    echo "PODCAST_DESTINATION does not exist: $PODCAST_DESTINATION"
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

# Move new podcast audio files to the destination folder
echo "Moving podcast to $PODCAST_DESTINATION..."
mv ./output/*.mp3 "$PODCAST_DESTINATION"

# Delete leftover podcast script text files from the output folder
echo "Deleting podcast scripts..."
rm -f ./output/*.txt

echo "🔉 Enjoy your podcast!"
