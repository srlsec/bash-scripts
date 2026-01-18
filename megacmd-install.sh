#!/bin/bash

# MEGAcmd Installation Script for Ubuntu Server
# Save as: install_megacmd.sh
# Make executable: chmod +x install_megacmd.sh
# Run: sudo ./install_megacmd.sh

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        warning "Running as root. It's recommended to run as regular user with sudo."
    fi
}

# Detect Ubuntu version
detect_ubuntu_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        UBUNTU_VERSION=$(echo $VERSION_ID | cut -d'.' -f1)
        log "Detected Ubuntu version: $UBUNTU_VERSION"
    else
        error "Cannot detect Ubuntu version"
    fi
}

# Install dependencies
install_dependencies() {
    step "Installing dependencies..."
    sudo apt update
    sudo apt install -y wget curl apt-transport-https software-properties-common
}

# Install MEGAcmd from official repository
install_megacmd_repo() {
    step "Adding MEGA official repository..."
    
    # Determine repository URL based on Ubuntu version
    case $UBUNTU_VERSION in
        20|22|24)
            REPO_VERSION="xUbuntu_${UBUNTU_VERSION}.04"
            ;;
        *)
            warning "Ubuntu $UBUNTU_VERSION might not be officially supported. Using Ubuntu 22.04 repository."
            REPO_VERSION="xUbuntu_22.04"
            ;;
    esac
    
    log "Using repository version: $REPO_VERSION"
    
    # Download and add signing key
    cd /tmp
    wget -q "https://mega.nz/linux/repo/$REPO_VERSION/Release.key" || error "Failed to download Release.key"
    sudo apt-key add Release.key || error "Failed to add apt key"
    
    # Add repository
    echo "deb https://mega.nz/linux/repo/$REPO_VERSION/ ./" | sudo tee /etc/apt/sources.list.d/mega.list
    
    # Update and install
    step "Installing MEGAcmd..."
    sudo apt update
    sudo apt install -y megacmd
    
    # Clean up
    rm -f Release.key
}

# Alternative installation method (if repository fails)
install_megacmd_direct() {
    step "Trying direct DEB package installation..."
    
    cd /tmp
    ARCH=$(dpkg --print-architecture)
    
    case $ARCH in
        "amd64")
            PACKAGE_ARCH="amd64"
            ;;
        "arm64")
            PACKAGE_ARCH="arm64"
            ;;
        *)
            error "Unsupported architecture: $ARCH"
            ;;
    esac
    
    # Download DEB package
    DEB_URL="https://mega.nz/linux/repo/xUbuntu_22.04/${ARCH}/megacmd-xUbuntu_22.04_${ARCH}.deb"
    log "Downloading: $DEB_URL"
    
    wget -q "$DEB_URL" || error "Failed to download DEB package"
    
    # Install package
    sudo dpkg -i "megacmd-xUbuntu_22.04_${ARCH}.deb" || sudo apt install -f -y
    
    # Clean up
    rm -f "megacmd-xUbuntu_22.04_${ARCH}.deb"
}

# Verify installation
verify_installation() {
    step "Verifying installation..."
    
    if command -v mega-version &> /dev/null; then
        log "MEGAcmd installed successfully!"
        mega-version
    elif command -v mega-cmd &> /dev/null; then
        log "MEGAcmd installed successfully!"
        echo "MEGAcmd is available as 'mega-cmd'"
    else
        error "MEGAcmd installation verification failed"
    fi
}

# Show usage examples
show_examples() {
    step "MEGAcmd Usage Examples:"
    echo "
Basic Commands:
  mega-login your@email.com          # Login to MEGA account
  mega-ls                            # List files in cloud
  mega-put file.txt /                # Upload file
  mega-get /file.txt ./              # Download file
  mega-sync /local/path /remote/path # Sync directory

Interactive Mode:
  mega-cmd                           # Start interactive session

Common Operations:
  mega-mkdir /backups                # Create directory
  mega-cp /file.txt /backups/        # Copy file
  mega-rm /file.txt                  # Remove file
  mega-du                            # Show storage usage
  mega-df                            # Show storage info
    "
}

# Main installation function
main() {
    log "Starting MEGAcmd installation..."
    log "Ubuntu Server MEGAcmd Installer"
    echo "================================"
    
    check_root
    detect_ubuntu_version
    install_dependencies
    
    # Try repository method first, fallback to direct method
    if install_megacmd_repo; then
        log "Repository installation completed"
    else
        warning "Repository installation failed, trying direct method..."
        install_megacmd_direct
    fi
    
    verify_installation
    show_examples
    
    log "Installation completed successfully!"
    log "You can now use MEGAcmd commands. Start with 'mega-help' for help."
}

# Run main function
main "$@"