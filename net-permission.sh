#!/bin/bash
set -e
# Check if run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ This script must be run as root."
    exit 1
fi

# Ask for username
read -rp "👤 Enter the username to allow GUI IP changes: " USERNAME

# Check if user exists
if ! id "$USERNAME" &>/dev/null; then
    echo "❌ User '$USERNAME' does not exist. Exiting."
    exit 1
fi

echo "📦 Creating 'network' group (if it doesn't exist)..."
groupadd -f network

echo "👤 Adding user '$USERNAME' to 'network' group..."
usermod -aG network "$USERNAME"

POLKIT_RULE_PATH="/etc/polkit-1/rules.d/50-network.rules"

echo "🛠️ Creating Polkit rule to allow GUI IP changes for 'network' group..."
cat > "$POLKIT_RULE_PATH" << 'EOF'
polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.NetworkManager.settings.modify.system") &&
        subject.isInGroup("network")) {
        return polkit.Result.YES;
    }
});
EOF

echo "🔒 Setting correct permissions..."
chmod 644 "$POLKIT_RULE_PATH"

echo "🔁 Restarting polkit and NetworkManager..."
systemctl restart polkit
systemctl restart NetworkManager

echo "✅ Setup complete!"
echo "ℹ️ Log out and log back in as user '$USERNAME' for changes to take effect."
