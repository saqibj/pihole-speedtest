#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Execute the installation script
"$SCRIPT_DIR/scripts/speedtestmod/install.sh" "$@"
