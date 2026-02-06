#!/bin/bash

# Simple Google Chrome Installer for Ubuntu 24.04
# Default: Method 1 (Direct .deb download)
# Optional: Method 2 (Repository install)

set -e  # Exit on error

echo "=========================================="
echo "  Google Chrome Installer for Ubuntu"
echo "=========================================="

# Check root
if [ "$EUID" -eq 0 ]; then 
    echo "Please run as normal user (not root/sudo)"
    exit 1
fi

# Show installation methods
echo ""
echo "Select installation method:"
echo "  1) Direct .deb download (Default - One-time install)"
echo "  2) Add repository (Recommended - Auto updates via apt)"
echo ""
read -p "Enter choice [1]: " -r method
method=${method:-1}  # Default to method 1

# Check if Chrome already exists
if command -v google-chrome &> /dev/null; then
    echo "Chrome already installed: $(google-chrome --version)"
    read -p "Reinstall? (y/N): " -r reinstall
    if [[ ! "$reinstall" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Cancelled."
        exit 0
    fi
fi

# Install based on chosen method
if [ "$method" -eq "1" ]; then
    echo "Installing using Method 1 (Direct .deb)..."
    
    # Install wget if missing
    if ! command -v wget &> /dev/null; then
        sudo apt update && sudo apt install -y wget
    fi
    
    # Download and install
    wget -q --show-progress https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo apt install -y ./google-chrome-stable_current_amd64.deb
    rm -f google-chrome-stable_current_amd64.deb
    
    echo "✓ Installed via .deb package"
    echo "  Note: Run this script again to update"
    
elif [ "$method" -eq "2" ]; then
    echo "Installing using Method 2 (Repository)..."
    
    # Add repository and install
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/googlechrome-linux-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/googlechrome-linux-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
    sudo apt update
    sudo apt install -y google-chrome-stable
    
    echo "✓ Installed via repository"
    echo "  Updates: sudo apt update && sudo apt upgrade"
    
else
    echo "Invalid choice. Using Method 1 (default)..."
    wget -q --show-progress https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo apt install -y ./google-chrome-stable_current_amd64.deb
    rm -f google-chrome-stable_current_amd64.deb
fi

# Verify installation
if command -v google-chrome &> /dev/null; then
    echo ""
    echo "✓ Success! Chrome installed: $(google-chrome --version)"
    
    # Offer to launch
    read -p "Launch Chrome now? (y/N): " -r launch
    if [[ "$launch" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        google-chrome &
    fi
else
    echo "Installation failed. Try: sudo apt --fix-broken install"
fi

echo ""
echo "=========================================="
echo "           Installation Complete"
echo "=========================================="
