#!/bin/bash

# Version information
MOD_VERSION="2.1.2"
REQUIRED_PIHOLE_VERSION="6.x"

# Initialize error tracking
INSTALL_ERRORS=0
ERROR_MESSAGES=()

# Function to log errors
log_error() {
    INSTALL_ERRORS=$((INSTALL_ERRORS + 1))
    ERROR_MESSAGES+=("$1")
    echo "Error: $1"
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

# Add speedtest widget to dashboard
if ! grep -q "speedtest" "$INDEX_FILE"; then
    echo "Adding speedtest widget to dashboard..."
    WIDGET_ADDED=0
    # Try to find a good insertion point
    if grep -q "<div class=\"row\">" "$INDEX_FILE"; then
        if sudo sed -i '/<div class="row">/ a <!-- Add Speedtest Widget -->' "$INDEX_FILE" && \
           sudo sed -i '/<!-- Add Speedtest Widget -->/ a\    <div class="col-md-6">\n      <div class="box box-primary">\n        <div class="box-header with-border">\n          <h3 class="box-title">Speedtest Results</h3>\n        </div>\n        <div class="box-body">\n          <div id="speedtest-chart"></div>\n        </div>\n      </div>\n    </div>' "$INDEX_FILE"; then
            WIDGET_ADDED=1
        fi
    elif grep -q "<div class=\"content-wrapper\">" "$INDEX_FILE"; then
        if sudo sed -i '/<div class="content-wrapper">/ a <!-- Add Speedtest Widget -->' "$INDEX_FILE" && \
           sudo sed -i '/<!-- Add Speedtest Widget -->/ a\    <div class="col-md-6">\n      <div class="box box-primary">\n        <div class="box-header with-border">\n          <h3 class="box-title">Speedtest Results</h3>\n        </div>\n        <div class="box-body">\n          <div id="speedtest-chart"></div>\n        </div>\n      </div>\n    </div>' "$INDEX_FILE"; then
            WIDGET_ADDED=1
        fi
    elif grep -q "<div class=\"container-fluid\">" "$INDEX_FILE"; then
        if sudo sed -i '/<div class="container-fluid">/ a <!-- Add Speedtest Widget -->' "$INDEX_FILE" && \
           sudo sed -i '/<!-- Add Speedtest Widget -->/ a\    <div class="col-md-6">\n      <div class="box box-primary">\n        <div class="box-header with-border">\n          <h3 class="box-title">Speedtest Results</h3>\n        </div>\n        <div class="box-body">\n          <div id="speedtest-chart"></div>\n        </div>\n      </div>\n    </div>' "$INDEX_FILE"; then
            WIDGET_ADDED=1
        fi
    fi
    if [ $WIDGET_ADDED -eq 0 ]; then
        log_error "Could not add speedtest widget to dashboard"
        echo "Please check the file structure of $INDEX_FILE"
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
        SETTINGS_ADDED=0
        # Try to find a good insertion point
        if grep -q "<div class=\"row\">" "$SETTINGS_FILE"; then
            if sudo sed -i '/<div class="row">/ a <!-- Add Speedtest Settings -->' "$SETTINGS_FILE" && \
               sudo sed -i '/<!-- Add Speedtest Settings -->/ a\    <div class="col-md-12">\n      <div class="box box-primary">\n        <div class="box-header with-border">\n          <h3 class="box-title">Speedtest Settings</h3>\n        </div>\n        <div class="box-body">\n          <div class="form-group">\n            <label for="speedtest-interval">Test Interval (hours)</label>\n            <input type="number" class="form-control" id="speedtest-interval" min="1" max="24" value="6">\n          </div>\n          <button type="button" class="btn btn-primary" id="run-speedtest">Run Speedtest Now</button>\n        </div>\n      </div>\n    </div>' "$SETTINGS_FILE"; then
                SETTINGS_ADDED=1
            fi
        elif grep -q "<div class=\"content-wrapper\">" "$SETTINGS_FILE"; then
            if sudo sed -i '/<div class="content-wrapper">/ a <!-- Add Speedtest Settings -->' "$SETTINGS_FILE" && \
               sudo sed -i '/<!-- Add Speedtest Settings -->/ a\    <div class="col-md-12">\n      <div class="box box-primary">\n        <div class="box-header with-border">\n          <h3 class="box-title">Speedtest Settings</h3>\n        </div>\n        <div class="box-body">\n          <div class="form-group">\n            <label for="speedtest-interval">Test Interval (hours)</label>\n            <input type="number" class="form-control" id="speedtest-interval" min="1" max="24" value="6">\n          </div>\n          <button type="button" class="btn btn-primary" id="run-speedtest">Run Speedtest Now</button>\n        </div>\n      </div>\n    </div>' "$SETTINGS_FILE"; then
                SETTINGS_ADDED=1
            fi
        elif grep -q "<div class=\"container-fluid\">" "$SETTINGS_FILE"; then
            if sudo sed -i '/<div class="container-fluid">/ a <!-- Add Speedtest Settings -->' "$SETTINGS_FILE" && \
               sudo sed -i '/<!-- Add Speedtest Settings -->/ a\    <div class="col-md-12">\n      <div class="box box-primary">\n        <div class="box-header with-border">\n          <h3 class="box-title">Speedtest Settings</h3>\n        </div>\n        <div class="box-body">\n          <div class="form-group">\n            <label for="speedtest-interval">Test Interval (hours)</label>\n            <input type="number" class="form-control" id="speedtest-interval" min="1" max="24" value="6">\n          </div>\n          <button type="button" class="btn btn-primary" id="run-speedtest">Run Speedtest Now</button>\n        </div>\n      </div>\n    </div>' "$SETTINGS_FILE"; then
                SETTINGS_ADDED=1
            fi
        fi
        if [ $SETTINGS_ADDED -eq 0 ]; then
            log_error "Could not add speedtest settings"
            echo "Please check the file structure of $SETTINGS_FILE"
        fi
    fi
else
    log_error "Could not find settings file"
fi

# Add speedtest script to page
if ! grep -q "speedtest.js" "$INDEX_FILE"; then
    echo "Adding speedtest script to page..."
    SCRIPT_ADDED=0
    # Try to find a good insertion point
    if grep -q "</body>" "$INDEX_FILE"; then
        if sudo sed -i '/<\/body>/ i <!-- Add Speedtest Script -->' "$INDEX_FILE" && \
           sudo sed -i '/<!-- Add Speedtest Script -->/ a\    <script src="scripts/js/speedtest.js"></script>' "$INDEX_FILE"; then
            SCRIPT_ADDED=1
        fi
    elif grep -q "<!-- REQUIRED JS SCRIPTS -->" "$INDEX_FILE"; then
        if sudo sed -i '/<!-- REQUIRED JS SCRIPTS -->/ a <!-- Add Speedtest Script -->' "$INDEX_FILE" && \
           sudo sed -i '/<!-- Add Speedtest Script -->/ a\    <script src="scripts/js/speedtest.js"></script>' "$INDEX_FILE"; then
            SCRIPT_ADDED=1
        fi
    elif grep -q "<!-- Scripts -->" "$INDEX_FILE"; then
        if sudo sed -i '/<!-- Scripts -->/ a <!-- Add Speedtest Script -->' "$INDEX_FILE" && \
           sudo sed -i '/<!-- Add Speedtest Script -->/ a\    <script src="scripts/js/speedtest.js"></script>' "$INDEX_FILE"; then
            SCRIPT_ADDED=1
        fi
    elif grep -q "<!-- Footer -->" "$INDEX_FILE"; then
        if sudo sed -i '/<!-- Footer -->/ i <!-- Add Speedtest Script -->' "$INDEX_FILE" && \
           sudo sed -i '/<!-- Add Speedtest Script -->/ a\    <script src="scripts/js/speedtest.js"></script>' "$INDEX_FILE"; then
            SCRIPT_ADDED=1
        fi
    elif grep -q "<script src=\"scripts/pi-hole/js/" "$INDEX_FILE"; then
        if sudo sed -i '/<script src="scripts\/pi-hole\/js\// a <!-- Add Speedtest Script -->' "$INDEX_FILE" && \
           sudo sed -i '/<!-- Add Speedtest Script -->/ a\    <script src="scripts/js/speedtest.js"></script>' "$INDEX_FILE"; then
            SCRIPT_ADDED=1
        fi
    elif grep -q "<script src=\"scripts/pi-hole/js/scripts.js\"" "$INDEX_FILE"; then
        if sudo sed -i '/<script src="scripts\/pi-hole\/js\/scripts.js"/ a <!-- Add Speedtest Script -->' "$INDEX_FILE" && \
           sudo sed -i '/<!-- Add Speedtest Script -->/ a\    <script src="scripts/js/speedtest.js"></script>' "$INDEX_FILE"; then
            SCRIPT_ADDED=1
        fi
    elif grep -q "<script src=\"scripts/pi-hole/js/footer.js\"" "$INDEX_FILE"; then
        if sudo sed -i '/<script src="scripts\/pi-hole\/js\/footer.js"/ a <!-- Add Speedtest Script -->' "$INDEX_FILE" && \
           sudo sed -i '/<!-- Add Speedtest Script -->/ a\    <script src="scripts/js/speedtest.js"></script>' "$INDEX_FILE"; then
            SCRIPT_ADDED=1
        fi
    elif grep -q "<script src=\"scripts/pi-hole/js/custom.js\"" "$INDEX_FILE"; then
        if sudo sed -i '/<script src="scripts\/pi-hole\/js\/custom.js"/ a <!-- Add Speedtest Script -->' "$INDEX_FILE" && \
           sudo sed -i '/<!-- Add Speedtest Script -->/ a\    <script src="scripts/js/speedtest.js"></script>' "$INDEX_FILE"; then
            SCRIPT_ADDED=1
        fi
    elif grep -q "<script src=\"scripts/pi-hole/js/network.js\"" "$INDEX_FILE"; then
        if sudo sed -i '/<script src="scripts\/pi-hole\/js\/network.js"/ a <!-- Add Speedtest Script -->' "$INDEX_FILE" && \
           sudo sed -i '/<!-- Add Speedtest Script -->/ a\    <script src="scripts/js/speedtest.js"></script>' "$INDEX_FILE"; then
            SCRIPT_ADDED=1
        fi
    elif grep -q "<script src=\"scripts/pi-hole/js/scripts.js\"" "$INDEX_FILE"; then
        if sudo sed -i '/<script src="scripts\/pi-hole\/js\/scripts.js"/ a <!-- Add Speedtest Script -->' "$INDEX_FILE" && \
           sudo sed -i '/<!-- Add Speedtest Script -->/ a\    <script src="scripts/js/speedtest.js"></script>' "$INDEX_FILE"; then
            SCRIPT_ADDED=1
        fi
    elif grep -q "<script src=\"scripts/pi-hole/js/gravity.js\"" "$INDEX_FILE"; then
        if sudo sed -i '/<script src="scripts\/pi-hole\/js\/gravity.js"/ a <!-- Add Speedtest Script -->' "$INDEX_FILE" && \
           sudo sed -i '/<!-- Add Speedtest Script -->/ a\    <script src="scripts/js/speedtest.js"></script>' "$INDEX_FILE"; then
            SCRIPT_ADDED=1
        fi
    elif grep -q "<script src=\"scripts/pi-hole/js/whitelist.js\"" "$INDEX_FILE"; then
        if sudo sed -i '/<script src="scripts\/pi-hole\/js\/whitelist.js"/ a <!-- Add Speedtest Script -->' "$INDEX_FILE" && \
           sudo sed -i '/<!-- Add Speedtest Script -->/ a\    <script src="scripts/js/speedtest.js"></script>' "$INDEX_FILE"; then
            SCRIPT_ADDED=1
        fi
    elif grep -q "<script src=\"scripts/pi-hole/js/blacklist.js\"" "$INDEX_FILE"; then
        if sudo sed -i '/<script src="scripts\/pi-hole\/js\/blacklist.js"/ a <!-- Add Speedtest Script -->' "$INDEX_FILE" && \
           sudo sed -i '/<!-- Add Speedtest Script -->/ a\    <script src="scripts/js/speedtest.js"></script>' "$INDEX_FILE"; then
            SCRIPT_ADDED=1
        fi
    elif grep -q "<script src=\"scripts/pi-hole/js/domains.js\"" "$INDEX_FILE"; then
        if sudo sed -i '/<script src="scripts\/pi-hole\/js\/domains.js"/ a <!-- Add Speedtest Script -->' "$INDEX_FILE" && \
           sudo sed -i '/<!-- Add Speedtest Script -->/ a\    <script src="scripts/js/speedtest.js"></script>' "$INDEX_FILE"; then
            SCRIPT_ADDED=1
        fi
    elif grep -q "<script src=\"scripts/pi-hole/js/ads.js\"" "$INDEX_FILE"; then
        if sudo sed -i '/<script src="scripts\/pi-hole\/js\/ads.js"/ a <!-- Add Speedtest Script -->' "$INDEX_FILE" && \
           sudo sed -i '/<!-- Add Speedtest Script -->/ a\    <script src="scripts/js/speedtest.js"></script>' "$INDEX_FILE"; then
            SCRIPT_ADDED=1
        fi
    fi
    if [ $SCRIPT_ADDED -eq 0 ]; then
        log_error "Could not add speedtest script to page"
        echo "Please check the file structure of $INDEX_FILE"
        echo "You can manually add the following line to the file:"
        echo '    <script src="scripts/js/speedtest.js"></script>'
        echo
        echo "Common insertion points to try:"
        echo "1. Before the closing </body> tag"
        echo "2. After any existing <script> tag"
        echo "3. After <!-- REQUIRED JS SCRIPTS -->"
        echo "4. After <!-- Scripts -->"
        echo "5. Before <!-- Footer -->"
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
    fi
else
    if ! sudo service pihole-FTL restart; then
        log_error "Failed to restart Pi-hole FTL service"
    fi
fi

# Print installation summary
echo
if [ $INSTALL_ERRORS -eq 0 ]; then
    echo "Speedtest mod installed successfully!"
    echo "Please refresh your Pi-hole web interface to see the changes."
else
    echo "Speedtest mod installation completed with $INSTALL_ERRORS error(s):"
    for error in "${ERROR_MESSAGES[@]}"; do
        echo "- $error"
    done
    echo
    echo "Please check the errors above and try to resolve them manually."
    echo "You may need to refresh your Pi-hole web interface to see partial changes."
    exit 1
fi