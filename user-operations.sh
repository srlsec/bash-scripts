#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# Check root
if [[ $EUID -ne 0 ]]; then
    print_error "Run this script as root"
    exit 1
fi

echo "================================="
echo "      USER MANAGEMENT"
echo "================================="
echo "1. Add User"
echo "2. Remove User"
echo "3. Change Username"
echo "4. List Users"
echo "5. Reset Password"
echo

read -p "Select option [1-5]: " choice

# =========================================
# ADD USER
# =========================================

if [[ "$choice" == "1" ]]; then

    read -p "Enter username: " username

    if id "$username" &>/dev/null; then
        print_error "User already exists"
        exit 1
    fi

    read -s -p "Enter password: " password
    echo

    useradd -m -s /bin/bash "$username"

    echo "$username:$password" | chpasswd

    print_success "User created successfully"

# =========================================
# REMOVE USER
# =========================================

elif [[ "$choice" == "2" ]]; then

    read -p "Enter username to remove: " username

    if ! id "$username" &>/dev/null; then
        print_error "User does not exist"
        exit 1
    fi

    read -p "Remove home directory? (y/n): " remove_home

    if [[ "$remove_home" =~ ^[Yy]$ ]]; then
        userdel -r "$username"
    else
        userdel "$username"
    fi

    print_success "User removed successfully"

# =========================================
# CHANGE USERNAME
# =========================================

elif [[ "$choice" == "3" ]]; then

    read -p "Current username: " old_user

    if ! id "$old_user" &>/dev/null; then
        print_error "User does not exist"
        exit 1
    fi

    read -p "New username: " new_user

    usermod -l "$new_user" "$old_user"
    usermod -d "/home/$new_user" -m "$new_user"

    print_success "Username changed successfully"

# =========================================
# LIST USERS
# =========================================

elif [[ "$choice" == "4" ]]; then

    echo
    echo "System Users:"
    echo

    awk -F: '$3 >= 1000 && $1 != "nobody" {
        print "User: " $1 " | UID: " $3 " | Home: " $6
    }' /etc/passwd

# =========================================
# RESET PASSWORD
# =========================================

elif [[ "$choice" == "5" ]]; then

    read -p "Enter username: " username

    if ! id "$username" &>/dev/null; then
        print_error "User does not exist"
        exit 1
    fi

    read -s -p "Enter new password: " password
    echo

    echo "$username:$password" | chpasswd

    print_success "Password updated successfully"

else
    print_error "Invalid option"
fi
