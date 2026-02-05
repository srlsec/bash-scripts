#!/bin/bash

# Google Chrome Installer for Ubuntu 24.04
# Method 1: Official .deb Package

set -e  # Exit on any error

echo "=========================================="
echo "Google Chrome Installer for Ubuntu 24.04"
echo "=========================================="

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo "Please do not run as root/sudo. Run as normal user."
    exit 1
fi

# Check if wget is installed
if ! command -v wget &> /dev/null; then
    echo "Installing wget..."
    sudo apt update && sudo apt install -y wget
fi

# Check if Google Chrome is already installed
if command -v google-chrome &> /dev/null; then
    echo "Google Chrome is already installed."
    echo "Version: $(google-chrome --version)"
    echo "Would you like to reinstall? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
fi

# Create a temporary directory for the download
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

echo "Downloading Google Chrome..."
wget -q --show-progress https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

# Verify download was successful
if [ ! -f "google-chrome-stable_current_amd64.deb" ]; then
    echo "Error: Failed to download Google Chrome package."
    exit 1
fi

echo "Installing Google Chrome..."
echo "You may be prompted for your password..."

# Install the package
sudo apt install -y ./google-chrome-stable_current_amd64.deb

# Check installation was successful
if command -v google-chrome &> /dev/null; then
    echo ""
    echo "✓ Installation successful!"
    echo "✓ Google Chrome $(google-chrome --version | cut -d ' ' -f 3) installed"
    echo ""
    echo "You can launch Chrome from:"
    echo "  • Applications menu"
    echo "  • Terminal: google-chrome"
    echo "  • Terminal (incognito): google-chrome --incognito"
else
    echo "Error: Installation may have failed. Trying alternative method..."
    # Try alternative installation method
    sudo dpkg -i google-chrome-stable_current_amd64.deb || sudo apt --fix-broken install -y
fi

# Clean up
cd
rm -rf "$TEMP_DIR"

# Offer to launch Chrome
echo ""
echo "Would you like to launch Google Chrome now? (y/N)"
read -r launch_response
if [[ "$launch_response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Launching Google Chrome..."
    google-chrome &
fi

echo "=========================================="
echo "Installation complete!"
echo "=========================================="
