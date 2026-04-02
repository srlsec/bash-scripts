#!/bin/bash
# Auto-install Wine on Ubuntu 22.04/24.04

# Enable 32-bit arch
sudo dpkg --add-architecture i386

# Update system
sudo apt update

# Install prerequisites
sudo apt install -y wget gnupg2 software-properties-common

# Add WineHQ repository
sudo mkdir -pm755 /etc/apt/keyrings
wget -qO- https://dl.winehq.org/wine-builds/winehq.key | sudo gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key

# Detect Ubuntu version and add correct repo
if [ "$(lsb_release -rs)" = "22.04" ]; then
    sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/winehq-jammy.sources
elif [ "$(lsb_release -rs)" = "24.04" ]; then
    sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/noble/winehq-noble.sources
else
    echo "Unsupported Ubuntu version"
    exit 1
fi

# Update and install Wine
sudo apt update
sudo apt install -y --install-recommends winehq-stable

# Verify installation
wine --version
