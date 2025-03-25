# PiHole 6 Speedtest

![Speedtest Chart](https://raw.githubusercontent.com/arevindh/AdminLTE/master/img/st-chart.png)

[![Version](https://img.shields.io/badge/version-2.1.3-blue.svg)](https://github.com/saqibj/pihole-speedtest/releases)
[![Pi-hole Version](https://img.shields.io/badge/Pi--hole-6.x-blue)](https://pi-hole.net/)
[![Shell Script](https://img.shields.io/badge/Shell_Script-%23121011.svg?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![JavaScript](https://img.shields.io/badge/JavaScript-F7DF1E?logo=javascript&logoColor=black)](https://developer.mozilla.org/en-US/docs/Web/JavaScript)
[![PHP](https://img.shields.io/badge/PHP-777BB4?logo=php&logoColor=white)](https://www.php.net/)
[![SQLite](https://img.shields.io/badge/SQLite-07405E?logo=sqlite&logoColor=white)](https://www.sqlite.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/saqibj/pihole-speedtest/blob/main/LICENSE)

A Pi-hole extension that adds speedtest functionality directly to your Pi-hole dashboard. This mod allows you to monitor your network speed over time, run tests on demand, and view historical data through a beautiful web interface.

## Features

- Run speedtests directly from the Pi-hole web interface
- Automatic speedtest scheduling with configurable intervals
- Beautiful charts showing download and upload speeds over time
- Historical data storage in SQLite database
- Real-time speedtest results display
- Mobile-responsive design
- Easy installation and configuration
- Automatic web interface detection
- Enhanced error handling and user feedback
- Detailed installation progress and error reporting
- Clean uninstallation process

## Requirements
- Pi-hole v6.x
- Debian, Fedora, or derivatives
- Docker support (optional)

## Installation

### Quick Install

```bash
curl -sSL https://raw.githubusercontent.com/saqibj/pihole-speedtest/v2.1.3/mod | sudo bash
```

### Manual Installation

1. Clone this repository:
```bash
git clone https://github.com/saqibj/pihole-speedtest.git
cd pihole-speedtest
```

2. Run the installation script:
```bash
sudo ./mod
```

### Docker Installation

You can use the provided Docker image:

```bash
docker run -d \
    --name pihole \
    -p 53:53/tcp -p 53:53/udp \
    -p 80:80 \
    -e TZ=America/Chicago \
    -v "$(pwd)/etc-pihole:/etc/pihole" \
    -v "$(pwd)/etc-dnsmasq.d:/etc/dnsmasq.d" \
    --restart=unless-stopped \
    ghcr.io/saqibj/pihole-speedtest:pihole-6
```

## Uninstallation

### Quick Uninstall

```bash
curl -sSL https://raw.githubusercontent.com/saqibj/pihole-speedtest/v2.1.3/scripts/speedtestmod/uninstall.sh | sudo bash
```

### Manual Uninstallation

1. Navigate to the mod directory:
```bash
cd pihole-speedtest
```

2. Run the uninstallation script:
```bash
sudo bash scripts/speedtestmod/uninstall.sh
```

The uninstallation script will:
- Remove all mod files and configurations
- Clean up web interface modifications
- Remove the speedtest database
- Remove the cron job
- Restart Pi-hole FTL service

If you encounter any errors during uninstallation, the script will provide detailed information about what went wrong and how to resolve it.

### Manual Cleanup

If the automatic uninstallation fails, you can manually remove the mod:

1. Remove the mod files:
```bash
sudo rm /var/www/html/admin/scripts/js/speedtest.js
sudo rm /var/www/html/admin/style/speedtest.css
sudo rm /usr/local/bin/pihole-6-speedtest
```

2. Remove the database directory:
```bash
sudo rm -rf /etc/pihole/pihole-6-speedtest
```

3. Remove the cron job:
```bash
sudo rm /etc/cron.d/pihole-6-speedtest
```

4. Restart Pi-hole FTL:
```bash
sudo systemctl restart pihole-FTL
```

## Usage

### Running a Speedtest

1. Open your Pi-hole web interface
2. Navigate to the Dashboard
3. Click the "Run Speedtest Now" button in the Speedtest widget
4. Wait for the test to complete
5. View your results in the chart

### Configuring the Speedtest

1. Go to Settings > System
2. Find the Speedtest Settings section
3. Set your desired test interval (in hours)
4. Click Save

### Viewing Results

- The Speedtest widget on the Dashboard shows:
  - Current download speed
  - Current upload speed
  - Ping time
  - Test server
  - Historical data chart

## File Structure

```