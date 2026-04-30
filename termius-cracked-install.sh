#!/bin/bash

# Termius Patcher Script
# This script installs and patches Termius with Premium features

set -e  # Exit on error

echo "=========================================="
echo "Termius Premium Patcher"
echo "=========================================="

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "Please run with sudo: sudo ./termius-patcher.sh"
    exit 1
fi

# Step 1: Install megatools
echo "[1/12] Installing megatools..."
apt update
apt install megatools -y

# Step 2: Download Termius from Mega
echo "[2/12] Downloading Termius Horizontal Tabs.deb from Mega..."
mega-get https://mega.nz/file/pChTGTSZ#CqbOuVeiu5ZShlgkKobWponDfqA19H5vmoPkWhvX9Zs

# Step 3: Install Termius
echo "[3/12] Installing Termius Horizontal Tabs.deb..."
dpkg -i Termius\ Horizontal\ Tabs.deb || apt install -f -y

# Step 4: Install npm
echo "[4/12] Installing npm..."
apt install npm -y

# Step 5: Install asar
echo "[5/12] Installing asar..."
snap install asar --classic

# Step 6: Navigate to Termius resources
echo "[6/12] Navigating to Termius resources..."
cd "/opt/Termius Alpha/resources" || exit 1

# Step 7: Extract app.asar
echo "[7/12] Extracting app.asar..."
asar extract app.asar ./app

# Step 8: Backup and clean up
echo "[8/12] Creating backup and cleaning up..."
mv app.asar app.asar.bak
rm -f app-update.yml

# Step 9: Navigate to JS directory
echo "[9/12] Navigating to JS directory..."
cd "/opt/Termius Alpha/resources/app/js" || exit 1

# Step 10: Create backup of background-process.js
echo "[10/12] Creating backup of background-process.js..."
cp background-process.js background-process.js.bak

# Step 11: Apply patch
echo "[11/12] Applying Premium patch..."
sed -i 's/const e = await this\.api\.bulkAccount();/var e=await this.api.bulkAccount();e.account.pro_mode=true;e.account.need_to_update_subscription=false;e.account.current_period={"from":"2022-01-01T00:00:00","until":"2099-01-01T00:00:00"};e.account.plan_type="Premium";e.account.user_type="Premium";e.student=null;e.trial=null;e.account.authorized_features.show_trial_section=false;e.account.authorized_features.show_subscription_section=true;e.account.authorized_features.show_github_account_section=false;e.account.expired_screen_type=null;e.personal_subscription={"now":new Date().toISOString().slice(0,-5),"status":"SUCCESS","platform":"stripe","current_period":{"from":"2022-01-01T00:00:00","until":"2099-01-01T00:00:00"},"revokable":true,"refunded":false,"cancelable":true,"reactivatable":false,"currency":"usd","created_at":"2022-01-01T00:00:00","updated_at":new Date().toISOString().slice(0,-5),"valid_until":"2099-01-01T00:00:00","auto_renew":true,"price":12,"verbose_plan_name":"Termius Pro Monthly","plan_type":"SINGLE","is_expired":false};e.access_objects=[{"period":{"start":"2022-01-01T00:00:00","end":"2099-01-01T00:00:00"},"title":"Pro"}];/' background-process.js

# Step 12: Repack asar
#echo "[12/12] Repacking app.asar..."
#cd "/opt/Termius Alpha/resources" || exit 1
#asar pack ./app app.asar

# Cleanup (optional)
#echo "Cleaning up temporary files..."
#rm -rf ./app

echo "=========================================="
echo "Termius patching completed successfully!"
echo "You can now launch Termius with Premium features"
echo "=========================================="

# Optional: Remove npm and asar
read -p "Do you want to remove npm and asar? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing npm and asar..."
    apt remove npm -y
    snap remove asar
    echo "npm and asar removed."
fi

exit 0
