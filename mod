#!/bin/bash

# Download the installation script
INSTALL_SCRIPT_URL="https://raw.githubusercontent.com/saqibj/pihole-speedtest/main/scripts/speedtestmod/install.sh"
TEMP_DIR=$(mktemp -d)
INSTALL_SCRIPT="$TEMP_DIR/install.sh"

echo "Downloading installation script..."
curl -sSL "$INSTALL_SCRIPT_URL" -o "$INSTALL_SCRIPT"

if [ ! -f "$INSTALL_SCRIPT" ]; then
    echo "Failed to download installation script"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Make the script executable
chmod +x "$INSTALL_SCRIPT"

# Execute the installation script
"$INSTALL_SCRIPT" "$@"

# Clean up
rm -rf "$TEMP_DIR"
