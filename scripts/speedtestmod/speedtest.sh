#!/bin/bash

# Define database file path
DB_DIR="/etc/pihole/pihole-6-speedtest"
DB_FILE="$DB_DIR/speedtest.db"

# Ensure database directory exists with proper permissions
if [ ! -d "$DB_DIR" ]; then
    echo "Error: Database directory does not exist"
    exit 1
fi

# Check if database exists
if [ ! -f "$DB_FILE" ]; then
    echo "Creating new database..."
    sqlite3 "$DB_FILE" "
        CREATE TABLE IF NOT EXISTS speedtest (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            download REAL,
            upload REAL,
            ping REAL,
            server TEXT,
            ip TEXT,
            location TEXT
        );
    "
    chown pihole:pihole "$DB_FILE"
    chmod 644 "$DB_FILE"
fi

# Check if speedtest is installed
if ! command -v speedtest &> /dev/null; then
    echo "Speedtest CLI is not installed. Please install it first."
    exit 1
fi

# Run speedtest with detailed output
echo "Running speedtest..."
result=$(speedtest --format=json-pretty)

# Check if speedtest was successful
if [ $? -ne 0 ]; then
    echo "Error: Speedtest failed"
    exit 1
fi

# Extract values using jq
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Please install it first."
    exit 1
fi

# Extract detailed values
download=$(echo "$result" | jq -r '.download.bandwidth * 8 / 1000000')
upload=$(echo "$result" | jq -r '.upload.bandwidth * 8 / 1000000')
ping=$(echo "$result" | jq -r '.ping.latency')
server=$(echo "$result" | jq -r '.server.name')
ip=$(echo "$result" | jq -r '.server.ip')
location=$(echo "$result" | jq -r '.server.location')

# Check if values were extracted successfully
if [ -z "$download" ] || [ -z "$upload" ] || [ -z "$ping" ] || [ -z "$server" ]; then
    echo "Error: Failed to extract speedtest results"
    exit 1
fi

# Save to database
if ! sqlite3 "$DB_FILE" "
    INSERT INTO speedtest (download, upload, ping, server, ip, location) 
    VALUES ($download, $upload, $ping, '$server', '$ip', '$location');
"; then
    echo "Error: Failed to save results to database"
    exit 1
fi

# Output results in JSON format for Pi-hole v6 API
echo "{
    \"success\": true,
    \"data\": {
        \"download\": \"$download\",
        \"upload\": \"$upload\",
        \"ping\": \"$ping\",
        \"server\": \"$server\",
        \"ip\": \"$ip\",
        \"location\": \"$location\"
    }
}"