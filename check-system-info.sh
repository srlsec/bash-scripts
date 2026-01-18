#!/bin/bash
# hardware-info.sh - Get comprehensive system information

echo "==============================================="
echo "           SYSTEM INFORMATION REPORT"
echo "==============================================="
echo "Generated on: $(date)"
echo ""

# Check if we need root privileges
if [[ $EUID -ne 0 ]]; then
    echo "⚠️  Some information requires root privileges"
    echo "   Run with 'sudo' for complete details"
    echo ""
fi

# ======================
# 1. VENDOR INFORMATION
# ======================
echo "🔹 VENDOR INFORMATION"
echo "---------------------"

# System Vendor
if [ -f /sys/devices/virtual/dmi/id/sys_vendor ]; then
    VENDOR=$(cat /sys/devices/virtual/dmi/id/sys_vendor 2>/dev/null)
    echo "System Vendor:    $VENDOR"
fi

# Laptop/Desktop Model - ADDED THIS SECTION
if [ -f /sys/devices/virtual/dmi/id/product_name ]; then
    MODEL=$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null)
    echo "Device Model:     $MODEL"
fi

# Board/BIOS Vendor
if [ -f /sys/devices/virtual/dmi/id/board_vendor ]; then
    BOARD_VENDOR=$(cat /sys/devices/virtual/dmi/id/board_vendor 2>/dev/null)
    echo "Board Vendor:     $BOARD_VENDOR"
fi

# BIOS Vendor
if [ -f /sys/devices/virtual/dmi/id/bios_vendor ]; then
    BIOS_VENDOR=$(cat /sys/devices/virtual/dmi/id/bios_vendor 2>/dev/null)
    echo "BIOS Vendor:      $BIOS_VENDOR"
fi

# Chassis Vendor
if [ -f /sys/devices/virtual/dmi/id/chassis_vendor ]; then
    CHASSIS_VENDOR=$(cat /sys/devices/virtual/dmi/id/chassis_vendor 2>/dev/null)
    echo "Chassis Vendor:   $CHASSIS_VENDOR"
fi

# CPU Vendor
CPU_VENDOR=$(lscpu | grep -i "vendor" | head -1 | cut -d: -f2 | xargs)
echo "CPU Vendor:       $CPU_VENDOR"

# GPU Vendor (if available)
if command -v lspci &> /dev/null; then
    GPU_VENDOR=$(lspci | grep -i "vga\|3d\|display" | head -1 | cut -d: -f3 | xargs)
    echo "GPU Vendor:       ${GPU_VENDOR:-Not detected}"
fi

echo ""

# ======================
# 2. SERIAL NUMBERS
# ======================
echo "🔹 SERIAL NUMBERS"
echo "-----------------"

# System Serial
if [ -f /sys/devices/virtual/dmi/id/product_serial ]; then
    SERIAL=$(cat /sys/devices/virtual/dmi/id/product_serial 2>/dev/null)
    if [[ "$SERIAL" != "Not Specified" ]] && [[ "$SERIAL" != "None" ]] && [[ ! -z "$SERIAL" ]]; then
        echo "System Serial:    $SERIAL"
    fi
fi

# Board Serial
if [ -f /sys/devices/virtual/dmi/id/board_serial ]; then
    BOARD_SERIAL=$(cat /sys/devices/virtual/dmi/id/board_serial 2>/dev/null)
    if [[ "$BOARD_SERIAL" != "Not Specified" ]] && [[ "$BOARD_SERIAL" != "None" ]] && [[ ! -z "$BOARD_SERIAL" ]]; then
        echo "Board Serial:     $BOARD_SERIAL"
    fi
fi

# Chassis Serial
if [ -f /sys/devices/virtual/dmi/id/chassis_serial ]; then
    CHASSIS_SERIAL=$(cat /sys/devices/virtual/dmi/id/chassis_serial 2>/dev/null)
    if [[ "$CHASSIS_SERIAL" != "Not Specified" ]] && [[ "$CHASSIS_SERIAL" != "None" ]] && [[ ! -z "$CHASSIS_SERIAL" ]]; then
        echo "Chassis Serial:   $CHASSIS_SERIAL"
    fi
fi

# BIOS Serial
if [ -f /sys/devices/virtual/dmi/id/bios_version ]; then
    BIOS_SERIAL=$(cat /sys/devices/virtual/dmi/id/bios_version 2>/dev/null)
    echo "BIOS Version:     $BIOS_SERIAL"
fi

# Disk Serial Numbers (requires root)
echo ""
echo "💾 DISK SERIAL NUMBERS:"
if command -v lsblk &> /dev/null; then
    lsblk -o NAME,MODEL,SERIAL,SIZE,TYPE | grep -E "(disk|part)"
else
    echo "   Install 'lsblk' for disk information"
fi

echo ""

# ======================
# 3. HARDWARE INFORMATION
# ======================
echo "🔹 HARDWARE INFORMATION"
echo "-----------------------"

