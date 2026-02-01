#!/bin/bash
#
# DNS-Protekt Linux Installer
# This script installs DNS-Protekt with systemd integration
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/opt/dns-protekt"
CONFIG_FILE="$INSTALL_DIR/dns-protekt.conf"

# Function to print colored messages
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This installer must be run as root (use sudo)"
        exit 1
    fi
}

# Check Linux distribution
check_distro() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        print_status "Detected distribution: $NAME $VERSION_ID"
        
        # Check if systemd is available
        if ! command -v systemctl &> /dev/null; then
            print_error "systemd is required but not found"
            exit 1
        fi
    else
        print_error "Cannot detect Linux distribution"
        exit 1
    fi
}

# Check dependencies
check_dependencies() {
    local deps=("curl" "grep" "awk" "sort" "chmod")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -ne 0 ]]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        print_status "Please install them first:"
        
        if command -v apt-get &> /dev/null; then
            echo "  sudo apt-get update && sudo apt-get install -y curl grep gawk coreutils"
        elif command -v yum &> /dev/null; then
            echo "  sudo yum install -y curl grep gawk coreutils"
        elif command -v pacman &> /dev/null; then
            echo "  sudo pacman -S curl grep gawk coreutils"
        else
            echo "  Please install the missing packages using your package manager"
        fi
        exit 1
    fi
    
    print_success "All dependencies are installed"
}

# Create backup of original hosts
create_initial_backup() {
    if [[ -f /etc/hosts ]]; then
        mkdir -p "$INSTALL_DIR/backups"
        cp /etc/hosts "$INSTALL_DIR/backups/hosts.backup.original"
        print_success "Original hosts file backed up"
    fi
}

# Install files
install_files() {
    print_status "Installing DNS-Protekt files..."
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR/backups"
    mkdir -p "$INSTALL_DIR/temp"
    
    # Copy main script
    cp "$SCRIPT_DIR/dns-protekt" /usr/local/bin/dns-protekt
    chmod 755 /usr/local/bin/dns-protekt
    
    # Copy config file
    cp "$SCRIPT_DIR/dns-protekt.conf" "$CONFIG_FILE"
    chmod 644 "$CONFIG_FILE"
    
    # Copy systemd files
    cp "$SCRIPT_DIR/dns-protekt.service" /etc/systemd/system/
    cp "$SCRIPT_DIR/dns-protekt.timer" /etc/systemd/system/
    
    print_success "Files installed successfully"
}

# Setup log file
setup_logging() {
    touch /var/log/dns-protekt.log
    chmod 644 /var/log/dns-protekt.log
    print_status "Log file created at /var/log/dns-protekt.log"
}

# Enable and start systemd service
setup_systemd() {
    print_status "Setting up systemd service..."
    
    # Reload systemd
    systemctl daemon-reload
    
    # Enable the timer (for periodic updates)
    systemctl enable dns-protekt.timer
    
    # Enable the service (for boot-time execution)
    systemctl enable dns-protekt.service
    
    print_success "Systemd service enabled"
}

# Run initial update
run_initial_update() {
    print_status "Running initial blocklist update..."
    
    if /usr/local/bin/dns-protekt run; then
        print_success "Initial update completed successfully"
    else
        print_warning "Initial update failed - service will retry on next boot"
    fi
}

# Display post-installation information
show_post_install_info() {
    local blocked_count=$(grep -c "127.0.0.1\|0.0.0.0" /etc/hosts 2>/dev/null || echo "0")
    
    echo ""
    echo "=========================================="
    echo "  DNS-Protekt Installation Complete!"
    echo "=========================================="
    echo ""
    echo "Currently blocked domains: $blocked_count"
    echo ""
    echo "Management Commands:"
    echo "  sudo dns-protekt update    - Update blocklist manually"
    echo "  sudo dns-protekt restore   - Restore original hosts file"
    echo "  sudo dns-protekt stats     - Show statistics"
    echo "  sudo dns-protekt uninstall - Remove DNS-Protekt"
    echo ""
    echo "Systemd Commands:"
    echo "  sudo systemctl status dns-protekt     - Check service status"
    echo "  sudo systemctl start dns-protekt      - Run update now"
    echo "  sudo systemctl list-timers dns-protekt - Check timer schedule"
    echo ""
    echo "Configuration:"
    echo "  Config file: $CONFIG_FILE"
    echo "  Log file: /var/log/dns-protekt.log"
    echo ""
    echo "Automatic Updates:"
    echo "  - Daily at 3:00 AM (with 1 hour random delay)"
    echo "  - On every system boot (5 minutes after boot)"
    echo ""
    echo "Documentation: https://github.com/nicthegarden/DNS-Proteck"
    echo "=========================================="
}

# Uninstall function
uninstall() {
    print_status "Uninstalling DNS-Protekt..."
    
    # Stop and disable services
    systemctl stop dns-protekt.timer 2>/dev/null || true
    systemctl stop dns-protekt.service 2>/dev/null || true
    systemctl disable dns-protekt.timer 2>/dev/null || true
    systemctl disable dns-protekt.service 2>/dev/null || true
    
    # Restore original hosts
    if [[ -f "$INSTALL_DIR/backups/hosts.backup.original" ]]; then
        cp "$INSTALL_DIR/backups/hosts.backup.original" /etc/hosts
        print_success "Original hosts file restored"
    fi
    
    # Remove files
    rm -rf "$INSTALL_DIR"
    rm -f /usr/local/bin/dns-protekt
    rm -f /etc/systemd/system/dns-protekt.service
    rm -f /etc/systemd/system/dns-protekt.timer
    rm -f /var/run/dns-protekt.lock
    
    # Reload systemd
    systemctl daemon-reload
    
    print_success "DNS-Protekt uninstalled successfully"
}

# Main installation process
main() {
    local action="${1:-install}"
    
    case "$action" in
        install)
            echo "=========================================="
            echo "  DNS-Protekt Linux Installer"
            echo "=========================================="
            echo ""
            
            check_root
            check_distro
            check_dependencies
            create_initial_backup
            install_files
            setup_logging
            setup_systemd
            run_initial_update
            show_post_install_info
            ;;
            
        uninstall)
            check_root
            uninstall
            ;;
            
        *)
            echo "Usage: sudo $0 {install|uninstall}"
            echo ""
            echo "Examples:"
            echo "  sudo $0 install    - Install DNS-Protekt"
            echo "  sudo $0 uninstall  - Remove DNS-Protekt"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
