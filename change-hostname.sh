#!/bin/bash

# Simple Hostname Change Script

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "Error: Please run as root (use sudo)"
    exit 1
fi

# Show current hostname
echo "Current hostname: $(hostname)"
echo ""

# Get new hostname
read -p "Enter new hostname: " new_hostname

# Check if input is empty
if [[ -z "$new_hostname" ]]; then
    echo "Error: Hostname cannot be empty!"
    exit 1
fi

# Change hostname
echo "Changing hostname to $new_hostname..."

# Set hostname
hostname "$new_hostname"

# Update /etc/hostname (for permanent change)
echo "$new_hostname" > /etc/hostname

# Update /etc/hosts file
sed -i "s/$(hostname)/$new_hostname/g" /etc/hosts

# Verify change
echo ""
echo "Hostname changed successfully!"
echo "New hostname: $(hostname)"

# Ask for reboot
read -p "Reboot now? (y/n): " reboot_choice
if [[ "$reboot_choice" == "y" || "$reboot_choice" == "Y" ]]; then
    echo "Rebooting system..."
    reboot
else
    echo "Changes will be fully applied after reboot."
fi
