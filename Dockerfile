FROM pihole/pihole:latest

# Install the speedtest mod
RUN curl -sSL https://github.com/saqibj/pihole-6-speedtest/raw/main/mod | sudo bash

# Set the default tag
LABEL maintainer="saqibj"
LABEL version="2.0.0"
LABEL pihole_version="6.x"

EXPOSE 53/tcp 53/udp 80/tcp
