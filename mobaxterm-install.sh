
#!/bin/bash

# Simple MobaXterm installer

# Check if wine is installed
if ! command -v wine &> /dev/null; then
    echo "Error: Wine is not installed"
    exit 1
fi

echo "Wine found. Installing MobaXterm..."

# Download the zip file
wget https://download.mobatek.net/2622026032581854/MobaXterm_Installer_v26.2.zip

# Extract the zip file
unzip MobaXterm_Installer_v26.2.zip

# Install with wine
wine MobaXterm_Installer_v26.2.msi
