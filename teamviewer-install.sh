#!/bin/bash

# Simple TeamViewer Installation Script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_message() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check root
if [[ $EUID -ne 0 ]]; then
    print_error "Please run with sudo"
    exit 1
fi

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    DEB_FILE="teamviewer_amd64.deb"
elif [ "$ARCH" = "aarch64" ]; then
    DEB_FILE="teamviewer_arm64.deb"
else
    print_error "Unsupported architecture: $ARCH"
    exit 1
fi

print_message "Detected architecture: $ARCH"

# Update package list
print_message "Updating package list..."
apt update

# Install dependencies
print_message "Installing dependencies..."
apt install -y wget gdebi-core

# Download latest TeamViewer
print_message "Downloading latest TeamViewer..."
wget https://download.teamviewer.com/download/linux/$DEB_FILE

# Install TeamViewer
print_message "Installing TeamViewer..."
dpkg -i $DEB_FILE || apt --fix-broken install -y

# Enable and start service
print_message "Starting TeamViewer service..."
systemctl enable teamviewerd
systemctl start teamviewerd

# Cleanup
print_message "Cleaning up..."
rm -f $DEB_FILE

# Verify installation
if command -v teamviewer &> /dev/null; then
    print_message "TeamViewer installed successfully!"
    print_message "Run 'teamviewer' to start"
    systemctl status teamviewerd --no-pager | head -n 3
else
    print_error "Installation failed"
    exit 1
fi
