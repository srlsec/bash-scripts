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

# Function to validate username
validate_username() {
    [[ "$1" =~ ^[a-z_][a-z0-9_-]*[$]?$ ]]
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

    if [[ -z "$username" ]]; then
        print_error "Username cannot be empty!"
        return 1
    fi

    if ! validate_username "$username"; then
        print_error "Invalid username format!"
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

    if [[ "$password" != "$password_confirm" ]]; then
        print_error "Passwords do not match!"
        return 1
    fi

    if [[ -z "$password" ]]; then
        print_warning "Password is empty! Setting random password..."
        password=$(openssl rand -base64 12)
        print_info "Random password: $password"
    fi

    # Create user
    useradd -m -s /bin/bash "$username"

    if [[ $? -ne 0 ]]; then
        print_error "Failed to create user '$username'!"
        return 1
    fi

    echo "$username:$password" | chpasswd

    print_success "User '$username' created successfully!"

    # User type selection
    echo
    echo "Select user type:"
    echo "1. Normal User"
    echo "2. Sudo User"

    read -p "Enter choice [1-2]: " user_type

    case $user_type in
        1)
            print_info "Normal user created"
            ;;
        2)
            usermod -aG sudo "$username"
            print_success "User added to sudo group"
            ;;
        *)
            print_warning "Invalid choice. User created as normal user."
            ;;
    esac

    # Additional groups
    read -p "Add user to additional groups (comma-separated, e.g., docker,www-data): " groups

    if [[ -n "$groups" ]]; then
        usermod -aG "$groups" "$username"

        if [[ $? -eq 0 ]]; then
            print_success "User added to groups: $groups"
        else
            print_error "Failed to add groups!"
        fi
    fi

    # Password expiration
    read -p "Set password expiration (days, 0 for never): " expire_days

    if [[ "$expire_days" =~ ^[0-9]+$ ]] && [[ "$expire_days" -gt 0 ]]; then
        chage -M "$expire_days" "$username"
        print_info "Password will expire in $expire_days days"
    fi
}

# Function to remove user
remove_user() {
    echo -e "\n${YELLOW}=== Remove User ===${NC}"

    read -p "Enter username to remove: " username

    if [[ -z "$username" ]]; then
        print_error "Username cannot be empty!"
        return 1
    fi

    if ! user_exists "$username"; then
        print_error "User '$username' does not exist!"
        return 1
    fi

    # Prevent removing important users
    if [[ "$username" == "root" ]] || [[ "$username" == "bin" ]] || [[ "$username" == "daemon" ]]; then
        print_error "Cannot remove system user '$username'!"
        return 1
    fi

    # Prevent deleting current sudo user
    if [[ "$username" == "$SUDO_USER" ]]; then
        print_error "Cannot delete currently logged-in sudo user!"
        return 1
    fi

    echo -e "${RED}WARNING: You are about to delete user '$username'${NC}"

    read -p "Remove home directory? (y/n): " remove_home
    read -p "Force remove user files? (y/n): " force_remove
    read -p "Confirm deletion (type 'yes' to confirm): " confirm

    if [[ "$confirm" != "yes" ]]; then
        print_warning "User deletion cancelled"
        return 0
    fi

    options=""

    if [[ "$remove_home" =~ ^[Yy]$ ]]; then
        options="-r"
        print_info "Home directory will be removed"
    fi

    if [[ "$force_remove" =~ ^[Yy]$ ]]; then
        options="$options -f"
        print_info "Force removal enabled"
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

    if [[ -z "$old_username" ]]; then
        print_error "Username cannot be empty!"
        return 1
    fi

    if ! user_exists "$old_username"; then
        print_error "User '$old_username' does not exist!"
        return 1
    fi

    if [[ "$old_username" == "root" ]]; then
        print_error "Cannot rename root user!"
        return 1
    fi

    read -p "Enter new username: " new_username

    if [[ -z "$new_username" ]]; then
        print_error "New username cannot be empty!"
        return 1
    fi

    if ! validate_username "$new_username"; then
        print_error "Invalid new username format!"
        return 1
    fi

    if user_exists "$new_username"; then
        print_error "User '$new_username' already exists!"
        return 1
    fi

    old_home=$(getent passwd "$old_username" | cut -d: -f6)
    new_home="${old_home%/*}/$new_username"

    print_info "Current home directory: $old_home"
    print_info "New home directory: $new_home"

    # Kill user processes
    pkill -u "$old_username" 2>/dev/null

    # Rename user
    if usermod -l "$new_username" "$old_username" &&
       usermod -d "$new_home" -m "$new_username"; then

        old_group=$(id -gn "$new_username")
        groupmod -n "$new_username" "$old_group" 2>/dev/null

        print_success "Username changed successfully!"
        print_info "New username: $new_username"
        print_info "Home directory: $new_home"
    else
        print_error "Failed to change username!"
        return 1
    fi
}

# Function to list all users
list_users() {
    echo -e "\n${YELLOW}=== System Users ===${NC}"

    awk -F: '$3>=1000 && $3<65534 {
        print " - " $1 " | UID: " $3 " | Home: " $6
    }' /etc/passwd
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
