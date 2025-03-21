#!/bin/bash

# Database file
DB_FILE="/etc/pihole/speedtest/speedtest.db"

# Create database if it doesn't exist
if [ ! -f "$DB_FILE" ]; then
    sqlite3 "$DB_FILE" "CREATE TABLE speedtest (id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, download REAL, upload REAL, ping REAL, server TEXT);"
fi

# Run speedtest
echo "Running speedtest..."
result=$(speedtest --format=json)

# Extract values
download=$(echo "$result" | jq -r '.download.bandwidth * 8 / 1000000')
upload=$(echo "$result" | jq -r '.upload.bandwidth * 8 / 1000000')
ping=$(echo "$result" | jq -r '.ping.latency')
server=$(echo "$result" | jq -r '.server.name')

# Save to database
sqlite3 "$DB_FILE" "INSERT INTO speedtest (download, upload, ping, server) VALUES ($download, $upload, $ping, '$server');"

# Output results
echo "Speedtest completed:"
echo "Download: ${download} Mbps"
echo "Upload: ${upload} Mbps"
echo "Ping: ${ping} ms"
echo "Server: ${server}" 