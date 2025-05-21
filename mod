#!/bin/bash

# Download the installation script
INSTALL_SCRIPT_URL="https://raw.githubusercontent.com/saqibj/pihole-speedtest/v2.2.0/scripts/speedtestmod/install.sh"
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

# Create a temporary directory for other required files
SPEEDTEST_DIR="$TEMP_DIR/speedtestmod"
mkdir -p "$SPEEDTEST_DIR"

# Download other required files
echo "Downloading required files..."
curl -sSL "https://raw.githubusercontent.com/saqibj/pihole-speedtest/v2.2.0/scripts/speedtestmod/speedtest.sh" -o "$SPEEDTEST_DIR/speedtest.sh"
curl -sSL "https://raw.githubusercontent.com/saqibj/pihole-speedtest/v2.2.0/scripts/speedtestmod/speedtest.js" -o "$SPEEDTEST_DIR/speedtest.js"
curl -sSL "https://raw.githubusercontent.com/saqibj/pihole-speedtest/v2.2.0/scripts/speedtestmod/speedtest.css" -o "$SPEEDTEST_DIR/speedtest.css"

# Make speedtest script executable
chmod +x "$SPEEDTEST_DIR/speedtest.sh"

# Set the SCRIPT_DIR environment variable for the installation script
export SCRIPT_DIR="$SPEEDTEST_DIR"

# Execute the installation script
"$INSTALL_SCRIPT" "$@"

# Clean up
rm -rf "$TEMP_DIR"
