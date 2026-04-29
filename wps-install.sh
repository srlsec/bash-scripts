#!/bin/bash

set -e

echo "🔄 Updating system..."
sudo apt update

echo "📦 Installing required tools..."
sudo apt install -y wget gdebi-core

echo "⬇️ Downloading WPS Office..."
cd /tmp
WPS_URL="https://wdl1.pcfg.cache.wpscdn.com/wpsdl/wpsoffice/download/linux/11723/wps-office_11.1.0.11723_amd64.deb"

wget -O wps.deb "$WPS_URL"

echo "📥 Installing WPS Office..."
sudo gdebi -n wps.deb

echo "🔤 Installing Microsoft fonts..."
sudo apt install -y ttf-mscorefonts-installer

echo "🧹 Cleaning up..."
rm -f wps.deb

echo "✅ WPS Office installation completed!"
echo "🚀 You can launch it using: wps"
