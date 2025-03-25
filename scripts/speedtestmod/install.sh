#!/bin/bash

# Version information
MOD_VERSION="2.1.0"
REQUIRED_PIHOLE_VERSION="6.x"

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
    echo "This mod (v${MOD_VERSION}) is designed for Pi-hole ${REQUIRED_PIHOLE_VERSION}. Your version is $PIHOLE_VERSION"
    exit 1
fi

# Define paths
PIHOLE_DIR="/etc/.pihole"
WEB_DIR="/var/www/html/admin"
DB_DIR="/etc/pihole/pihole-6-speedtest"

# Verify SCRIPT_DIR is set
if [ -z "$SCRIPT_DIR" ]; then
    echo "Error: SCRIPT_DIR environment variable is not set"
    exit 1
fi

# Install speedtest CLI if not present
if ! command -v speedtest &> /dev/null; then
    echo "Installing speedtest CLI..."
    curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
    sudo apt-get install speedtest
fi

# Create database directory with proper permissions
if [ ! -d "$DB_DIR" ]; then
    echo "Creating database directory..."
    sudo mkdir -p "$DB_DIR"
    sudo chown www-data:www-data "$DB_DIR"
    sudo chmod 755 "$DB_DIR"
fi

# Copy speedtest script
echo "Installing speedtest script..."
sudo cp "$SCRIPT_DIR/speedtest.sh" /usr/local/bin/pihole-6-speedtest
sudo chmod +x /usr/local/bin/pihole-6-speedtest

# Find Pi-hole web interface directory
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
    echo "Error: Could not find Pi-hole web interface directory"
    echo "Please ensure Pi-hole is properly installed"
    exit 1
fi

# Create web interface files
echo "Installing web interface files..."
sudo mkdir -p "$WEB_DIR/scripts/js/"
sudo mkdir -p "$WEB_DIR/style/"
sudo cp "$SCRIPT_DIR/speedtest.js" "$WEB_DIR/scripts/js/"
sudo cp "$SCRIPT_DIR/speedtest.css" "$WEB_DIR/style/"

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
    echo "Error: Could not find index file in web interface directory"
    exit 1
fi

# Add speedtest widget to dashboard
if ! grep -q "speedtest" "$INDEX_FILE"; then
    echo "Adding speedtest widget to dashboard..."
    # Try to find a good insertion point
    if grep -q "<!-- Content Wrapper. Contains page content -->" "$INDEX_FILE"; then
        sudo sed -i '/<!-- Content Wrapper. Contains page content -->/ a <!-- Add Speedtest Widget -->' "$INDEX_FILE"
        sudo sed -i '/<!-- Add Speedtest Widget -->/ a\    <div class="col-md-6">\n      <div class="box box-primary">\n        <div class="box-header with-border">\n          <h3 class="box-title">Speedtest Results</h3>\n        </div>\n        <div class="box-body">\n          <div id="speedtest-chart"></div>\n        </div>\n      </div>\n    </div>' "$INDEX_FILE"
    elif grep -q "<div class=\"content-wrapper\">" "$INDEX_FILE"; then
        sudo sed -i '/<div class="content-wrapper">/ a <!-- Add Speedtest Widget -->' "$INDEX_FILE"
        sudo sed -i '/<!-- Add Speedtest Widget -->/ a\    <div class="col-md-6">\n      <div class="box box-primary">\n        <div class="box-header with-border">\n          <h3 class="box-title">Speedtest Results</h3>\n        </div>\n        <div class="box-body">\n          <div id="speedtest-chart"></div>\n        </div>\n      </div>\n    </div>' "$INDEX_FILE"
    else
        echo "Warning: Could not find suitable insertion point for widget"
    fi
fi

# Find settings file
SETTINGS_FILE=""
for file in "settings.php" "settings-system.php" "settings-system.lp"; do
    if [ -f "$WEB_DIR/$file" ]; then
        SETTINGS_FILE="$WEB_DIR/$file"
        echo "Found settings file: $SETTINGS_FILE"
        break
    fi
