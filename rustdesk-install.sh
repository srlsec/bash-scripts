#!/bin/bash

# Rustdesk Installation Script
# This script installs Rustdesk and its dependencies

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print colored output
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if script is run with sudo
check_sudo() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run with sudo privileges"
        echo "Please run: sudo $0"
        exit 1
    fi
}

# Update package list
update_packages() {
    print_message "Updating package list..."
    apt update
}

# Install dependencies
install_dependencies() {
    print_message "Installing Rustdesk dependencies..."
    apt install -y libxdo3 libva-drm2 libva-x11-2 libvdpau1 wget
    
    if [ $? -eq 0 ]; then
        print_message "Dependencies installed successfully"
    else
        print_error "Failed to install dependencies"
        exit 1
    fi
}

# Check if Rustdesk is already installed
check_existing_installation() {
    if dpkg -l | grep -q rustdesk; then
        print_warning "Rustdesk is already installed"
        read -p "Do you want to reinstall? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_message "Installation cancelled"
            exit 0
        fi
    fi
}

# Download Rustdesk if not present
download_rustdesk() {
    local DEB_FILE="rustdesk-1.2.6-x86_64.deb"
    local DOWNLOAD_URL="https://github.com/rustdesk/rustdesk/releases/download/1.2.6/rustdesk-1.2.6-x86_64.deb"
    
    if [ -f "$DEB_FILE" ]; then
        print_message "Found existing $DEB_FILE"
        read -p "Use existing file? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            print_message "Downloading fresh copy..."
            rm -f "$DEB_FILE"
            wget "$DOWNLOAD_URL"
        else
            print_message "Using existing $DEB_FILE"
        fi
    else
        print_message "Downloading Rustdesk..."
        wget "$DOWNLOAD_URL"
    fi
    
    if [ ! -f "$DEB_FILE" ]; then
        print_error "Failed to download Rustdesk"
        exit 1
    fi
}

# Install Rustdesk
install_rustdesk() {
    local DEB_FILE="rustdesk-1.2.6-x86_64.deb"
    
    print_message "Installing Rustdesk package..."
    dpkg -i "$DEB_FILE"
    
    # Fix any dependency issues
    if [ $? -ne 0 ]; then
        print_warning "Fixing broken dependencies..."
        apt --fix-broken install -y
        dpkg -i "$DEB_FILE"
    fi
    
    if [ $? -eq 0 ]; then
        print_message "Rustdesk installed successfully!"
    else
        print_error "Failed to install Rustdesk"
        exit 1
    fi
}

# Verify installation
verify_installation() {
    print_message "Verifying installation..."
    
    if command -v rustdesk &> /dev/null; then
        print_message "Rustdesk is installed and in PATH"
        RUSTDESK_VERSION=$(rustdesk --version 2>/dev/null || echo "Version unknown")
        print_message "Version: $RUSTDESK_VERSION"
    else
        print_warning "Rustdesk command not found in PATH"
        print_message "You can still launch it from the application menu"
    fi
    
    # Check if service is running
    if systemctl list-unit-files | grep -q rustdesk; then
        print_message "Rustdesk service is installed"
        systemctl status rustdesk --no-pager | head -n 3
    fi
}

# Clean up
cleanup() {
    print_message "Cleaning up..."
    apt autoremove -y
    apt clean
}

# Main installation function
main() {
    print_message "Starting Rustdesk installation..."
    echo "=================================="
    
    check_sudo
    check_existing_installation
    update_packages
    install_dependencies
    download_rustdesk
    install_rustdesk
    verify_installation
    cleanup
    
    echo "=================================="
    print_message "Rustdesk installation completed!"
    print_message "You can launch Rustdesk from the application menu or by typing 'rustdesk' in terminal"
}

# Run main function
main
