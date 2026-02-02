#!/bin/bash
# enhanced-system-info.sh - Comprehensive hardware & system report

echo "==============================================="
echo "           SYSTEM INFORMATION REPORT"
echo "==============================================="
echo "Generated on: $(date)"
echo ""

# ======================
# 0. Root Check
# ======================
if [[ $EUID -ne 0 ]]; then
    echo "⚠️  Some information requires root privileges"
    echo "   Run with 'sudo' for complete details"
    echo ""
fi

read_dmi() {
    [[ -f "$1" ]] && cat "$1" 2>/dev/null || echo "N/A"
}

# ======================
# 1. VENDOR & MODEL INFO
# ======================
echo "🔹 VENDOR & MODEL INFORMATION"
echo "----------------------------"

echo "System Vendor:      $(read_dmi /sys/devices/virtual/dmi/id/sys_vendor)"
echo "Device Model:       $(read_dmi /sys/devices/virtual/dmi/id/product_name)"
echo "System Family:      $(sudo dmidecode -s system-family 2>/dev/null || echo "N/A")"
echo "Board Vendor:       $(read_dmi /sys/devices/virtual/dmi/id/board_vendor)"
echo "BIOS Vendor:        $(read_dmi /sys/devices/virtual/dmi/id/bios_vendor)"
echo "BIOS Version:       $(read_dmi /sys/devices/virtual/dmi/id/bios_version)"
echo "BIOS Release Date:  $(sudo dmidecode -s bios-release-date 2>/dev/null || echo "N/A")"
echo "Chassis Vendor:     $(read_dmi /sys/devices/virtual/dmi/id/chassis_vendor)"
echo "Chassis Type:       $(sudo dmidecode -s chassis-type 2>/dev/null || echo "N/A")"

# ======================
# 2. SERIAL NUMBERS
# ======================
echo ""
echo "🔹 SERIAL NUMBERS"
echo "-----------------"

echo "System Serial:      $(read_dmi /sys/devices/virtual/dmi/id/product_serial)"
echo "Board Serial:       $(read_dmi /sys/devices/virtual/dmi/id/board_serial)"
echo "Chassis Serial:     $(read_dmi /sys/devices/virtual/dmi/id/chassis_serial)"

# Disk Serial Numbers
echo ""
echo "💾 DISK SERIAL NUMBERS"
if command -v lsblk &> /dev/null; then
    lsblk -o NAME,MODEL,SERIAL,SIZE,TYPE | grep -E "(disk|part)" | sed 's/^/  /'
else
    echo "  Install 'lsblk' for disk information"
fi

# ======================
# 3. HARDWARE INFO
# ======================
echo ""
echo "🔹 HARDWARE INFORMATION"
echo "-----------------------"

# CPU
echo "💻 CPU DETAILS"
lscpu | grep -E 'Architecture|Model name|CPU MHz|CPU max MHz|CPU min MHz|Core|Thread|Vendor' | sed 's/^/  /'

# Memory
echo ""
echo "🧠 MEMORY DETAILS"
free -h | sed 's/^/  /'
echo "Memory Slots Info:"
sudo dmidecode -t memory | awk '/Size|Speed|Locator|Type/ {print "  "$0}'

# GPU
echo ""
echo "🎮 GPU DETAILS"
if command -v lspci &> /dev/null; then
    lspci | grep -Ei "vga|3d|display" | sed 's/^/  /'
fi

# Network
echo ""
echo "🌐 NETWORK INTERFACES"
ip -brief addr | sed 's/^/  /'

# USB
echo ""
echo "🔌 USB DEVICES"
if command -v lsusb &> /dev/null; then
    lsusb | sed 's/^/  /'
fi

# ======================
# 4. OPERATING SYSTEM INFO
# ======================
echo ""
echo "🔹 OPERATING SYSTEM INFORMATION"
echo "-------------------------------"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "Distribution:     $NAME"
    echo "Version:          $VERSION"
    echo "Codename:         $VERSION_CODENAME"
    echo "ID:               $ID"
fi

echo "Kernel:           $(uname -s) $(uname -r)"
echo "Kernel Release:   $(uname -v)"
echo "Architecture:     $(uname -m)"
echo "Hostname:         $(hostname)"
echo "Uptime:           $(uptime -p | sed 's/up //')"

echo ""
echo "👥 USER SESSIONS:"
echo "  Current user: $(whoami)"
who 2>/dev/null | awk '{print "    " $1 " on " $2 " (" $3 " " $4 ")"}' || echo "    No active sessions found"

# ======================
# 5. SYSTEM HEALTH
# ======================
echo ""
echo "🔹 SYSTEM HEALTH"
echo "----------------"

# CPU Load
LOAD=$(uptime | awk -F'load average:' '{print $2}' 2>/dev/null || echo "N/A")
echo "CPU Load:         $LOAD"

# Temperatures
if command -v sensors &> /dev/null; then
    echo "Temperature:"
    sensors | sed 's/^/  /'
fi

# Battery
if [ -d /sys/class/power_supply/ ]; then
    for bat in /sys/class/power_supply/BAT*; do
        [[ -e "$bat" ]] || continue
        CAPACITY=$(cat "$bat/capacity" 2>/dev/null || echo "N/A")
        STATUS=$(cat "$bat/status" 2>/dev/null || echo "N/A")
        echo "Battery:  $(basename $bat): $CAPACITY% ($STATUS)"
    done
fi

# ======================
# 6. USER-INSTALLED PACKAGES
# ======================
echo ""
echo "📦 USER-INSTALLED PACKAGES"
echo "-----------------------------------------"
if [ -f /var/log/installer/initial-status.gz ]; then
    comm -23 <(apt-mark showmanual | sort -u) \
            <(gzip -dc /var/log/installer/initial-status.gz | sed -n 's/^Package: //p' | sort -u) | \
    while read pkg; do
        version=$(dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null || echo "N/A")
        echo "  $pkg - $version"
    done | sort
else
    apt-mark showmanual | \
    grep -v -E 'ubuntu-|gnome-|libreoffice|thunderbird|rhythmbox|shotwell|transmission|gedit|eog|evince|totem|baobab|seahorse|simple-scan|cheese|deja-dup' | \
    while read pkg; do
        version=$(dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null || echo "N/A")
        echo "  $pkg - $version"
    done | sort
fi

# ======================
# 7. AVAILABLE USERS
# ======================
echo ""
echo "👤 AVAILABLE USERS (with /bin/bash shell)"
echo "-----------------------------------------"
awk -F: '($7=="/bin/bash"){print "  "$1}' /etc/passwd

awk -F: '($7=="/bin/bash"){print $1}' /etc/passwd | while read user; do
    echo "User: $user"
    
    # List groups for user
    GROUPS=$(id -nG "$user")
    echo "  Groups: $GROUPS"
    
    # Check home directory permissions
    HOMEDIR=$(getent passwd "$user" | cut -d: -f6)
    if [ -d "$HOMEDIR" ]; then
        PERMS=$(ls -ld "$HOMEDIR" | awk '{print $1, $3, $4}')
        echo "  Home Dir Permissions: $PERMS"
    else
        echo "  Home Dir Permissions: N/A"
    fi
    
    echo ""
done


echo ""
echo "==============================================="
echo "           END OF REPORT"
echo "==============================================="
