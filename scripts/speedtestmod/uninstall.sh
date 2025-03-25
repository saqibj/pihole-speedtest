#!/bin/bash

# Version information
MOD_VERSION="2.1.2"
REQUIRED_PIHOLE_VERSION="6.x"

# Initialize error tracking
UNINSTALL_ERRORS=0
ERROR_MESSAGES=()

# Function to log errors
log_error() {
    UNINSTALL_ERRORS=$((UNINSTALL_ERRORS + 1))
    ERROR_MESSAGES+=("$1")
    echo "Error: $1"
}

# Check if Pi-hole is installed
if ! command -v pihole &> /dev/null; then
    log_error "Pi-hole is not installed."
    exit 1
fi

# Get Pi-hole version
PIHOLE_VERSION=$(pihole -v | grep -oP "v\K[0-9]+\.[0-9]+")
if [[ -z "$PIHOLE_VERSION" ]]; then
    log_error "Could not determine Pi-hole version."
    exit 1
fi

# Check if version is 6.x
if [[ ! "$PIHOLE_VERSION" =~ ^6\. ]]; then
    log_error "This uninstaller (v${MOD_VERSION}) is designed for Pi-hole ${REQUIRED_PIHOLE_VERSION}. Your version is $PIHOLE_VERSION"
    exit 1
fi

# Define paths
WEB_DIR="/var/www/html/admin"
DB_DIR="/etc/pihole/pihole-6-speedtest"

# Find web interface directory
if [ ! -d "$WEB_DIR" ]; then
    echo "Looking for Pi-hole web interface directory..."
    # Try common locations
    for dir in "/var/www/html/admin" "/var/www/html/pihole" "/var/www/pihole" "/var/www/html"; do
        if [ -d "$dir" ]; then
            WEB_DIR="$dir"
            echo "Found web interface at: $WEB_DIR"
            break
        fi
    done
fi

if [ ! -d "$WEB_DIR" ]; then
    log_error "Could not find Pi-hole web interface directory"
    exit 1
fi

# Find index file
INDEX_FILE=""
for file in "index.php" "index.lp" "index.html"; do
    if [ -f "$WEB_DIR/$file" ]; then
        INDEX_FILE="$WEB_DIR/$file"
        echo "Found index file: $INDEX_FILE"
        break
    fi
done

if [ -z "$INDEX_FILE" ]; then
    log_error "Could not find index file in web interface directory"
    exit 1
fi

# Remove speedtest files
echo "Removing speedtest files..."
if [ -f "$WEB_DIR/scripts/js/speedtest.js" ]; then
    if ! sudo rm "$WEB_DIR/scripts/js/speedtest.js"; then
        log_error "Failed to remove speedtest.js"
    fi
fi

if [ -f "$WEB_DIR/style/speedtest.css" ]; then
    if ! sudo rm "$WEB_DIR/style/speedtest.css"; then
        log_error "Failed to remove speedtest.css"
    fi
fi

if [ -f "/usr/local/bin/pihole-6-speedtest" ]; then
    if ! sudo rm "/usr/local/bin/pihole-6-speedtest"; then
        log_error "Failed to remove speedtest script"
    fi
fi

# Remove speedtest widget from dashboard
if grep -q "speedtest-results" "$INDEX_FILE"; then
    echo "Removing speedtest widget from dashboard..."
    if ! sudo sed -i '/<!-- Add Speedtest Widget -->/,/<!-- \/\.\/col -->\n<\/div>/d' "$INDEX_FILE"; then
        log_error "Failed to remove speedtest widget"
    fi
fi

# Remove speedtest script from page
if grep -q "speedtest.js" "$INDEX_FILE"; then
    echo "Removing speedtest script from page..."
    if ! sudo sed -i '/<!-- Add Speedtest Script -->/,/<script src="<?=pihole.fileversion('\''scripts\/js\/speedtest.js'\'')?>">/d' "$INDEX_FILE"; then
        log_error "Failed to remove speedtest script reference"
    fi
fi

# Remove database directory
if [ -d "$DB_DIR" ]; then
    echo "Removing database directory..."
    if ! sudo rm -rf "$DB_DIR"; then
        log_error "Failed to remove database directory"
    fi
fi

# Remove speedtest cron job if it exists
if [ -f "/etc/cron.d/pihole-6-speedtest" ]; then
    echo "Removing speedtest cron job..."
    if ! sudo rm "/etc/cron.d/pihole-6-speedtest"; then
        log_error "Failed to remove speedtest cron job"
    fi
fi

# Restart Pi-hole FTL service
echo "Restarting Pi-hole FTL service..."
if command -v systemctl &> /dev/null; then
    if ! sudo systemctl restart pihole-FTL; then
        log_error "Failed to restart Pi-hole FTL service"
    fi
else
    if ! sudo service pihole-FTL restart; then
        log_error "Failed to restart Pi-hole FTL service"
    fi
fi

# Print uninstallation summary
echo
if [ $UNINSTALL_ERRORS -eq 0 ]; then
    echo "Speedtest mod uninstalled successfully!"
    echo "Please refresh your Pi-hole web interface to see the changes."
else
    echo "Speedtest mod uninstallation completed with $UNINSTALL_ERRORS error(s):"
    for error in "${ERROR_MESSAGES[@]}"; do
        echo "- $error"
    done
    echo
    echo "Please check the errors above and try to resolve them manually."
    echo "You may need to refresh your Pi-hole web interface to see partial changes."
    exit 1
fi 