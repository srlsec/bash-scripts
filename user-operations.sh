#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display colored output
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
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Check if script is run as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root!"
        exit 1
    fi
}

# Function to clean input (remove carriage returns and extra whitespace)
clean_input() {
    local input="$1"
    echo "$input" | tr -d '\r' | xargs
}

# Function to check if user exists
user_exists() {
    id "$1" &>/dev/null
    return $?
}

# Function to add a new user
add_user() {
    echo -e "\n${YELLOW}=== Add New User ===${NC}"
    read -p "Enter username: " username
    username=$(clean_input "$username")
    
    if [[ -z "$username" ]]; then
        print_error "Username cannot be empty!"
        return 1
    fi
    
    if user_exists "$username"; then
        print_error "User '$username' already exists!"
        return 1
    fi
    
    read -s -p "Enter password: " password
    echo
    read -s -p "Confirm password: " password_confirm
    echo
    
    password=$(clean_input "$password")
    password_confirm=$(clean_input "$password_confirm")
    
    if [[ "$password" != "$password_confirm" ]]; then
        print_error "Passwords do not match!"
        return 1
    fi
    
    if [[ -z "$password" ]]; then
        print_warning "Password is empty! Setting random password..."
        password=$(openssl rand -base64 12)
        print_info "Random password: $password"
    fi
    
    # Create user with home directory and bash shell
    useradd -m -s /bin/bash "$username"
    
    if [[ $? -eq 0 ]]; then
        echo "$username:$password" | chpasswd
        print_success "User '$username' created successfully!"
        
        # Optional: add to additional groups
        read -p "Add user to additional groups (comma-separated, e.g., sudo,www-data): " groups
        groups=$(clean_input "$groups")
        if [[ -n "$groups" ]]; then
            usermod -aG "$groups" "$username"
            print_success "User added to groups: $groups"
        fi
        
        # Set password expiration
        read -p "Set password expiration (days, 0 for never): " expire_days
        expire_days=$(clean_input "$expire_days")
        if [[ "$expire_days" =~ ^[0-9]+$ ]] && [[ "$expire_days" -gt 0 ]]; then
            chage -M "$expire_days" "$username"
            print_info "Password will expire in $expire_days days"
        fi
    else
        print_error "Failed to create user '$username'!"
        return 1
    fi
}

# Function to remove user
remove_user() {
    echo -e "\n${YELLOW}=== Remove User ===${NC}"
    read -p "Enter username to remove: " username
    username=$(clean_input "$username")
    
    if [[ -z "$username" ]]; then
        print_error "Username cannot be empty!"
        return 1
    fi
    
    if ! user_exists "$username"; then
        print_error "User '$username' does not exist!"
        return 1
    fi
    
    # Don't allow removing important system users
    if [[ "$username" == "root" ]] || [[ "$username" == "bin" ]] || [[ "$username" == "daemon" ]]; then
        print_error "Cannot remove system user '$username'!"
        return 1
    fi
    
    echo -e "${RED}WARNING: You are about to delete user '$username'${NC}"
    read -p "Remove home directory? (y/n): " remove_home
    remove_home=$(clean_input "$remove_home")
    read -p "Remove mail spool? (y/n): " remove_mail
    remove_mail=$(clean_input "$remove_mail")
    read -p "Confirm deletion (type 'yes' to confirm): " confirm
    confirm=$(clean_input "$confirm")
    
    if [[ "$confirm" != "yes" ]]; then
        print_warning "User deletion cancelled"
        return 0
    fi
    
    # Build removal options
    options=""
    if [[ "$remove_home" =~ ^[Yy]$ ]]; then
        options="-r"
        print_info "Will remove home directory"
    fi
    
    if [[ "$remove_mail" =~ ^[Yy]$ ]]; then
        options="$options -f"
        print_info "Will remove mail spool"
    fi
    
    userdel $options "$username"
    
    if [[ $? -eq 0 ]]; then
        print_success "User '$username' removed successfully!"
    else
        print_error "Failed to remove user '$username'!"
        return 1
    fi
}

# Function to change username
change_username() {
    echo -e "\n${YELLOW}=== Change Username ===${NC}"
    read -p "Enter current username: " old_username
    old_username=$(clean_input "$old_username")
    
    if [[ -z "$old_username" ]]; then
        print_error "Username cannot be empty!"
        return 1
    fi
    
    if ! user_exists "$old_username"; then
        print_error "User '$old_username' does not exist!"
        return 1
    fi
    
    # Don't allow renaming root or important system users
    if [[ "$old_username" == "root" ]]; then
        print_error "Cannot rename root user!"
        return 1
    fi
    
    read -p "Enter new username: " new_username
    new_username=$(clean_input "$new_username")
    
    if [[ -z "$new_username" ]]; then
        print_error "New username cannot be empty!"
        return 1
    fi
    
    if user_exists "$new_username"; then
        print_error "User '$new_username' already exists!"
        return 1
    fi
    
    # Get current home directory
    old_home=$(getent passwd "$old_username" | cut -d: -f6)
    new_home="${old_home%/*}/$new_username"
    
    print_info "Current home directory: $old_home"
    print_info "New home directory: $new_home"
    
    # Kill all user processes (to avoid issues)
    pkill -u "$old_username" 2>/dev/null
    
    # Change username, group, and home directory
    usermod -l "$new_username" "$old_username" 2>/dev/null
    usermod -d "$new_home" -m "$new_username" 2>/dev/null
    groupmod -n "$new_username" "$old_username" 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        print_success "Username changed from '$old_username' to '$new_username'!"
        print_info "Home directory: $new_home"
    else
        print_error "Failed to change username!"
        return 1
    fi
}

# Function to list all users
list_users() {
    echo -e "\n${YELLOW}=== System Users ===${NC}"
    echo -e "${GREEN}Regular users (UID >= 1000):${NC}"
    awk -F: '$3>=1000 && $3<65534 {print "  - " $1 " (UID: " $3 ", Home: " $6 ")"}' /etc/passwd
    
    echo -e "\n${YELLOW}Recent user additions (last 10):${NC}"
    ls -lt /home/ 2>/dev/null | head -10 | tail -n +2 | awk '{print "  - " $9}'
}

# Main menu
main_menu() {
    while true; do
        echo -e "\n${YELLOW}================================${NC}"
        echo -e "${GREEN}     User Management System${NC}"
        echo -e "${YELLOW}================================${NC}"
        echo "1. Add New User"
        echo "2. Remove User"
        echo "3. Change Username"
        echo "4. List All Users"
        echo "5. Exit"
        echo -e "${YELLOW}================================${NC}"
        read -p "Enter your choice [1-5]: " choice
        choice=$(clean_input "$choice")
        
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
                print_info "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid choice! Please enter 1-5"
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
}

# Main execution
check_root
main_menu
