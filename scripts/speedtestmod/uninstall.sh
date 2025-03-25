#!/bin/bash

# Version information
MOD_VERSION="2.1.2"
REQUIRED_PIHOLE_VERSION="6.x"

# Initialize error tracking
UNINSTALL_ERRORS=0
ERROR_MESSAGES=()

# Logging functions
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    UNINSTALL_ERRORS=$((UNINSTALL_ERRORS + 1))
    ERROR_MESSAGES+=("$1")
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_debug() {
    echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Check if Pi-hole is installed
log_info "Checking if Pi-hole is installed..."
if ! command -v pihole &> /dev/null; then
    log_error "Pi-hole is not installed."
    exit 1
fi
log_info "Pi-hole is installed."

# Get Pi-hole version
log_info "Checking Pi-hole version..."
PIHOLE_VERSION=$(pihole -v | grep -oP "v\K[0-9]+\.[0-9]+")
if [[ -z "$PIHOLE_VERSION" ]]; then
    log_error "Could not determine Pi-hole version."
    exit 1
fi
log_info "Pi-hole version: $PIHOLE_VERSION"

# Check if version is 6.x
if [[ ! "$PIHOLE_VERSION" =~ ^6\. ]]; then
    log_error "This uninstaller (v${MOD_VERSION}) is designed for Pi-hole ${REQUIRED_PIHOLE_VERSION}. Your version is $PIHOLE_VERSION"
    exit 1
fi

# Define paths
WEB_DIR="/var/www/html/admin"
DB_DIR="/etc/pihole/pihole-6-speedtest"

# Find web interface directory
log_info "Looking for Pi-hole web interface directory..."
if [ ! -d "$WEB_DIR" ]; then
    log_debug "Default web directory not found, searching in common locations..."
    # Try common locations
    for dir in "/var/www/html/admin" "/var/www/html/pihole" "/var/www/pihole" "/var/www/html"; do
        if [ -d "$dir" ]; then
            WEB_DIR="$dir"
            log_info "Found web interface at: $WEB_DIR"
            break
        fi
    done
fi

if [ ! -d "$WEB_DIR" ]; then
    log_error "Could not find Pi-hole web interface directory"
    exit 1
fi
log_info "Using web interface directory: $WEB_DIR"

# Find index file
log_info "Looking for index file..."
INDEX_FILE=""
for file in "index.php" "index.lp" "index.html"; do
    if [ -f "$WEB_DIR/$file" ]; then
        INDEX_FILE="$WEB_DIR/$file"
        log_info "Found index file: $INDEX_FILE"
        break
    fi
done

if [ -z "$INDEX_FILE" ]; then
    log_error "Could not find index file in web interface directory"
    exit 1
fi

# Remove speedtest files
log_info "Removing speedtest files..."
if [ -f "$WEB_DIR/scripts/js/speedtest.js" ]; then
    log_debug "Removing speedtest.js..."
    if ! sudo rm "$WEB_DIR/scripts/js/speedtest.js"; then
        log_error "Failed to remove speedtest.js"
    else
        log_info "Successfully removed speedtest.js"
    fi
else
    log_debug "speedtest.js not found at $WEB_DIR/scripts/js/speedtest.js"
fi

if [ -f "$WEB_DIR/style/speedtest.css" ]; then
    log_debug "Removing speedtest.css..."
    if ! sudo rm "$WEB_DIR/style/speedtest.css"; then
        log_error "Failed to remove speedtest.css"
    else
        log_info "Successfully removed speedtest.css"
    fi
else
    log_debug "speedtest.css not found at $WEB_DIR/style/speedtest.css"
fi

if [ -f "/usr/local/bin/pihole-6-speedtest" ]; then
    log_debug "Removing speedtest script..."
    if ! sudo rm "/usr/local/bin/pihole-6-speedtest"; then
        log_error "Failed to remove speedtest script"
    else
        log_info "Successfully removed speedtest script"
    fi
else
    log_debug "Speedtest script not found at /usr/local/bin/pihole-6-speedtest"
fi

# Remove speedtest widget from dashboard
log_info "Checking for speedtest widget in dashboard..."
if grep -q "speedtest-results" "$INDEX_FILE"; then
    log_debug "Found speedtest widget, removing..."
    if ! sudo sed -i '/<!-- Add Speedtest Widget -->/,/<!-- \/\.\/col -->\n<\/div>/d' "$INDEX_FILE"; then
        log_error "Failed to remove speedtest widget"
    else
        log_info "Successfully removed speedtest widget"
    fi
else
    log_debug "Speedtest widget not found in dashboard"
fi

# Remove speedtest script from page
log_info "Checking for speedtest script in page..."
if grep -q "speedtest.js" "$INDEX_FILE"; then
    log_debug "Found speedtest script reference, removing..."
    if ! sudo sed -i '/<!-- Add Speedtest Script -->/,/<script src="<?=pihole.fileversion('\''scripts\/js\/speedtest.js'\'')?>">/d' "$INDEX_FILE"; then
        log_error "Failed to remove speedtest script reference"
    else
        log_info "Successfully removed speedtest script reference"
    fi
else
    log_debug "Speedtest script reference not found in page"
fi

# Remove database directory
log_info "Checking for database directory..."
if [ -d "$DB_DIR" ]; then
    log_debug "Removing database directory..."
    if ! sudo rm -rf "$DB_DIR"; then
        log_error "Failed to remove database directory"
    else
        log_info "Successfully removed database directory"
    fi
else
    log_debug "Database directory not found at $DB_DIR"
fi

# Remove speedtest cron job if it exists
log_info "Checking for speedtest cron job..."
if [ -f "/etc/cron.d/pihole-6-speedtest" ]; then
    log_debug "Removing speedtest cron job..."
    if ! sudo rm "/etc/cron.d/pihole-6-speedtest"; then
        log_error "Failed to remove speedtest cron job"
    else
        log_info "Successfully removed speedtest cron job"
    fi
else
    log_debug "Speedtest cron job not found at /etc/cron.d/pihole-6-speedtest"
fi

# Restart Pi-hole FTL service
log_info "Restarting Pi-hole FTL service..."
if command -v systemctl &> /dev/null; then
    if ! sudo systemctl restart pihole-FTL; then
        log_error "Failed to restart Pi-hole FTL service"
    else
        log_info "Successfully restarted Pi-hole FTL service"
    fi
else
    if ! sudo service pihole-FTL restart; then
        log_error "Failed to restart Pi-hole FTL service"
    else
        log_info "Successfully restarted Pi-hole FTL service"
    fi
fi

# Print uninstallation summary
echo
if [ $UNINSTALL_ERRORS -eq 0 ]; then
    log_info "Speedtest mod uninstalled successfully!"
    log_info "Please refresh your Pi-hole web interface to see the changes."
else
    log_error "Speedtest mod uninstallation completed with $UNINSTALL_ERRORS error(s):"
    for error in "${ERROR_MESSAGES[@]}"; do
        echo "- $error"
    done
    echo
    log_info "Please check the errors above and try to resolve them manually."
    log_info "You may need to refresh your Pi-hole web interface to see partial changes."
    exit 1
fi 