# CPU Information
echo "💻 PROCESSOR:"
echo "  $(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | xargs)"
echo "  Cores: $(nproc) | Threads: $(grep -c "processor" /proc/cpuinfo)"
echo "  Architecture: $(arch)"

# Memory Information
echo ""
echo "🧠 MEMORY:"
MEM_TOTAL=$(free -h | grep Mem | awk '{print $2}')
MEM_USED=$(free -h | grep Mem | awk '{print $3}')
MEM_FREE=$(free -h | grep Mem | awk '{print $4}')
echo "  Total: $MEM_TOTAL | Used: $MEM_USED | Free: $MEM_FREE"

# Disk Information
echo ""
echo "💿 STORAGE:"
if command -v df &> /dev/null; then
    df -h --total | grep -E "(Filesystem|total)"
fi

# GPU Information
echo ""
echo "🎮 GRAPHICS:"
if command -v lspci &> /dev/null; then
    lspci | grep -i "vga\|3d\|display" | while read line; do
        echo "  ${line:8}"
    done
fi

# Network Adapters
echo ""
echo "🌐 NETWORK ADAPTERS:"
if command -v lspci &> /dev/null; then
    lspci | grep -i "network\|ethernet\|wireless" | while read line; do
        echo "  ${line:8}"
    done
fi

# USB Devices
echo ""
echo "🔌 USB DEVICES:"
if command -v lsusb &> /dev/null; then
    lsusb | head -10 | while read line; do
        echo "  ${line:23}"
    done
    if [ $(lsusb | wc -l) -gt 10 ]; then
        echo "  ... and $(( $(lsusb | wc -l) - 10 )) more devices"
    fi
fi

echo ""

# ======================
# 4. OPERATING SYSTEM INFO
# ======================
echo "🔹 OPERATING SYSTEM INFORMATION"
echo "-------------------------------"

# OS Name and Version
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "Distribution:     $NAME"
    echo "Version:          $VERSION"
    echo "Codename:         $VERSION_CODENAME"
    echo "ID:               $ID"
fi

# Kernel Information
echo "Kernel:           $(uname -s) $(uname -r)"
echo "Kernel Release:   $(uname -v)"
echo "Architecture:     $(uname -m)"
echo "Hostname:         $(hostname)"

# Uptime
echo "Uptime:           $(uptime -p | sed 's/up //')"

# Users
echo ""
echo "👥 USER SESSIONS:"
echo "  Current user: $(whoami)"
echo "  Logged in users:"
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

# Temperature (if sensors available)
if command -v sensors &> /dev/null; then
    TEMP=$(sensors | grep -E "(Core|Package)" | head -2)
    if [ ! -z "$TEMP" ]; then
        echo "Temperature:"
        echo "$TEMP" | sed 's/^/  /'
    fi
fi

# Battery (for laptops)
if [ -d /sys/class/power_supply/ ]; then
    BATTERIES=$(find /sys/class/power_supply/ -name "BAT*" 2>/dev/null | head -1)
    if [ ! -z "$BATTERIES" ]; then
        echo "Battery:"
        for bat in $BATTERIES; do
            CAPACITY=$(cat $bat/capacity 2>/dev/null || echo "N/A")
            STATUS=$(cat $bat/status 2>/dev/null || echo "N/A")
            echo "  $(basename $bat): $CAPACITY% ($STATUS)"
        done
    fi
fi

echo ""
echo "==============================================="
echo "           END OF REPORT"
echo "==============================================="

# Optional: Save to file
read -p "💾 Save to file? (y/n): " save
if [[ $save == "y" || $save == "Y" ]]; then
    FILENAME="system-info-$(date +%Y%m%d-%H%M%S).txt"
    {
        echo "SYSTEM INFORMATION REPORT"
        echo "Generated: $(date)"
        echo "==============================================="
        [ -f /sys/devices/virtual/dmi/id/sys_vendor ] && echo "System Vendor: $(cat /sys/devices/virtual/dmi/id/sys_vendor)"
        [ -f /sys/devices/virtual/dmi/id/product_name ] && echo "Device Model: $(cat /sys/devices/virtual/dmi/id/product_name)"
        [ -f /sys/devices/virtual/dmi/id/product_serial ] && echo "System Serial: $(cat /sys/devices/virtual/dmi/id/product_serial)"
        echo ""
        echo "--- HARDWARE ---"
        lscpu | grep -E "(Model name|Architecture|CPU\(s\))"
        free -h
        echo ""
        echo "--- OS ---"
        cat /etc/os-release
        uname -a
    } > "$FILENAME"
    echo "Report saved to: $FILENAME"
fi

# Added your laptop model command at the end
echo ""
echo "=== LAPTOP MODEL (Direct Command) ==="
sudo dmidecode -s system-product-name 2>/dev/null || \
cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || \
echo "Model information not available"