#!/bin/bash

# Antigravity Installer for Ubuntu 24.04
# Run with: chmod +x install-antigravity.sh && ./install-antigravity.sh

set -e  # Exit on error

echo "📦 Installing Antigravity on Ubuntu 24.04..."

# Update system
sudo apt update

# Install dependencies
sudo apt install -y curl gpg

# Add Google's signing key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/google-antigravity.gpg

# Add repository
echo "deb [signed-by=/usr/share/keyrings/google-antigravity.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | \
  sudo tee /etc/apt/sources.list.d/antigravity.list > /dev/null

# Install Antigravity
sudo apt update
sudo apt install -y antigravity

echo "✅ Antigravity installed successfully!"
echo "🚀 Run 'antigravity' to launch"
