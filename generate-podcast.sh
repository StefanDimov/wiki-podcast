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

# Check that Docker and the kokoro container are available
if ! command -v docker > /dev/null; then
    echo "docker is not installed."
    exit 1
fi

if ! docker info > /dev/null 2>&1; then
    echo "Docker is not running. Start Docker Desktop and try again."
    exit 1
fi

if ! docker container inspect kokoro > /dev/null 2>&1; then
    echo "Docker container 'kokoro' does not exist. See README for setup."
    exit 1
fi

# Write podcast script
echo "Writing podcast script for subject: $1"
claude -p "/write-podcast-script $1"

# Run kokoro container
echo "Start kokoro container..."
docker container start kokoro || { echo "Failed to start kokoro container."; exit 1; }

# Wait for the Kokoro API to be ready
echo "Waiting for kokoro to be ready..."
for _ in $(seq 1 60); do
    curl -sf http://localhost:8880/health > /dev/null && break
    sleep 2
done

if ! curl -sf http://localhost:8880/health > /dev/null; then
    echo "Kokoro did not become ready in time."
    docker container stop kokoro
    exit 1
fi

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
