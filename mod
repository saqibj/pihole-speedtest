#!/bin/bash

# Check if Pi-hole is installed
if ! command -v pihole &> /dev/null; then
    echo "Pi-hole is not installed. Please install Pi-hole first."
    exit 1
fi

# Get Pi-hole version
PIHOLE_VERSION=$(pihole -v | grep -oP "v\K[0-9]+\.[0-9]+")
if [[ -z "$PIHOLE_VERSION" ]]; then
    echo "Could not determine Pi-hole version."
    exit 1
fi

# Check if version is 6.x
if [[ ! "$PIHOLE_VERSION" =~ ^6\. ]]; then
    echo "This mod is designed for Pi-hole 6.x. Your version is $PIHOLE_VERSION"
    exit 1
fi

# Download and execute the Pi-hole 6 compatible mod script
curl -sSLN https://github.com/arevindh/pi-hole/raw/pihole-6/advanced/Scripts/speedtestmod/mod.sh | sudo bash -s -- "$@"
