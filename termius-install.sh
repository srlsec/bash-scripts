#!/bin/bash

# Simple Termius Installation Script (.deb method)

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

# Update and install dependencies
print_message "Updating package list..."
apt update
apt install -y wget gdebi-core

# Download latest Termius .deb
print_message "Downloading latest Termius..."
wget -O termius.deb https://www.termius.com/download/linux/Termius.deb

# Install
print_message "Installing Termius..."
dpkg -i termius.deb || apt --fix-broken install -y

# Cleanup
rm -f termius.deb

# Verify
if command -v termius &> /dev/null; then
    print_message "Termius installed successfully!"
    print_message "Run 'termius' to start"
else
    print_error "Installation failed"
    exit 1
fi
