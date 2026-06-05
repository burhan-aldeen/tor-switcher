# 🔄 Tor Switcher

**One-command Tor setup + automatic IP rotation for Kali Linux**

Automate everything from zero: install Tor, configure ControlPort for circuit switching, enable system-wide SOCKS5 proxy, and rotate your exit IP every 10 seconds.

---

## Quick Start

```bash
# 1. Clone and install
git clone https://github.com/burhan-aldeen/tor-switcher.git
cd tor-switcher
chmod +x tor_switcher.sh

# 2. Full auto setup (install Tor + configure)
sudo ./tor_switcher setup

# 3. Enable Tor proxy + auto IP rotation
./tor_switcher on

# 4. Verify
curl --socks5 127.0.0.1:9050 ifconfig.me

# 5. Restore normal network
./tor_switcher off
```

### One-liner install

```bash
bash <(curl -s https://raw.githubusercontent.com/adx0/tor-switcher/main/tor_switcher.sh) setup
```

---

## Commands

| Command | Description |
|---------|-------------|
| `setup` | Install Tor, write torrc, start service |
| `on` | Enable SOCKS5 proxy + start IP rotation (every 10s) |
| `off` | Restore default network + stop rotator |
| `status` | Show Tor listeners + current exit IP |

---

## How it works

```
┌─────────────────────────────────────────────────┐
│                 tor_switcher                     │
├─────────────────────────────────────────────────┤
│ setup → installs tor + writes /etc/tor/torrc    │
│         with ControlPort 9051 + CookieAuth       │
├─────────────────────────────────────────────────┤
│ on    → gsettings set system proxy = SOCKS5:9050  │
│         + starts IP rotator in background         │
├──────────────────────────────────────────────────┤
│ off   → gsettings set proxy = none                │
│         + kills rotator process                   │
├──────────────────────────────────────────────────┤
│ rotator (auto via on) → connects to ControlPort   │
│           sends NEWNYM every 10 seconds            │
│           changes Tor exit node → new IP           │
└─────────────────────────────────────────────────┘
```

### Tor control protocol

The script uses Tor's control protocol to request new circuits:

```
> AUTHENTICATE <cookie>
> SIGNAL NEWNYM
```

This forces Tor to build a new circuit, giving you a different exit node (and IP).

---

## Firewall / Browser

- **Firefox**: set SOCKS5 `127.0.0.1:9050` + "Proxy DNS when using SOCKS v5"
- **Brave/Chrome**: `brave-browser --proxy-server="socks5://127.0.0.1:9050"`
- **proxychains**: `proxychains4 -q firefox`
- **torsocks**: `torsocks brave-browser`

Or just use `tor_switcher on` — it sets the **system-wide Gnome proxy**, so every app respects it.

---

## Requirements

- Kali Linux / Debian-based (apt)
- systemd
- gsettings (Gnome)
- xxd, nc (netcat)

All installed automatically by `setup`.

---

## Security Notes

- ⚠️ Changing IP every 10s is aggressive — Tor may rate-limit you
- ⚠️ Some sites block known Tor exit nodes
- ⚠️ This does NOT make you 100% anonymous — Tor is a tool, not a magic wand
- ✅ CookieAuth is used (no plaintext password in torrc)

---

## Uninstall

```bash
sudo apt remove tor -y
sudo rm /etc/tor/torrc
rm ~/.tor_rotator.sh
```

---

## 📸 Demo

```text
$ tor_switcher setup
[*] Installing Tor...
[*] Configuring torrc...
[+] Tor installed and running
[+] SOCKS5 : 127.0.0.1:9050
[+] Control: 127.0.0.1:9051

$ tor_switcher on
[+] Enabling Tor proxy...
[+] Tor proxy active

$ tor_switcher on
[+] Enabling Tor proxy...
[+] Tor proxy active
[+] IP rotator started (every 10s)
[Fri Jun  5 04:30:00 CEST 2026] 🔄 IP rotated → 87.118.116.103
[Fri Jun  5 04:30:10 CEST 2026] 🔄 IP rotated → 64.190.76.13
[Fri Jun  5 04:30:20 CEST 2026] 🔄 IP rotated → 192.42.116.45

$ tor_switcher off
[+] Default restored
```

---

## License

MIT
