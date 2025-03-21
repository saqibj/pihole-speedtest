FROM pihole/pihole:latest

# Install the speedtest mod
RUN curl -sSL https://github.com/arevindh/pihole-speedtest/raw/pihole-6-compatibility/mod | sudo bash

# Set the default tag
LABEL maintainer="arevindh"
LABEL version="pihole-6"
