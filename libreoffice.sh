#!/bin/bash

# Simple LibreOffice Installation Script
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

# Update package list
print_message "Updating package list..."
apt update

# Option 1: Install standard LibreOffice suite
print_message "Installing LibreOffice..."
apt install -y libreoffice

# Option 2: Install full suite with all features (uncomment to use)
# print_message "Installing LibreOffice (full version)..."
# apt install -y libreoffice-full

# Install language packs (optional - uncomment for your language)
# apt install -y libreoffice-l10n-en-us  # English US
# apt install -y libreoffice-l10n-fr      # French
# apt install -y libreoffice-l10n-de      # German
# apt install -y libreoffice-l10n-es      # Spanish
# apt install -y libreoffice-l10n-pt      # Portuguese
# apt install -y libreoffice-l10n-it      # Italian
# apt install -y libreoffice-l10n-ru      # Russian
# apt install -y libreoffice-l10n-ja      # Japanese
# apt install -y libreoffice-l10n-zh-cn   # Chinese Simplified
# apt install -y libreoffice-l10n-zh-tw   # Chinese Traditional

# Verify installation
if command -v libreoffice &> /dev/null; then
    print_message "LibreOffice installed successfully!"
    print_message "Version: $(libreoffice --version | head -n1)"
    print_message ""
    print_message "Run 'libreoffice' to start"
    print_message "Or launch from application menu"
else
    print_error "Installation failed"
    exit 1
fi
