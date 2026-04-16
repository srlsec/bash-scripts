#!/bin/bash

# Packet Tracer Installation Script for Ubuntu/Debian
# Set error handling
set -e

echo "[1/7] Downloading Cisco Packet Tracer..."
wget -O Packet_Tracer821_amd64_signed.deb "https://excellmedia.dl.sourceforge.net/project/cisco-packet-tracer/Packet_Tracer821_amd64_signed.deb?viasf=1"

echo "[2/7] Removing broken installs (if any)..."
sudo apt remove -y packettracer 2>/dev/null || true
sudo dpkg --remove packettracer 2>/dev/null || true
sudo apt autoremove -y 2>/dev/null || true

echo "[3/7] Updating system packages..."
sudo apt update

echo "[4/7] Installing dependencies..."
sudo apt install -y dialog libgl1 libxcb-xinerama0 libxcb-xinerama0-dev equivs wget

echo "[5/7] Creating dummy libgl1-mesa-glx package..."
# Clean up old dummy package files
rm -f libgl1-mesa-glx libgl1-mesa-glx_*.deb

# Create control file for dummy package
cat > libgl1-mesa-glx <<'EOF'
Section: misc
Priority: optional
Standards-Version: 3.9.2

Package: libgl1-mesa-glx
Version: 1.0
Depends: libgl1
Architecture: all
Maintainer: dummy <dummy@local>
Description: Dummy package for Packet Tracer
 This is a dummy package to satisfy Packet Tracer dependencies.
 It provides a virtual libgl1-mesa-glx package.
EOF

# Build and install dummy package
equivs-build libgl1-mesa-glx
sudo dpkg -i libgl1-mesa-glx_1.0_all.deb

echo "[6/7] Installing Packet Tracer..."
# Try to install, but don't exit on failure
set +e
sudo dpkg -i Packet_Tracer821_amd64_signed.deb
INSTALL_STATUS=$?
set -e

if [ $INSTALL_STATUS -ne 0 ]; then
    echo "Initial installation had dependency issues, fixing..."
    sudo apt --fix-broken install -y
fi

echo "[7/7] Verifying installation..."
if command -v packettracer &> /dev/null; then
    echo "✅ Packet Tracer installed successfully!"
    echo "You can run it by typing: packettracer"
else
    echo "⚠️  Installation completed but 'packettracer' command not found."
    echo "Try logging out and back in, or restarting your session."
fi

# Cleanup downloaded files
echo "Cleaning up temporary files..."
rm -f Packet_Tracer821_amd64_signed.deb
rm -f libgl1-mesa-glx
rm -f libgl1-mesa-glx_1.0_all.deb
rm -f libgl1-mesa-glx_1.0_amd64.buildinfo 2>/dev/null || true
rm -f libgl1-mesa-glx_1.0_amd64.changes 2>/dev/null || true

echo "Installation script completed!"
