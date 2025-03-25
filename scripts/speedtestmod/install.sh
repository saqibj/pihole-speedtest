#!/bin/bash

# Version information
MOD_VERSION="2.1.3"
REQUIRED_PIHOLE_VERSION="6.x"

# Initialize error tracking
INSTALL_ERRORS=0
ERROR_MESSAGES=()

# Initialize rollback tracking
ROLLBACK_STEPS=()
ROLLBACK_SUCCESS=1

# Function to log errors
log_error() {
    INSTALL_ERRORS=$((INSTALL_ERRORS + 1))
    ERROR_MESSAGES+=("$1")
    echo "Error: $1"
}

# Function to add rollback step
add_rollback_step() {
    ROLLBACK_STEPS+=("$1")
}

# Function to execute rollback
execute_rollback() {
    log_info "Starting rollback due to installation failure..."
    for step in "${ROLLBACK_STEPS[@]}"; do
        log_info "Executing rollback step: $step"
        eval "$step"
    done
    log_info "Rollback completed"
}

# Check if Pi-hole is installed
if ! command -v pihole &> /dev/null; then
    log_error "Pi-hole is not installed. Please install Pi-hole first."
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
    log_error "This mod (v${MOD_VERSION}) is designed for Pi-hole ${REQUIRED_PIHOLE_VERSION}. Your version is $PIHOLE_VERSION"
    exit 1
fi

# Define paths
PIHOLE_DIR="/etc/.pihole"
WEB_DIR="/var/www/html/admin"
DB_DIR="/etc/pihole/pihole-6-speedtest"

# Verify SCRIPT_DIR is set
if [ -z "$SCRIPT_DIR" ]; then
    log_error "SCRIPT_DIR environment variable is not set"
    exit 1
fi

# Install speedtest CLI if not present
if ! command -v speedtest &> /dev/null; then
    echo "Installing speedtest CLI..."
    if ! curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash; then
        log_error "Failed to add speedtest repository"
    fi
    if ! sudo apt-get install -y speedtest; then
        log_error "Failed to install speedtest CLI"
    fi
fi

# Create database directory with proper permissions
if [ ! -d "$DB_DIR" ]; then
    echo "Creating database directory..."
    if ! sudo mkdir -p "$DB_DIR"; then
        log_error "Failed to create database directory"
    fi
    if ! sudo chown www-data:www-data "$DB_DIR"; then
        log_error "Failed to set database directory ownership"
    fi
    if ! sudo chmod 755 "$DB_DIR"; then
        log_error "Failed to set database directory permissions"
    fi
fi

# Copy speedtest script
echo "Installing speedtest script..."
if ! sudo cp "$SCRIPT_DIR/speedtest.sh" /usr/local/bin/pihole-6-speedtest; then
    log_error "Failed to copy speedtest script"
fi
if ! sudo chmod +x /usr/local/bin/pihole-6-speedtest; then
    log_error "Failed to set speedtest script permissions"
fi

# Find Pi-hole web interface directory
if [ ! -d "$WEB_DIR" ]; then
    echo "Looking for Pi-hole web interface directory..."
    # Try common locations
    for dir in "/var/www/html/admin" "/var/www/html/pihole" "/var/www/pihole" "/var/www/html" "/var/www/html/pihole/admin" "/var/www/html/pihole"; do
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

# Create web interface files
echo "Installing web interface files..."
if ! sudo mkdir -p "$WEB_DIR/scripts/js/"; then
    log_error "Failed to create JavaScript directory"
fi
if ! sudo mkdir -p "$WEB_DIR/style/"; then
    log_error "Failed to create style directory"
fi
if ! sudo cp "$SCRIPT_DIR/speedtest.js" "$WEB_DIR/scripts/js/"; then
    log_error "Failed to copy JavaScript file"
fi
if ! sudo cp "$SCRIPT_DIR/speedtest.css" "$WEB_DIR/style/"; then
    log_error "Failed to copy CSS file"
fi

# Find index file
INDEX_FILE=""
for file in "index.php" "index.lp" "index.html" "index.tlp"; do
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

# Verify and add navigation menu item
log_info "Verifying navigation menu structure..."
if grep -q "<\/ul>" "$WEB_DIR/scripts/pi-hole/php/sidebar.php"; then
    log_info "Found valid navigation menu insertion point"
    NAV_MARKER="<!-- Add Speedtest Settings Menu -->"
    NAV_ITEM="\n<li><a href=\"scripts/pi-hole/php/speedtest-settings.php\"><i class=\"fa fa-tachometer\"></i> Speedtest Settings</a></li>\n"
    
    # Add rollback step
    add_rollback_step "sudo sed -i '/$NAV_MARKER/d' '$WEB_DIR/scripts/pi-hole/php/sidebar.php'"
    
    if ! sudo sed -i "/$NAV_MARKER/!s/<\/ul>/&$NAV_ITEM/" "$WEB_DIR/scripts/pi-hole/php/sidebar.php"; then
        log_error "Failed to add speedtest settings menu item"
        execute_rollback
        exit 1
    else
        log_info "Successfully added speedtest settings menu item"
    fi
else
    log_error "Could not find valid navigation menu insertion point"
    exit 1
fi

