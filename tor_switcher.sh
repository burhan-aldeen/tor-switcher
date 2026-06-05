#!/bin/bash
# ============================================
# Tor Switcher - Complete Tor Automation
# https://github.com/adx0/tor-switcher
# ============================================
# Usage:
#   tor_switcher setup   - full install + configure
#   tor_switcher on      - enable Tor system proxy
#   tor_switcher off     - restore normal network
#   tor_switcher rotator - rotate IP every 10s
#   tor_switcher status  - check Tor status
# ============================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
TORRC="/etc/tor/torrc"
ROTATOR="$HOME/.tor_rotator.sh"

setup() {
    echo -e "${YELLOW}[*] Installing Tor...${NC}"
    sudo apt update -qq && sudo apt install tor -y -qq

    echo -e "${YELLOW}[*] Configuring torrc...${NC}"
    sudo bash -c "cat >> $TORRC" << 'EOF'

# === Added by tor-switcher ===
ControlPort 9051
CookieAuthentication 1
CookieAuthFile /run/tor/control.authcookie
CookieAuthFileGroupReadable 1
DataDirectory /var/lib/tor
EOF

    sudo systemctl restart tor@default
    sleep 2

    echo -e "${GREEN}[+] Tor installed and running${NC}"
    echo -e "${GREEN}[+] SOCKS5 : 127.0.0.1:9050${NC}"
    echo -e "${GREEN}[+] Control: 127.0.0.1:9051${NC}"
}

create_rotator() {
    cat > "$ROTATOR" << 'RSEOF'
#!/bin/bash
COOKIE="/run/tor/control.authcookie"
INTERVAL=10
while true; do
    HEX=$(sudo xxd -p -c 32 "$COOKIE" 2>/dev/null)
    printf 'AUTHENTICATE %s\r\nSIGNAL NEWNYM\r\nQUIT\r\n' "$HEX" | nc 127.0.0.1 9051 2>/dev/null
    echo "[$(date)] 🔄 IP rotated"
    sleep $INTERVAL
done
RSEOF
    chmod +x "$ROTATOR"
}

proxy_on() {
    echo -e "${GREEN}[+] Enabling Tor proxy...${NC}"
    gsettings set org.gnome.system.proxy mode 'manual'
    gsettings set org.gnome.system.proxy.socks host '127.0.0.1'
    gsettings set org.gnome.system.proxy.socks port 9050
    echo -e "${GREEN}[+] Tor proxy active${NC}"
    echo -e "${YELLOW}[i] Test: curl --socks5 127.0.0.1:9050 ifconfig.me${NC}"
}

proxy_off() {
    echo -e "${GREEN}[+] Restoring default network...${NC}"
    gsettings set org.gnome.system.proxy mode 'none'
    echo -e "${GREEN}[+] Default restored${NC}"
}

status() {
    echo -e "${YELLOW}[*] Tor listeners:${NC}"
    sudo ss -tlnp 2>/dev/null | grep -E '9050|9051' | while read line; do echo "  $line"; done

    TOR_IP=$(curl -s --socks5 127.0.0.1:9050 ifconfig.me 2>/dev/null)
    if [ -n "$TOR_IP" ]; then
        echo -e "${GREEN}[+] Tor IP: $TOR_IP${NC}"
    else
        echo -e "${RED}[-] Tor not reachable${NC}"
    fi
}

case "$1" in
    setup)
        setup
        create_rotator
        status
        echo ""
        echo -e "${GREEN}✔ Setup complete!${NC}"
        echo "  tor_switcher on       → enable system proxy"
        echo "  tor_switcher rotator & → rotate IP every 10s"
        echo "  tor_switcher off      → restore normal"
        ;;
    on)
        proxy_on
        ;;
    off)
        proxy_off
        ;;
    rotator)
        if [ ! -f "$ROTATOR" ]; then
            echo -e "${YELLOW}[*] Creating rotator script...${NC}"
            create_rotator
        fi
        echo -e "${YELLOW}[*] Rotating IP every 10s...${NC}"
        exec "$ROTATOR"
        ;;
    status)
        status
        ;;
    *)
        echo "Tor Switcher - Complete Tor Automation"
        echo ""
        echo "Usage: tor_switcher COMMAND"
        echo "  setup   - full install Tor + configure + create rotator"
        echo "  on      - enable Tor as system-wide proxy"
        echo "  off     - restore normal network settings"
        echo "  rotator - rotate Tor exit IP every 10 seconds"
        echo "  status  - check Tor SOCKS/Control listeners + current IP"
        ;;
esac
