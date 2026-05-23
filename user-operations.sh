#!/bin/bash

# =========================================
# User Management Script
# =========================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# =========================================
# Functions
# =========================================

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# =========================================
# Check Root
# =========================================

if [[ $EUID -ne 0 ]]; then
    print_error "Please run as root"
    exit 1
fi

# =========================================
# Menu
# =========================================

echo "================================="
echo "      USER MANAGEMENT"
echo "================================="
echo "1. Add User"
echo "2. Remove User"
echo "3. Change Username"
echo "4. List Users"
echo "5. Reset Password"
echo "6. Lock User"
echo "7. Unlock User"
echo

read -p "Select option [1-7]: " choice

# =========================================
# ADD USER
# =========================================

if [[ "$choice" == "1" ]]; then

    echo
    echo "===== Add User ====="

    read -p "Enter username: " username

    if [[ -z "$username" ]]; then
        print_error "Username cannot be empty"
        exit 1
    fi

    if id "$username" &>/dev/null; then
        print_error "User already exists"
        exit 1
    fi

    read -s -p "Enter password: " password
    echo

    read -s -p "Confirm password: " confirm_password
    echo

    if [[ "$password" != "$confirm_password" ]]; then
        print_error "Passwords do not match"
        exit 1
    fi

    read -p "Create as sudo user? (y/n): " sudo_user

    useradd -m -s /bin/bash "$username"

    if [[ $? -ne 0 ]]; then
        print_error "Failed to create user"
        exit 1
    fi

    echo "$username:$password" | chpasswd

    if [[ "$sudo_user" =~ ^[Yy]$ ]]; then
        usermod -aG sudo "$username"
        print_success "Super user created successfully"
    else
        print_success "Normal user created successfully"
    fi

# =========================================
# REMOVE USER
# =========================================

elif [[ "$choice" == "2" ]]; then

    echo
    echo "===== Remove User ====="

    read -p "Enter username to remove: " username

    if ! id "$username" &>/dev/null; then
        print_error "User does not exist"
        exit 1
    fi

    if [[ "$username" == "root" ]]; then
        print_error "Cannot remove root user"
        exit 1
    fi

    read -p "Remove home directory? (y/n): " remove_home

    read -p "Type YES to confirm deletion: " confirm

    if [[ "$confirm" != "YES" ]]; then
        print_info "Cancelled"
        exit 0
    fi

    if [[ "$remove_home" =~ ^[Yy]$ ]]; then
        userdel -r "$username"
    else
        userdel "$username"
    fi

    if [[ $? -eq 0 ]]; then
        print_success "User removed successfully"
    else
        print_error "Failed to remove user"
    fi

# =========================================
# CHANGE USERNAME
# =========================================

elif [[ "$choice" == "3" ]]; then

    echo
    echo "===== Change Username ====="

    read -p "Current username: " old_user

    if ! id "$old_user" &>/dev/null; then
        print_error "User does not exist"
        exit 1
    fi

    read -p "New username: " new_user

    if id "$new_user" &>/dev/null; then
        print_error "New username already exists"
        exit 1
    fi

    usermod -l "$new_user" "$old_user"
    usermod -d "/home/$new_user" -m "$new_user"

    if [[ $? -eq 0 ]]; then
        print_success "Username changed successfully"
    else
        print_error "Failed to change username"
    fi

# =========================================
# LIST USERS
# =========================================

elif [[ "$choice" == "4" ]]; then

    echo
    echo "===== System Users ====="
    echo

    awk -F: '$3 >= 1000 && $1 != "nobody" {
        print "User: " $1 " | UID: " $3 " | Home: " $6
    }' /etc/passwd

# =========================================
# RESET PASSWORD
# =========================================

elif [[ "$choice" == "5" ]]; then

    echo
    echo "===== Reset Password ====="

    read -p "Enter username: " username

    if ! id "$username" &>/dev/null; then
        print_error "User does not exist"
        exit 1
    fi

    read -s -p "Enter new password: " password
    echo

    echo "$username:$password" | chpasswd

    if [[ $? -eq 0 ]]; then
        print_success "Password updated successfully"
    else
        print_error "Failed to reset password"
    fi

# =========================================
# LOCK USER
# =========================================

elif [[ "$choice" == "6" ]]; then

    echo
    echo "===== Lock User ====="

    read -p "Enter username: " username

    if ! id "$username" &>/dev/null; then
        print_error "User does not exist"
        exit 1
    fi

    usermod -L "$username"

    if [[ $? -eq 0 ]]; then
        print_success "User locked successfully"
    else
        print_error "Failed to lock user"
    fi

# =========================================
# UNLOCK USER
# =========================================

elif [[ "$choice" == "7" ]]; then

    echo
    echo "===== Unlock User ====="

    read -p "Enter username: " username

    if ! id "$username" &>/dev/null; then
        print_error "User does not exist"
        exit 1
    fi

    usermod -U "$username"

    if [[ $? -eq 0 ]]; then
        print_success "User unlocked successfully"
    else
        print_error "Failed to unlock user"
    fi

# =========================================
# INVALID OPTION
# =========================================

else
    print_error "Invalid option"
fi
