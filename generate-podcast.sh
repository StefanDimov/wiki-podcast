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

# Write podcast script
echo "Writing podcast script for subject: $1"
claude -p "/create-podcast $1"

# Run kokoro container
echo "Start kokoro container..."
docker container start kokoro

# Wait for the Kokoro API to be ready
echo "Waiting for kokoro to be ready..."
for _ in $(seq 1 60); do
    curl -sf http://localhost:8880/health > /dev/null && break
    sleep 2
done

# Generate podcast audio from each script via the Kokoro API
for script in ./output/*.txt; do
    [ -e "$script" ] || { echo "No podcast script was written."; docker container stop kokoro; exit 1; }
    audio="${script%.txt}.mp3"
    echo "Generating audio: $script -> $audio (takes around 5 min)"
    jq -Rs '{model: "kokoro", voice: "af_bella", input: ., response_format: "mp3", speed: 0.85}' "$script" |
        curl -sS --fail -X POST http://localhost:8880/v1/audio/speech \
            -H "Content-Type: application/json" \
            --data-binary @- \
            --output "$audio" || { echo "Audio generation failed."; docker container stop kokoro; exit 1; }
done

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
