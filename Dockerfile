FROM pihole/pihole:latest

# Install the speedtest mod
RUN curl -sSL https://raw.githubusercontent.com/saqibj/pihole-speedtest/v2.1.3/mod | sudo bash

# Set the default tag
LABEL maintainer="saqibj <https://github.com/saqibj>"
LABEL description="Pi-Hole 6.x with Speedtest Mod"
LABEL version="2.1.3"
LABEL pihole_version="6.x"

# Copy mod files
COPY scripts/speedtestmod/install.sh /install.sh
COPY scripts/speedtestmod/speedtest.sh /speedtest.sh
COPY scripts/speedtestmod/speedtest.js /speedtest.js
COPY scripts/speedtestmod/speedtest.css /speedtest.css

# Set execute permissions
RUN chmod +x /install.sh /speedtest.sh

# Run installation script
RUN /install.sh

# Expose ports
EXPOSE 53/tcp 53/udp 80/tcp 443/tcp

# Start Pi-hole
ENTRYPOINT ["/s6-init"]
