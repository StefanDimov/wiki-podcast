#!/bin/bash

# Check if an argument was provided
if [ -z "$1" ]; then
    echo "Please provide a subject for the podcast."
    exit 1
fi

# Generate podcast
echo "Generating podcast for subject: $1"
opencode run "/create-podcast $1"

# Copy to icloud
echo "Copying podcast to iCloud..."
./copy-to-icloud.sh

echo "🔉 Enjoy your podcast!"