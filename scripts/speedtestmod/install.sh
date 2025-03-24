#!/bin/bash

# Version information
MOD_VERSION="2.0.0"
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

# Create web interface files
echo "Installing web interface files..."
sudo mkdir -p "$WEB_DIR/scripts/js/"
sudo mkdir -p "$WEB_DIR/style/"
sudo cp "$SCRIPT_DIR/speedtest.js" "$WEB_DIR/scripts/js/"
sudo cp "$SCRIPT_DIR/speedtest.css" "$WEB_DIR/style/"

# Add speedtest widget to dashboard
if ! grep -q "speedtest" "$WEB_DIR/index.php"; then
    echo "Adding speedtest widget to dashboard..."
    sudo sed -i '/<div class="row">/ a <!-- Add Speedtest Widget -->' "$WEB_DIR/index.php"
    sudo sed -i '/<!-- Add Speedtest Widget -->/ a\    <div class="col-md-6">\n      <div class="box box-primary">\n        <div class="box-header with-border">\n          <h3 class="box-title">Speedtest Results</h3>\n        </div>\n        <div class="box-body">\n          <div id="speedtest-chart"></div>\n        </div>\n      </div>\n    </div>' "$WEB_DIR/index.php"
fi

# Add speedtest settings to system settings
if ! grep -q "speedtest" "$WEB_DIR/settings.php"; then
    echo "Adding speedtest settings..."
    sudo sed -i '/<div class="col-md-12">/ a <!-- Add Speedtest Settings -->' "$WEB_DIR/settings.php"
    sudo sed -i '/<!-- Add Speedtest Settings -->/ a\    <div class="box box-primary">\n      <div class="box-header with-border">\n        <h3 class="box-title">Speedtest Settings</h3>\n      </div>\n      <div class="box-body">\n        <div class="form-group">\n          <label for="speedtest-interval">Test Interval (hours)</label>\n          <input type="number" class="form-control" id="speedtest-interval" min="1" max="24" value="6">\n        </div>\n        <button type="button" class="btn btn-primary" id="run-speedtest">Run Speedtest Now</button>\n      </div>\n    </div>' "$WEB_DIR/settings.php"
fi

# Add speedtest script to page
if ! grep -q "speedtest.js" "$WEB_DIR/index.php"; then
    echo "Adding speedtest script to page..."
    sudo sed -i '/<\/body>/ i <!-- Add Speedtest Script -->' "$WEB_DIR/index.php"
    sudo sed -i '/<!-- Add Speedtest Script -->/ a\    <script src="scripts/js/speedtest.js"></script>' "$WEB_DIR/index.php"
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