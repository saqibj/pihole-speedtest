#!/bin/bash

# Define database file path
DB_DIR="/etc/pihole/pihole-6-speedtest"
DB_FILE="$DB_DIR/speedtest.db"

# Ensure database directory exists with proper permissions
if [ ! -d "$DB_DIR" ]; then
    echo "Error: Database directory does not exist"
    exit 1
fi

# Create database if it doesn't exist
if [ ! -f "$DB_FILE" ]; then
    echo "Creating new database..."
    sqlite3 "$DB_FILE" "CREATE TABLE speedtest (id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, download REAL, upload REAL, ping REAL, server TEXT);"
    chown www-data:www-data "$DB_FILE"
    chmod 644 "$DB_FILE"
fi

# Run speedtest
echo "Running speedtest..."
result=$(speedtest --format=json)

# Check if speedtest was successful
if [ $? -ne 0 ]; then
    echo "Error: Speedtest failed"
    exit 1
fi

# Extract values
download=$(echo "$result" | jq -r '.download.bandwidth * 8 / 1000000')
upload=$(echo "$result" | jq -r '.upload.bandwidth * 8 / 1000000')
ping=$(echo "$result" | jq -r '.ping.latency')
server=$(echo "$result" | jq -r '.server.name')

# Check if values were extracted successfully
if [ -z "$download" ] || [ -z "$upload" ] || [ -z "$ping" ] || [ -z "$server" ]; then
    echo "Error: Failed to extract speedtest results"
    exit 1
fi

# Save to database
if ! sqlite3 "$DB_FILE" "INSERT INTO speedtest (download, upload, ping, server) VALUES ($download, $upload, $ping, '$server');"; then
    echo "Error: Failed to save results to database"
    exit 1
fi

# Output results
echo "Speedtest completed:"
echo "Download: ${download} Mbps"
echo "Upload: ${upload} Mbps"
echo "Ping: ${ping} ms"
echo "Server: ${server}" 