# Verify and add widget
log_info "Verifying dashboard structure..."
if grep -q "<div class=\"row\" id=\"widgets\">" "$INDEX_FILE"; then
    log_info "Found valid widget insertion point"
    WIDGET_MARKER="<!-- Add Speedtest Widget -->"
    WIDGET_CONTENT="\n<div class=\"col-md-6\">\n    <div class=\"box\" id=\"speedtest-results\">\n        <div class=\"box-header with-border\">\n            <h3 class=\"box-title\">Speedtest Results</h3>\n        </div>\n        <div class=\"box-body\">\n            <div class=\"chart\">\n                <canvas id=\"speedtest-chart\" style=\"height: 300px;\"></canvas>\n            </div>\n            <div class=\"speedtest-stats\"></div>\n        </div>\n    </div>\n</div>\n"
    
    # Add rollback step
    add_rollback_step "sudo sed -i '/$WIDGET_MARKER/d' '$INDEX_FILE'"
    
    if ! sudo sed -i "/$WIDGET_MARKER/!s/<div class=\"row\" id=\"widgets\">/&$WIDGET_CONTENT/" "$INDEX_FILE"; then
        log_error "Failed to add speedtest widget to dashboard"
        execute_rollback
        exit 1
    else
        log_info "Successfully added speedtest widget to dashboard"
    fi
else
    log_error "Could not find valid widget insertion point"
    execute_rollback
    exit 1
fi

# Verify and add script reference
log_info "Verifying head section structure..."
if grep -q "<\/head>" "$INDEX_FILE"; then
    log_info "Found valid script reference insertion point"
    SCRIPT_MARKER="<!-- Add Speedtest Script -->"
    SCRIPT_CONTENT="\n<script src=\"<?=pihole.fileversion('scripts/js/speedtest.js')?>\"></script>\n"
    
    # Add rollback step
    add_rollback_step "sudo sed -i '/$SCRIPT_MARKER/d' '$INDEX_FILE'"
    
    if ! sudo sed -i "/$SCRIPT_MARKER/!s/<\/head>/&$SCRIPT_CONTENT/" "$INDEX_FILE"; then
        log_error "Failed to add speedtest script reference"
        execute_rollback
        exit 1
    else
        log_info "Successfully added speedtest script reference"
    fi
else
    log_error "Could not find valid script reference insertion point"
    execute_rollback
    exit 1
fi

# Verify and create settings page
log_info "Verifying settings page location..."
if [ -d "$WEB_DIR/scripts/pi-hole/php" ]; then
    log_info "Found valid settings page location"
    
    # Add rollback step
    add_rollback_step "sudo rm -f '$WEB_DIR/scripts/pi-hole/php/speedtest-settings.php'"
    
    if ! sudo cp "$SCRIPT_DIR/speedtest-settings.php" "$WEB_DIR/scripts/pi-hole/php/speedtest-settings.php"; then
        log_error "Failed to create speedtest settings page"
        execute_rollback
        exit 1
    else
        log_info "Successfully created speedtest settings page"
    fi
else
    log_error "Could not find valid settings page location"
    execute_rollback
    exit 1
fi

# Find settings file
SETTINGS_FILE="$WEB_DIR/scripts/pi-hole/php/speedtest-settings.php"

# Verify and add speedtest settings
log_info "Checking for existing speedtest settings..."
if grep -q "speedtest-settings" "$SETTINGS_FILE"; then
    log_info "Speedtest settings already exist"
else
    log_info "Adding speedtest settings..."
    SETTINGS_MARKER="<!-- Add Speedtest Settings -->"
    SETTINGS_CONTENT="\n<div class=\"speedtest-settings\">\n    <h3>Speedtest Settings</h3>\n    <div class=\"form-group\">\n        <label for=\"speedtest-interval\">Test Interval (hours):</label>\n        <input type=\"number\" class=\"form-control\" id=\"speedtest-interval\" min=\"1\" max=\"24\" value=\"6\">\n    </div>\n</div>\n"
    
    if ! sudo sed -i "/$SETTINGS_MARKER/!s/<!-- Add Settings Here -->/&$SETTINGS_CONTENT/" "$SETTINGS_FILE"; then
        log_error "Failed to add speedtest settings"
    else
        log_info "Successfully added speedtest settings"
    fi
fi

# Set proper permissions
echo "Setting proper permissions..."
if ! sudo chown -R www-data:www-data "$WEB_DIR/scripts/js/speedtest.js"; then
    log_error "Failed to set JavaScript file ownership"
fi
if ! sudo chown -R www-data:www-data "$WEB_DIR/style/speedtest.css"; then
    log_error "Failed to set CSS file ownership"
fi
if ! sudo chmod 644 "$WEB_DIR/scripts/js/speedtest.js"; then
    log_error "Failed to set JavaScript file permissions"
fi
if ! sudo chmod 644 "$WEB_DIR/style/speedtest.css"; then
    log_error "Failed to set CSS file permissions"
fi

# Restart Pi-hole FTL service
echo "Restarting Pi-hole FTL service..."
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

# Print installation summary
echo
if [ $INSTALL_ERRORS -eq 0 ]; then
    log_info "Speedtest mod installed successfully!"
    log_info "Please refresh your Pi-hole web interface to see the changes."
else
    log_error "Speedtest mod installation completed with $INSTALL_ERRORS error(s):"
    for error in "${ERROR_MESSAGES[@]}"; do
        log_error "- $error"
    done
    log_info "Please check the errors above and try to resolve them manually."
    log_info "You may need to refresh your Pi-hole web interface to see partial changes."
    execute_rollback
    exit 1
fi