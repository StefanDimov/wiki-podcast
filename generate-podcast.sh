#!/bin/bash

# Check if an argument was provided
if [ -z "$1" ]; then
    echo "Please provide a subject for the podcast."
    exit 1
fi

# Generate podcast
opencode run "/create-podcast $1"

# Copy to icloud
./copy-to-icloud.sh