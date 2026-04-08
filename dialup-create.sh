
# Optional: Ask if user wants to create a PPPoE connection
read -rp "🌐 Do you want to create a PPPoE connection? (y/n): " CREATE_PPPOE
if [[ "$CREATE_PPPOE" =~ ^[Yy]$ ]]; then
    read -rp "Enter interface name (e.g., eth0, enp2s0): " INTERFACE
    read -rp "Enter PPPoE username: " PPPOE_USER
    read -rsp "Enter PPPoE password: " PPPOE_PASS
    echo
    
    if nmcli connection show "Dialup connection" &>/dev/null; then
        echo "⚠️ Connection 'Dialup connection' already exists. Skipping..."
    else
        sudo nmcli connection add type pppoe con-name "Dialup connection" \
            ifname "$INTERFACE" username "$PPPOE_USER" password "$PPPOE_PASS"
        echo "✅ PPPoE connection created."
    fi
fi
