#!/bin/bash

echo "Updating system..."
sudo apt update -y

echo "Installing required packages..."
sudo apt install -y curl gpg

echo "Adding AnyDesk GPG key..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://keys.anydesk.com/repos/DEB-GPG-KEY | \
sudo gpg --dearmor -o /etc/apt/keyrings/anydesk.gpg

echo "Adding AnyDesk repository..."
echo "deb [signed-by=/etc/apt/keyrings/anydesk.gpg] http://deb.anydesk.com/ all main" | \
sudo tee /etc/apt/sources.list.d/anydesk.list

echo "Updating package list..."
sudo apt update -y

echo "Installing AnyDesk..."
sudo apt install -y anydesk

echo "Fixing Wayland issue (forcing Xorg)..."

# Backup config before modifying
sudo cp /etc/gdm3/custom.conf /etc/gdm3/custom.conf.bak

# Uncomment WaylandEnable=false (or add if not present)
if grep -q "^#WaylandEnable=false" /etc/gdm3/custom.conf; then
    sudo sed -i 's/^#WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf
elif ! grep -q "^WaylandEnable=false" /etc/gdm3/custom.conf; then
    echo "WaylandEnable=false" | sudo tee -a /etc/gdm3/custom.conf
fi

echo "Enabling and starting AnyDesk service..."
sudo systemctl enable anydesk
sudo systemctl start anydesk

echo "⚠️ Reboot required to apply Wayland changes"

echo "✅ AnyDesk installation completed!"
