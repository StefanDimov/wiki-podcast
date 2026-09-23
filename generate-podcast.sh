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

# Kokoro settings (override in .env)
KOKORO_CONTAINER="${KOKORO_CONTAINER:-kokoro}"
KOKORO_PORT="${KOKORO_PORT:-8880}"
KOKORO_VOICE="${KOKORO_VOICE:-af_bella}"
KOKORO_SPEED="${KOKORO_SPEED:-0.85}"
KOKORO_URL="http://localhost:$KOKORO_PORT"

# Check that the required tools are installed
for tool in claude jq curl docker; do
    if ! command -v "$tool" > /dev/null; then
        echo "$tool is not installed. See README for prerequisites."
        exit 1
    fi
done

# Check that Docker and the kokoro container are available
if ! docker info > /dev/null 2>&1; then
    echo "Docker is not running. Start Docker Desktop and try again."
    exit 1
fi

if ! docker container inspect "$KOKORO_CONTAINER" > /dev/null 2>&1; then
    echo "Docker container '$KOKORO_CONTAINER' does not exist. See README for setup."
    exit 1
fi

# Wait until no other podcast is being generated (one run at a time)
LOCK=".generating.lock"
until mkdir "$LOCK" 2>/dev/null; do
    pid=$(cat "$LOCK/pid" 2>/dev/null)
    if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then
        echo "Removing stale lock from process $pid"
        rm -rf "$LOCK"
        continue
    fi
    [ -n "$waiting" ] || echo "Another podcast is being generated, waiting..."
    waiting=1
    sleep 10
done
echo $$ > "$LOCK/pid"
trap 'rm -rf "$LOCK"' EXIT

# Write podcast script
echo "Writing podcast script for subject: $1"
claude -p "/write-podcast-script $1"

# Run kokoro container
echo "Start kokoro container..."
docker container start "$KOKORO_CONTAINER" || { echo "Failed to start kokoro container."; exit 1; }

# Wait for the Kokoro API to be ready
echo "Waiting for kokoro to be ready..."
for _ in $(seq 1 60); do
    curl -sf "$KOKORO_URL/health" > /dev/null && break
    sleep 2
done

if ! curl -sf "$KOKORO_URL/health" > /dev/null; then
    echo "Kokoro did not become ready in time."
    docker container stop "$KOKORO_CONTAINER"
    exit 1
fi

# Generate podcast audio from each script via the Kokoro API
for script in ./output/*.txt; do
    [ -e "$script" ] || { echo "No podcast script was written."; docker container stop "$KOKORO_CONTAINER"; exit 1; }
    audio="${script%.txt}.mp3"
    echo "Generating audio: $script -> $audio (takes around 5 min)"
    jq -Rs --arg voice "$KOKORO_VOICE" --argjson speed "$KOKORO_SPEED" \
        '{model: "kokoro", voice: $voice, input: ., response_format: "mp3", speed: $speed}' "$script" |
        curl -sS --fail -X POST "$KOKORO_URL/v1/audio/speech" \
            -H "Content-Type: application/json" \
            --data-binary @- \
            --output "$audio" || { echo "Audio generation failed."; docker container stop "$KOKORO_CONTAINER"; exit 1; }
done

# Stop kokoro container
echo "Stopping kokoro container..."
docker container stop "$KOKORO_CONTAINER"

# Move new podcast audio files to the destination folder
echo "Moving podcast to $PODCAST_DESTINATION..."
mv ./output/*.mp3 "$PODCAST_DESTINATION"

# Delete leftover podcast script text files from the output folder
echo "Deleting podcast scripts..."
rm -f ./output/*.txt

echo "🔉 Enjoy your podcast!"
