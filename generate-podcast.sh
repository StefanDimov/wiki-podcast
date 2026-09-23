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

# Copy to icloud
echo "Copying podcast to iCloud..."
./copy-to-icloud.sh

echo "🔉 Enjoy your podcast!"