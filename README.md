# PiHole 6 Speedtest

![Speedtest Chart](https://raw.githubusercontent.com/arevindh/AdminLTE/master/img/st-chart.png)

[![Join the chat at https://gitter.im/pihole-6-speedtest/community](https://badges.gitter.im/pihole-6-speedtest/community.svg)](https://gitter.im/pihole-6-speedtest/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) [![Discord](https://badgen.net/badge/icon/discord?icon=discord&label)](https://discord.gg/TW9TfyM) [![Docker Build](https://github.com/saqibj/pihole-6-speedtest/actions/workflows/publish.yml/badge.svg)](https://github.com/saqibj/pihole-6-speedtest/actions/workflows/publish.yml)

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

## Requirements
- Pi-hole v6.x
- Debian, Fedora, or derivatives
- Docker support (optional)

## Installation

### Quick Install

```bash
curl -sSL https://raw.githubusercontent.com/saqibj/pihole-6-speedtest/main/mod | sudo bash
```

### Manual Installation

1. Clone this repository:
```bash
git clone https://github.com/saqibj/pihole-6-speedtest.git
cd pihole-6-speedtest
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
    ghcr.io/saqibj/pihole-6-speedtest:pihole-6
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
pihole-6-speedtest/
├── mod                    # Main installation script
├── test                   # Speedtest runner script
├── scripts/
│   └── speedtestmod/
│       ├── install.sh     # Installation script
│       ├── speedtest.sh   # Speedtest runner
│       ├── speedtest.js   # Web interface JavaScript
│       └── speedtest.css  # Web interface styles
└── README.md
```

## Uninstallation

To remove the speedtest mod:

```bash
sudo ./mod -u
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Credits

- [Pi-hole](https://pi-hole.net/) - The core DNS server
- [Ookla Speedtest CLI](https://www.speedtest.net/apps/cli) - The speedtest tool
- [Chart.js](https://www.chartjs.org/) - For beautiful charts
- [Original Pi-hole Speedtest Mod](https://github.com/arevindh/pihole-speedtest) - The original project by @arevindh
