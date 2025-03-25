FROM pihole/pihole:latest

# Install the speedtest mod
RUN curl -sSL https://github.com/saqibj/pihole-6-speedtest/raw/main/mod | sudo bash

# Set the default tag
LABEL maintainer="Your Name <your.email@example.com>"
LABEL description="Pi-hole with Speedtest Mod"
LABEL version="2.1.1"
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
