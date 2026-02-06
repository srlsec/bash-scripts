#!/bin/bash

# TFTP Server Setup Script
# Automates the installation and configuration of TFTP-HPA server

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_status() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[!]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run as root (use sudo)"
        exit 1
    fi
}

# Function to update system
update_system() {
    print_status "Updating package lists..."
    apt update
    if [ $? -eq 0 ]; then
        print_status "System update completed"
    else
        print_error "Failed to update system"
        exit 1
    fi
}

# Function to install TFTP server
install_tftp() {
    print_status "Installing tftpd-hpa..."
    apt install -y tftpd-hpa
    if [ $? -eq 0 ]; then
        print_status "TFTP installation completed"
    else
        print_error "Failed to install TFTP"
        exit 1
    fi
}

# Function to configure TFTP server
configure_tftp() {
    print_status "Configuring TFTP server..."
    
    # Backup original config if exists
    if [ -f "/etc/default/tftpd-hpa" ]; then
        cp /etc/default/tftpd-hpa /etc/default/tftpd-hpa.backup.$(date +%Y%m%d_%H%M%S)
        print_status "Backup created: /etc/default/tftpd-hpa.backup"
    fi
    
    # Create configuration file
    cat > /etc/default/tftpd-hpa << EOF
# TFTP Server Configuration
TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/srv/tftp"
TFTP_ADDRESS=":69"
TFTP_OPTIONS="--secure --create"
EOF
    
    print_status "TFTP configuration file created"
}

# Function to setup TFTP directory
setup_tftp_directory() {
    print_status "Setting up TFTP directory..."
    
    # Create directory
    mkdir -p /srv/tftp
    
    # Set permissions
    chown -R tftp:tftp /srv/tftp
    chmod -R 777 /srv/tftp
    
    # Create a test file
    echo "TFTP Server is working!" > /srv/tftp/test.txt
    chmod 666 /srv/tftp/test.txt
    
    print_status "TFTP directory created at /srv/tftp"
    print_status "Test file created: /srv/tftp/test.txt"
}

# Function to manage TFTP service
manage_service() {
    print_status "Restarting TFTP service..."
    
    # Restart service
    systemctl restart tftpd-hpa
    
    # Enable on boot
    systemctl enable tftpd-hpa
    
    # Check service status
    print_status "Checking TFTP service status..."
    systemctl status tftpd-hpa --no-pager
    
    # Verify service is running
    if systemctl is-active --quiet tftpd-hpa; then
        print_status "TFTP service is running successfully"
    else
        print_error "TFTP service failed to start"
        exit 1
    fi
}

# Function to show firewall status
check_firewall() {
    print_status "Checking firewall configuration..."
    
    # Check if ufw is installed and enabled
    if command -v ufw &> /dev/null && ufw status | grep -q "active"; then
        print_warning "UFW firewall is active"
        print_warning "If TFTP doesn't work, you may need to allow port 69:"
        echo "  sudo ufw allow 69/udp"
    fi
}

# Function to show summary
show_summary() {
    echo ""
    echo "========================================"
    echo "          TFTP SETUP COMPLETE          "
    echo "========================================"
    echo ""
    echo "Summary:"
    echo "  ✓ TFTP Server: tftpd-hpa"
    echo "  ✓ TFTP Directory: /srv/tftp"
    echo "  ✓ TFTP Port: 69/udp"
    echo "  ✓ Configuration: /etc/default/tftpd-hpa"
    echo ""
    echo "To test TFTP server:"
    echo "  1. Put files in: /srv/tftp/"
    echo "  2. Test from client: tftp <server-ip>"
    echo "     -> get test.txt"
    echo ""
    echo "Files currently in TFTP directory:"
    ls -la /srv/tftp/
    echo ""
    echo "Service commands:"
    echo "  sudo systemctl status tftpd-hpa"
    echo "  sudo systemctl restart tftpd-hpa"
    echo "  sudo systemctl stop tftpd-hpa"
    echo "========================================"
}

# Main execution
main() {
    clear
    echo "========================================"
    echo "    TFTP Server Setup Script           "
    echo "========================================"
    echo ""
    
    check_root
    update_system
    install_tftp
    configure_tftp
    setup_tftp_directory
    manage_service
    check_firewall
    show_summary
}

# Execute main function
main
