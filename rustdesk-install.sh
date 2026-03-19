#!/bin/bash

# Simple Rustdesk Installation Script

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

# Install dependencies
print_message "Installing dependencies..."
apt update
apt install -y libxdo3 libva-drm2 libva-x11-2 libvdpau1 wget

# Download Rustdesk
print_message "Downloading Rustdesk..."
wget https://github.com/rustdesk/rustdesk/releases/download/1.2.6/rustdesk-1.2.6-x86_64.deb

# Install
print_message "Installing Rustdesk..."
dpkg -i rustdesk-1.2.6-x86_64.deb || apt --fix-broken install -y

# Cleanup
print_message "Cleaning up..."
rm rustdesk-1.2.6-x86_64.deb

print_message "Rustdesk installed successfully!"
print_message "Run 'rustdesk' to start"
