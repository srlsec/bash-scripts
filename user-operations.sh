#!/bin/bash

# =========================================
# User Management System
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

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

pause() {
    read -p "Press Enter to continue..."
}

# Check root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Please run as root!"
        exit 1
    fi
}

# Check if user exists
user_exists() {
    id "$1" &>/dev/null
}

# =========================================
# Add User
# =========================================

add_user() {

    echo
    echo -e "${YELLOW}=== Add User ===${NC}"

    read -p "Enter username: " username

    if [[ -z "$username" ]]; then
        print_error "Username cannot be empty"
        return
    fi

    if user_exists "$username"; then
        print_error "User already exists"
        return
    fi

    read -s -p "Enter password: " password
    echo

    read -s -p "Confirm password: " confirm_password
    echo

    if [[ "$password" != "$confirm_password" ]]; then
        print_error "Passwords do not match"
        return
    fi

    useradd -m -s /bin/bash "$username"

    if [[ $? -ne 0 ]]; then
        print_error "Failed to create user"
        return
    fi

    echo "$username:$password" | chpasswd

    read -p "Add to sudo group? (y/n): " add_sudo

    if [[ "$add_sudo" =~ ^[Yy]$ ]]; then
        usermod -aG sudo "$username"
        print_info "Added to sudo group"
    fi

    print_success "User created successfully"
}

# =========================================
# Remove User
# =========================================

remove_user() {

    echo
    echo -e "${YELLOW}=== Remove User ===${NC}"

    read -p "Enter username to remove: " username

    if ! user_exists "$username"; then
        print_error "User does not exist"
        return
    fi

    if [[ "$username" == "root" ]]; then
        print_error "Cannot remove root user"
        return
    fi

    read -p "Delete home directory? (y/n): " remove_home

    echo
    print_warning "This action cannot be undone!"
    read -p "Type YES to confirm: " confirm

    if [[ "$confirm" != "YES" ]]; then
        print_warning "Cancelled"
        return
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
}

# =========================================
# Change Username
# =========================================

change_username() {

    echo
    echo -e "${YELLOW}=== Change Username ===${NC}"

    read -p "Current username: " old_user

    if ! user_exists "$old_user"; then
        print_error "User does not exist"
        return
    fi

    read -p "New username: " new_user

    if user_exists "$new_user"; then
        print_error "New username already exists"
        return
    fi

    old_home=$(getent passwd "$old_user" | cut -d: -f6)
    new_home="/home/$new_user"

    usermod -l "$new_user" "$old_user"
    usermod -d "$new_home" -m "$new_user"

    if [[ $? -eq 0 ]]; then
        print_success "Username changed successfully"
    else
        print_error "Failed to change username"
    fi
}

# =========================================
# List Users
# =========================================

list_users() {

    echo
    echo -e "${YELLOW}=== System Users ===${NC}"

    awk -F: '$3 >= 1000 && $1 != "nobody" {
        print "User: " $1 " | UID: " $3 " | Home: " $6
    }' /etc/passwd
}

# =========================================
# Reset Password
# =========================================

reset_password() {

    echo
    echo -e "${YELLOW}=== Reset Password ===${NC}"

    read -p "Enter username: " username

    if ! user_exists "$username"; then
        print_error "User does not exist"
        return
    fi

    read -s -p "Enter new password: " password
    echo

    echo "$username:$password" | chpasswd

    if [[ $? -eq 0 ]]; then
        print_success "Password updated successfully"
    else
        print_error "Failed to update password"
    fi
}

# =========================================
# Main Menu
# =========================================

main_menu() {

    while true
    do
        clear

        echo -e "${GREEN}"
        echo "===================================="
        echo "      USER MANAGEMENT SYSTEM"
        echo "===================================="
        echo -e "${NC}"

        echo "1. Add User"
        echo "2. Remove User"
        echo "3. Change Username"
        echo "4. List Users"
        echo "5. Reset Password"
        echo "6. Exit"
        echo

        read -p "Select option [1-6]: " choice

        case $choice in
            1)
                add_user
                ;;
            2)
                remove_user
                ;;
            3)
                change_username
                ;;
            4)
                list_users
                ;;
            5)
                reset_password
                ;;
            6)
                print_info "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid option"
                ;;
        esac

        echo
        pause
    done
}

# =========================================
# Start Script
# =========================================

check_root
main_menu
