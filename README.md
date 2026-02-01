# DNS-Protekt

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Windows-blue.svg)](https://github.com/nicthegarden/DNS-Proteck)

DNS-Protekt is a security tool that automatically blocks malicious domains by maintaining and updating your system's hosts file with community-curated blocklists.

## Features

- **Automatic Protection**: Blocks known malicious, ad, and tracking domains
- **Cross-Platform**: Works on both Windows and Linux systems
- **Systemd Integration** (Linux): Automatic updates on boot and daily schedule
- **Backup & Restore**: Always maintains backups of your original hosts file
- **Logging**: Comprehensive logging for troubleshooting
- **DNS Verification**: Ensures legitimate domains still resolve after updates
- **Customizable**: Configurable blocklist sources and whitelist
- **Security**: Hardened systemd service with sandboxing

## Quick Start

### Linux Installation

```bash
# Clone or download the repository
git clone https://github.com/nicthegarden/DNS-Proteck.git
cd DNS-Proteck

# Run the installer
sudo ./install.sh
```

### Windows Installation

1. Download `DNS-Protekt.exe` from the releases page
2. Run as Administrator
3. The scheduled task will be created automatically

## How It Works

DNS-Protekt downloads a curated blocklist of malicious domains from trusted sources and appends them to your system's `/etc/hosts` file (Linux) or `C:\Windows\System32\drivers\etc\hosts` (Windows). By pointing these domains to `127.0.0.1` or `0.0.0.0`, all DNS requests to these domains are blocked at the system level, preventing connections to malicious sites.

### Default Blocklist Source

- **someonewhocares.org**: A comprehensive, regularly updated hosts file blocking ads, malware, and tracking domains

### Alternative Blocklist Sources

You can configure DNS-Protekt to use different blocklist sources:

- [StevenBlack's hosts](https://github.com/StevenBlack/hosts) - Unified hosts file with extensions
- [Malware Domain List](https://www.malwaredomainlist.com/) - Focused on malware domains
- [NoCoin Filter List](https://github.com/hoshsadiq/adblock-nocoin-list) - Blocks cryptocurrency miners

## Linux Usage

### Management Commands

```bash
# Update blocklist manually
sudo dns-protekt update

# Check statistics
sudo dns-protekt stats

# Restore original hosts file
sudo dns-protekt restore

# Uninstall DNS-Protekt
sudo dns-protekt uninstall
```

### Systemd Commands

```bash
# Check service status
sudo systemctl status dns-protekt

# Run update immediately
sudo systemctl start dns-protekt

# Check timer schedule
sudo systemctl list-timers dns-protekt

# View logs
sudo journalctl -u dns-protekt -f
sudo tail -f /var/log/dns-protekt.log
```

### Configuration

Edit `/opt/dns-protekt/dns-protekt.conf` to customize:

```bash
# Change blocklist source
BLOCKLIST_URL="https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"

# Change update frequency (hourly, daily, weekly, monthly)
UPDATE_INTERVAL="daily"

# Number of backups to keep
BACKUP_RETENTION=7

# Add custom whitelist
WHITELIST=(
    "example.com"
    "subdomain.example.com"
)
```

### Automatic Updates

The systemd timer automatically:
- Updates the blocklist daily at 3:00 AM (with 1-hour random delay)
- Runs 5 minutes after every system boot
- Maintains up-to-date protection without manual intervention

## File Structure

```
/opt/dns-protekt/
├── dns-protekt.conf      # Configuration file
├── backups/              # Hosts file backups
│   ├── hosts.backup.20240101_000000
│   └── hosts.backup.original
└── temp/                 # Temporary files during updates

/etc/systemd/system/
├── dns-protekt.service   # Service definition
└── dns-protekt.timer     # Timer for periodic updates

/usr/local/bin/
└── dns-protekt           # Main executable script

/var/log/
└── dns-protekt.log       # Application logs
```

## Security Features

### Systemd Hardening

The systemd service includes security sandboxing:
- `NoNewPrivileges=true`: Prevents privilege escalation
- `PrivateTmp=true`: Isolated temporary directory
- `ProtectSystem=strict`: Read-only root filesystem
- `ProtectHome=true`: Inaccessible home directories
- `ProtectKernelTunables=true`: Immutable kernel settings
- And more security restrictions

### Backup Strategy

- Original hosts file backed up before first run
- New backup created before every update
- Configurable retention policy (default: 7 backups)
- Automatic cleanup of old backups

### DNS Verification

After each update, DNS-Protekt verifies:
1. Legitimate domains (like google.com) still resolve correctly
2. Blocked domains properly resolve to localhost
3. System DNS functionality remains intact

If verification fails, the original hosts file is automatically restored.

## Uninstallation

### Linux

```bash
# Method 1: Using the script
sudo dns-protekt uninstall

# Method 2: Using the installer
sudo ./install.sh uninstall
```

Both methods will:
- Stop and disable systemd services
- Restore your original hosts file
- Remove all DNS-Protekt files

### Windows

1. Open Task Scheduler
2. Find and delete the "DNSProtekt" task
3. Delete `C:\dnscapture\` directory
4. Restore original hosts file from backup if needed

## Troubleshooting

### Check Logs

```bash
# Application logs
sudo tail -f /var/log/dns-protekt.log

# Systemd logs
sudo journalctl -u dns-protekt -f
```

### Common Issues

**DNS not working after update**
```bash
# Restore original hosts
sudo dns-protekt restore

# Then check the blocklist URL or try a different source
```

**Service fails to start**
```bash
# Check service status
sudo systemctl status dns-protekt

# Check for errors
sudo journalctl -u dns-protekt --no-pager
```

**Blocked domains you need access to**
```bash
# Edit config and add to whitelist
sudo nano /opt/dns-protekt/dns-protekt.conf

# Then update
sudo dns-protekt update
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [someonewhocares.org](https://someonewhocares.org/hosts/) for providing the default blocklist
- [StevenBlack](https://github.com/StevenBlack/hosts) for the unified hosts project
- All contributors to the blocklist community

## Disclaimer

This tool modifies your system's hosts file. While it includes safety measures (backups, verification), users should understand the implications:
- Some websites may not function correctly if they depend on blocked domains
- Critical system functionality should always be tested after installation
- Always maintain backups of important data

Use at your own risk. The authors are not responsible for any issues arising from the use of this tool.

---

**Made with ❤️ for a safer internet experience**
