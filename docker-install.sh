#!/bin/bash

# Docker Installation Script for Ubuntu 22.04
# Method 1: Using Docker's Official Repository

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run this script as root. Run as regular user and use sudo when needed."
    exit 1
fi

print_status "Starting Docker installation on Ubuntu 22.04..."

# Step 1: Update System and Install Dependencies
print_status "Updating system packages and installing dependencies..."
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Step 2: Add Docker's Official GPG Key
print_status "Adding Docker's official GPG key..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Step 3: Add Docker Repository
print_status "Adding Docker repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Step 4: Update package index and install Docker
print_status "Installing Docker Engine..."
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Step 5: Start and Enable Docker Service
print_status "Starting and enabling Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# Step 6: Add current user to docker group
print_status "Adding current user to docker group..."
sudo usermod -aG docker $USER

# Step 7: Verify Installation
print_status "Verifying Docker installation..."
sudo docker --version

print_status "Testing Docker with hello-world container..."
sudo docker run --rm hello-world

# Final instructions
echo ""
print_status "Docker installation completed successfully!"
print_warning "Please log out and log back in for group changes to take effect."
print_warning "After logging back in, you can run Docker commands without sudo."
echo ""
print_status "Useful commands to test after re-login:"
echo "  docker --version"
echo "  docker ps"
echo "  docker run hello-world"
echo ""
print_status "Docker Compose is also installed. Test with:"
echo "  docker compose version"

# Check if we can run docker without sudo (may not work until re-login)
if docker version >/dev/null 2>&1; then
    print_status "You can already run Docker commands without sudo!"
else
    print_warning "You need to log out and log back in to run Docker commands without sudo."
fi