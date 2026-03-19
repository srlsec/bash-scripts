#!/bin/bash

# Simple WireGuard Installation Script
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

# Install WireGuard
print_message "Installing WireGuard..."
apt install -y wireguard wireguard-tools

# Enable IP forwarding
print_message "Enabling IP forwarding..."
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p

# Create WireGuard directory
mkdir -p /etc/wireguard
chmod 700 /etc/wireguard

print_message "WireGuard installed successfully!"
print_message "Version: $(wg --version)"
print_message ""
print_message "Next steps:"
print_message "1. Generate keys: wg genkey | tee /etc/wireguard/private.key | wg pubkey > /etc/wireguard/public.key"
print_message "2. Create config: /etc/wireguard/wg0.conf"
print_message "3. Start VPN: systemctl start wg-quick@wg0"
