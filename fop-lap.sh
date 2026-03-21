#!/bin/bash

# Simple setup script
# Run with: sudo bash script.sh

echo "Starting system setup..."

# Update system
apt update -y
apt upgrade -y

# Install basic packages
apt install -y curl net-tools

# Install applications
curl -sSL https://raw.githubusercontent.com/srlsec/bash-scripts/refs/heads/main/termius-install.sh | sed 's/\r$//' | bash
curl -sSL https://raw.githubusercontent.com/srlsec/bash-scripts/refs/heads/main/rustdesk-install.sh | sed 's/\r$//' | bash
curl -sSL https://raw.githubusercontent.com/srlsec/bash-scripts/refs/heads/main/teamviewer-install.sh | sed 's/\r$//' | bash
curl -sSL https://raw.githubusercontent.com/srlsec/bash-scripts/refs/heads/main/wireguard-install.sh | sed 's/\r$//' | bash
curl -sSL https://raw.githubusercontent.com/srlsec/bash-scripts/refs/heads/main/libreoffice.sh | sed 's/\r$//' | bash
curl -sSL https://raw.githubusercontent.com/srlsec/bash-scripts/refs/heads/main/net-permission.sh | sed 's/\r$//' | bash
curl -sSL https://raw.githubusercontent.com/srlsec/bash-scripts/refs/heads/main/brave-browser.sh | sed 's/\r$//' | bash

# Create user with prompt
echo "==== Create New User ===="
read -p "Enter username: " username

if [ -z "$username" ]; then
    echo "Username required!"
    exit 1
fi

if id "$username" &>/dev/null; then
    echo "User $username already exists"
else
    useradd -m -s /bin/bash "$username"
    echo "User $username created successfully"
fi

read -sp "Enter password for $username: " password
echo
read -sp "Confirm password: " password_confirm
echo

if [ "$password" != "$password_confirm" ]; then
    echo "Passwords do not match!"
    exit 1
fi

echo "$username:$password" | chpasswd
echo "Password set for $username"

# Change hostname
echo "==== Change Hostname ===="
read -p "Enter new hostname: " hostname
if [ -z "$hostname" ]; then
    echo "Hostname required!"
    exit 1
fi

hostnamectl set-hostname "$hostname"
sed -i "s/127\.0\.1\.1.*/127.0.1.1\t$hostname/" /etc/hosts
systemctl restart systemd-hostnamed

echo "Hostname set to: $hostname"
echo "Current hostname: $(hostname)"
echo "Setup complete!"
