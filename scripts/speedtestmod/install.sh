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

# Verify Pi-hole v6 is installed
if ! pihole-FTL --version | grep -q "v6"; then
    log_error "This mod requires Pi-hole v6. Please upgrade Pi-hole first."
    exit 1
fi

# Define paths
PIHOLE_DIR="/etc/.pihole"
WEB_DIR="/var/www/html/admin"
DB_DIR="/etc/pihole/pihole-6-speedtest"

# Create database directory with proper permissions
if [ ! -d "$DB_DIR" ]; then
    echo "Creating database directory..."
    if ! sudo mkdir -p "$DB_DIR"; then
        log_error "Failed to create database directory"
    fi
    if ! sudo chown pihole:pihole "$DB_DIR"; then
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

# Update web interface integration
WEB_UI_FILE="$WEB_DIR/index.lp"
if [ ! -f "$WEB_UI_FILE" ]; then
    log_error "Pi-hole v6 web interface file not found"
    exit 1
fi

# Add speedtest widget to Pi-hole v6's widget system
WIDGET_CONTENT="
<div class=\"col-md-6\">
    <div class=\"card\">
        <div class=\"card-header\">
            <h3 class=\"card-title\">Speedtest Results</h3>
        </div>
        <div class=\"card-body\">
            <div class=\"chart\">
                <canvas id=\"speedtest-chart\" style=\"height: 300px;\"></canvas>
            </div>
            <div class=\"speedtest-stats\"></div>
        </div>
    </div>
</div>
"

# Add widget to Pi-hole v6's widget area
if ! sudo sed -i '/<div class="row" id="widgets">/a\$WIDGET_CONTENT' "$WEB_UI_FILE"; then
    log_error "Failed to add speedtest widget to web interface"
fi

# Add speedtest.js to Pi-hole v6's asset pipeline
JS_FILE="$WEB_DIR/js/speedtest.js"
sudo cp "$SCRIPT_DIR/speedtest.js" "$JS_FILE"
if ! sudo chmod 644 "$JS_FILE"; then
    log_error "Failed to set speedtest.js permissions"
fi

# Add speedtest.css to Pi-hole v6's asset pipeline
CSS_FILE="$WEB_DIR/css/speedtest.css"
sudo cp "$SCRIPT_DIR/speedtest.css" "$CSS_FILE"
if ! sudo chmod 644 "$CSS_FILE"; then
    log_error "Failed to set speedtest.css permissions"
fi

# Add speedtest API endpoint to Pi-hole v6's API
API_FILE="$WEB_DIR/api.php"
API_CONTENT="
<?php
require_once __DIR__ . '/vendor/autoload.php';
use PiHole\FTL\Api;

// Speedtest API endpoint
if (isset($_GET['speedtest'])) {
    try {
        $api = new Api();
        $db = $api->getDb();
        
        if ($_GET['speedtest'] === 'run') {
            // Run speedtest and save results
            $result = shell_exec('/usr/local/bin/pihole-6-speedtest');
            echo json_encode(['success' => true, 'message' => $result]);
        } else {
            // Get historical data
            $stmt = $db->prepare('SELECT * FROM speedtest ORDER BY timestamp DESC LIMIT 100');
            $stmt->execute();
            $results = $stmt->fetchAll(PDO::FETCH_ASSOC);
            echo json_encode($results);
        }
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
    exit;
}
?>
"

if ! sudo sed -i '/<?php/a\$API_CONTENT' "$API_FILE"; then
    log_error "Failed to add speedtest API endpoint"
fi

# Restart Pi-hole FTL service
if ! sudo systemctl restart pihole-FTL; then
    log_error "Failed to restart Pi-hole FTL service"
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