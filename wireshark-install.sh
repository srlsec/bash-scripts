#!/bin/bash

# Update and install Wireshark
sudo apt update
sudo apt install -y wireshark

# Configure for non-root capture
echo "wireshark-common wireshark-common/install-setuid boolean true" | sudo debconf-set-selections
sudo dpkg-reconfigure -f noninteractive wireshark-common

# Ask for username
read -p "Enter username to add to wireshark group (leave empty to skip): " username

if [ -n "$username" ]; then
    if id "$username" &>/dev/null; then
        sudo usermod -aG wireshark "$username"
        echo "✅ Added $username to wireshark group"
    else
        echo "❌ User $username does not exist"
    fi
fi
