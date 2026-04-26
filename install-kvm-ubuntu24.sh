#!/bin/bash

# KVM/QEMU + Virt-Manager Installation Script for Ubuntu 24.04
# Run with: sudo ./install-kvm-ubuntu24.sh

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}KVM/QEMU + Virt-Manager Installer${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (sudo).${NC}" 
   exit 1
fi

# Get the original user (not root)
ORIGINAL_USER=${SUDO_USER:-$USER}
echo -e "${GREEN}Installing for user: $ORIGINAL_USER${NC}"

# Step 1: Update system
echo -e "${YELLOW}[1/8] Updating system packages...${NC}"
apt update && apt upgrade -y

# Step 2: Check virtualization support
echo -e "${YELLOW}[2/8] Checking virtualization support...${NC}"
VFLAG=$(egrep -c '(vmx|svm)' /proc/cpuinfo)
if [ $VFLAG -eq 0 ]; then
    echo -e "${RED}ERROR: Hardware virtualization not supported or not enabled in BIOS.${NC}"
    echo -e "${YELLOW}Please enable Intel VT-x or AMD-V in your BIOS settings.${NC}"
    exit 1
fi
echo -e "${GREEN}Virtualization support detected (flags: $VFLAG)${NC}"

# Step 3: Install KVM and packages
echo -e "${YELLOW}[3/8] Installing KVM/QEMU and Virt-Manager...${NC}"
apt install -y \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-clients \
    bridge-utils \
    virtinst \
    virt-manager \
    cpu-checker

# Step 4: Start and enable libvirtd
echo -e "${YELLOW}[4/8] Starting libvirtd service...${NC}"
systemctl enable --now libvirtd

# Step 5: Add user to groups
echo -e "${YELLOW}[5/8] Adding user $ORIGINAL_USER to libvirt and kvm groups...${NC}"
usermod -aG libvirt $ORIGINAL_USER
usermod -aG kvm $ORIGINAL_USER

# Step 6: Fix socket permissions in libvirtd.conf
echo -e "${YELLOW}[6/8] Configuring libvirt socket permissions...${NC}"
sed -i 's/#unix_sock_group = "libvirt"/unix_sock_group = "libvirt"/' /etc/libvirt/libvirtd.conf
sed -i 's/#unix_sock_rw_perms = "0770"/unix_sock_rw_perms = "0770"/' /etc/libvirt/libvirtd.conf

# Step 7: Create polkit rule for permission fixes
echo -e "${YELLOW}[7/8] Creating polkit rule for libvirt access...${NC}"
cat > /etc/polkit-1/rules.d/50-libvirt.rules << 'EOF'
polkit.addRule(function(action, subject) {
    if (action.id == "org.libvirt.unix.manage" &&
        subject.isInGroup("libvirt")) {
        return polkit.Result.YES;
    }
});
EOF

# Step 8: Fix socket permissions and restart services
echo -e "${YELLOW}[8/8] Restarting services...${NC}"
systemctl restart polkit
systemctl stop libvirtd
systemctl stop libvirtd-ro.socket
systemctl stop libvirtd.socket
systemctl start libvirtd

# Fix socket permissions directly
if [ -S /var/run/libvirt/libvirt-sock ]; then
    chown root:libvirt /var/run/libvirt/libvirt-sock
    chmod 660 /var/run/libvirt/libvirt-sock
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}IMPORTANT: You must log out and log back in for group changes to take effect.${NC}"
echo -e "${YELLOW}After logging back in, run 'virt-manager' to start the Virtual Machine Manager.${NC}"
echo -e "${YELLOW}Or run 'sudo virt-manager' if you still have permission issues.${NC}"
echo ""
echo -e "${GREEN}Verification commands to run after login:${NC}"
echo -e "  kvm-ok                      # Check KVM support"
echo -e "  virsh list --all            # List VMs"
echo -e "  virt-manager                # Launch GUI"
