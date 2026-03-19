#!/bin/bash

# Simple Brave Browser Installation Script
# For Ubuntu/Debian systems

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_message() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check root
if [[ $EUID -ne 0 ]]; then
    print_error "Please run with sudo"
    exit 1
fi

# Install prerequisites
print_message "Installing prerequisites..."
apt update
apt install -y curl

# Download and install Brave's GPG key
print_message "Adding Brave repository..."
curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
    https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

# Add Brave repository
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | \
    tee /etc/apt/sources.list.d/brave-browser-release.list

# Update package list
print_message "Updating package list..."
apt update

# Install Brave
print_message "Installing Brave browser..."
apt install -y brave-browser

# Verify installation
if command -v brave-browser &> /dev/null; then
    print_message "Brave browser installed successfully!"
    print_message "Version: $(brave-browser --version)"
    print_message ""
    print_message "Run 'brave-browser' to start"
else
    print_error "Installation failed"
    exit 1
fi