done

if [ -n "$SETTINGS_FILE" ]; then
    # Add speedtest settings to system settings
    if ! grep -q "speedtest" "$SETTINGS_FILE"; then
        echo "Adding speedtest settings..."
        # Try to find a good insertion point
        if grep -q "<!-- Content Wrapper. Contains page content -->" "$SETTINGS_FILE"; then
            sudo sed -i '/<!-- Content Wrapper. Contains page content -->/ a <!-- Add Speedtest Settings -->' "$SETTINGS_FILE"
            sudo sed -i '/<!-- Add Speedtest Settings -->/ a\    <div class="box box-primary">\n      <div class="box-header with-border">\n        <h3 class="box-title">Speedtest Settings</h3>\n      </div>\n      <div class="box-body">\n        <div class="form-group">\n          <label for="speedtest-interval">Test Interval (hours)</label>\n          <input type="number" class="form-control" id="speedtest-interval" min="1" max="24" value="6">\n        </div>\n        <button type="button" class="btn btn-primary" id="run-speedtest">Run Speedtest Now</button>\n      </div>\n    </div>' "$SETTINGS_FILE"
        elif grep -q "<div class=\"content-wrapper\">" "$SETTINGS_FILE"; then
            sudo sed -i '/<div class="content-wrapper">/ a <!-- Add Speedtest Settings -->' "$SETTINGS_FILE"
            sudo sed -i '/<!-- Add Speedtest Settings -->/ a\    <div class="box box-primary">\n      <div class="box-header with-border">\n        <h3 class="box-title">Speedtest Settings</h3>\n      </div>\n      <div class="box-body">\n        <div class="form-group">\n          <label for="speedtest-interval">Test Interval (hours)</label>\n          <input type="number" class="form-control" id="speedtest-interval" min="1" max="24" value="6">\n        </div>\n        <button type="button" class="btn btn-primary" id="run-speedtest">Run Speedtest Now</button>\n      </div>\n    </div>' "$SETTINGS_FILE"
        else
            echo "Warning: Could not find suitable insertion point for settings"
        fi
    fi
else
    echo "Warning: Could not find settings file"
fi

# Add speedtest script to page
if ! grep -q "speedtest.js" "$INDEX_FILE"; then
    echo "Adding speedtest script to page..."
    if grep -q "</body>" "$INDEX_FILE"; then
        sudo sed -i '/<\/body>/ i <!-- Add Speedtest Script -->' "$INDEX_FILE"
        sudo sed -i '/<!-- Add Speedtest Script -->/ a\    <script src="scripts/js/speedtest.js"></script>' "$INDEX_FILE"
    elif grep -q "<!-- REQUIRED JS SCRIPTS -->" "$INDEX_FILE"; then
        sudo sed -i '/<!-- REQUIRED JS SCRIPTS -->/ a <!-- Add Speedtest Script -->' "$INDEX_FILE"
        sudo sed -i '/<!-- Add Speedtest Script -->/ a\    <script src="scripts/js/speedtest.js"></script>' "$INDEX_FILE"
    else
        echo "Warning: Could not find suitable insertion point for script"
    fi
fi

# Set proper permissions
echo "Setting proper permissions..."
sudo chown -R www-data:www-data "$WEB_DIR/scripts/js/speedtest.js"
sudo chown -R www-data:www-data "$WEB_DIR/style/speedtest.css"
sudo chmod 644 "$WEB_DIR/scripts/js/speedtest.js"
sudo chmod 644 "$WEB_DIR/style/speedtest.css"

# Restart Pi-hole FTL service
echo "Restarting Pi-hole FTL service..."
if command -v systemctl &> /dev/null; then
    sudo systemctl restart pihole-FTL
else
    sudo service pihole-FTL restart
fi

echo "Speedtest mod installed successfully!"
echo "Please refresh your Pi-hole web interface to see the changes."