#!/bin/bash

# RFID Tool Installation Script for Raspberry Pi
# Comprehensive installation with dependency checking and system configuration

set -e

# Configuration
APP_NAME="rfid-tool"
VERSION="1.0.0"
INSTALL_DIR="/opt/rfid-tool"
SERVICE_NAME="rfid-tool"
USER="pi"
GROUP="pi"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root. Use 'sudo ./install-rpi.sh'"
        exit 1
    fi
}

check_raspberry_pi() {
    if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
        log_warning "This doesn't appear to be a Raspberry Pi. Continuing anyway..."
    else
        log_info "Raspberry Pi detected"
    fi
}

check_dependencies() {
    log_info "Checking system dependencies..."

    # Check if required files exist
    if [ ! -f "${APP_NAME}-rpi" ]; then
        log_error "Binary '${APP_NAME}-rpi' not found in current directory"
        exit 1
    fi

    if [ ! -f "config.json" ]; then
        log_error "Configuration file 'config.json' not found"
        exit 1
    fi

    # Check SPI interface
    if [ ! -d "/sys/module/spi_bcm2835" ] && [ ! -d "/sys/module/spi_bcm2708" ]; then
        log_warning "SPI interface may not be enabled"
        echo "Enable SPI with: sudo raspi-config -> Interface Options -> SPI -> Enable"
    else
        log_success "SPI interface appears to be enabled"
    fi

    # Check for SPI devices
    if [ ! -e "/dev/spidev0.0" ]; then
        log_warning "SPI device /dev/spidev0.0 not found"
        echo "You may need to enable SPI interface and reboot"
    else
        log_success "SPI device found"
    fi
}

install_system_dependencies() {
    log_info "Installing system dependencies..."

    # Update package list
    apt-get update -qq

    # Install required packages
    apt-get install -y -qq \
        systemd \
        curl \
        wget \
        gpio-utils \
        raspi-gpio || true

    log_success "System dependencies installed"
}

create_user_and_group() {
    log_info "Setting up user and group..."

    # Create user if it doesn't exist
    if ! id "$USER" &>/dev/null; then
        useradd -r -s /bin/false -d "$INSTALL_DIR" "$USER"
        log_info "Created user: $USER"
    else
        log_info "User $USER already exists"
    fi

    # Add user to necessary groups
    usermod -a -G spi,gpio,dialout "$USER" 2>/dev/null || true

    log_success "User and group configuration completed"
}

install_application() {
    log_info "Installing RFID Tool application..."

    # Create installation directory
    mkdir -p "$INSTALL_DIR"

    # Copy binary
    cp "${APP_NAME}-rpi" "$INSTALL_DIR/$APP_NAME"
    chmod +x "$INSTALL_DIR/$APP_NAME"

    # Copy configuration
    cp config.json "$INSTALL_DIR/"

    # Copy additional files if they exist
    [ -f "README.md" ] && cp README.md "$INSTALL_DIR/"
    [ -f "WIRING.md" ] && cp WIRING.md "$INSTALL_DIR/"

    # Set ownership
    chown -R "$USER:$GROUP" "$INSTALL_DIR"

    # Set permissions
    chmod 755 "$INSTALL_DIR"
    chmod 644 "$INSTALL_DIR/config.json"
    chmod 644 "$INSTALL_DIR"/*.md 2>/dev/null || true

    log_success "Application installed to $INSTALL_DIR"
}

create_systemd_services() {
    log_info "Creating systemd services..."

    # Create web service
    cat > "/etc/systemd/system/${SERVICE_NAME}-web.service" << EOL
[Unit]
Description=RFID Tool Web Interface
Documentation=file://$INSTALL_DIR/README.md
After=network.target network-online.target
Wants=network-online.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=$USER
Group=$GROUP
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/$APP_NAME -web -port=8080 -config=$INSTALL_DIR/config.json
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=rfid-tool-web

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$INSTALL_DIR

# Resource limits
LimitNOFILE=4096
MemoryMax=256M

[Install]
WantedBy=multi-user.target
EOL

    # Create hardware service
    cat > "/etc/systemd/system/${SERVICE_NAME}-hw.service" << EOL
[Unit]
Description=RFID Tool Hardware Interface
Documentation=file://$INSTALL_DIR/README.md
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=$USER
Group=$GROUP
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/$APP_NAME -hardware -config=$INSTALL_DIR/config.json
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=rfid-tool-hw

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$INSTALL_DIR

# Resource limits
LimitNOFILE=4096
MemoryMax=256M

[Install]
WantedBy=multi-user.target
EOL

    # Reload systemd
    systemctl daemon-reload

    log_success "Systemd services created"
}

configure_gpio_permissions() {
    log_info "Configuring GPIO permissions..."

    # Create udev rules for GPIO access
    cat > "/etc/udev/rules.d/99-rfid-tool-gpio.rules" << EOL
# GPIO access for RFID Tool
SUBSYSTEM=="gpio*", PROGRAM="/bin/sh -c 'chown -R $USER:$GROUP /sys/class/gpio && chmod -R 775 /sys/class/gpio'"
SUBSYSTEM=="gpio", KERNEL=="gpiochip*", ACTION=="add", PROGRAM="/bin/sh -c 'chown root:$GROUP /sys/class/gpio/export /sys/class/gpio/unexport ; chmod 220 /sys/class/gpio/export /sys/class/gpio/unexport'"
SUBSYSTEM=="gpio", KERNEL=="gpio*", ACTION=="add", PROGRAM="/bin/sh -c 'chown -R $USER:$GROUP /sys%p && chmod -R 775 /sys%p'"

# SPI access for RFID Tool
KERNEL=="spidev*", GROUP="$GROUP", MODE="0664"
EOL

    # Reload udev rules
    udevadm control --reload-rules
    udevadm trigger

    log_success "GPIO permissions configured"
}

create_scripts() {
    log_info "Creating helper scripts..."

    # Create start script
    cat > "$INSTALL_DIR/start-web.sh" << EOL
#!/bin/bash
# Start RFID Tool Web Interface
sudo systemctl start ${SERVICE_NAME}-web
sudo systemctl status ${SERVICE_NAME}-web --no-pager
EOL

    cat > "$INSTALL_DIR/start-hw.sh" << EOL
#!/bin/bash
# Start RFID Tool Hardware Interface
sudo systemctl start ${SERVICE_NAME}-hw
sudo systemctl status ${SERVICE_NAME}-hw --no-pager
EOL

    cat > "$INSTALL_DIR/stop-all.sh" << EOL
#!/bin/bash
# Stop all RFID Tool services
sudo systemctl stop ${SERVICE_NAME}-web 2>/dev/null || true
sudo systemctl stop ${SERVICE_NAME}-hw 2>/dev/null || true
echo "All RFID Tool services stopped"
EOL

    cat > "$INSTALL_DIR/logs.sh" << EOL
#!/bin/bash
# View RFID Tool logs
echo "Recent Web Interface logs:"
sudo journalctl -u ${SERVICE_NAME}-web -n 20 --no-pager
echo ""
echo "Recent Hardware Interface logs:"
sudo journalctl -u ${SERVICE_NAME}-hw -n 20 --no-pager
EOL

    # Make scripts executable
    chmod +x "$INSTALL_DIR"/*.sh
    chown "$USER:$GROUP" "$INSTALL_DIR"/*.sh

    log_success "Helper scripts created"
}

configure_firewall() {
    log_info "Configuring firewall for web interface..."

    # Check if ufw is installed and active
    if command -v ufw >/dev/null 2>&1; then
        if ufw status | grep -q "Status: active"; then
            ufw allow 8080/tcp comment "RFID Tool Web Interface" || true
            log_success "Firewall configured to allow port 8080"
        else
            log_info "UFW firewall is not active, skipping firewall configuration"
        fi
    else
        log_info "UFW firewall not found, skipping firewall configuration"
    fi
}

test_installation() {
    log_info "Testing installation..."

    # Test binary execution
    if sudo -u "$USER" "$INSTALL_DIR/$APP_NAME" -h >/dev/null 2>&1; then
        log_success "Binary executes successfully"
    else
        log_warning "Binary test failed, but continuing installation"
    fi

    # Test systemd services
    if systemctl is-enabled ${SERVICE_NAME}-web.service >/dev/null 2>&1; then
        log_info "Web service is available"
    fi

    if systemctl is-enabled ${SERVICE_NAME}-hw.service >/dev/null 2>&1; then
        log_info "Hardware service is available"
    fi
}

show_installation_summary() {
    local_ip=$(hostname -I | awk '{print $1}' | tr -d ' ')

    echo ""
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}  RFID Tool Installation Complete!${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}Installation Directory:${NC} $INSTALL_DIR"
    echo -e "${CYAN}Configuration File:${NC} $INSTALL_DIR/config.json"
    echo ""
    echo -e "${YELLOW}Quick Start Commands:${NC}"
    echo ""
    echo -e "${BLUE}Web Interface Mode:${NC}"
    echo "  sudo systemctl start ${SERVICE_NAME}-web"
    echo "  sudo systemctl enable ${SERVICE_NAME}-web"
    echo "  Access at: http://$local_ip:8080"
    echo ""
    echo -e "${BLUE}Hardware Interface Mode:${NC}"
    echo "  sudo systemctl start ${SERVICE_NAME}-hw"
    echo "  sudo systemctl enable ${SERVICE_NAME}-hw"
    echo ""
    echo -e "${BLUE}Service Management:${NC}"
    echo "  sudo systemctl status ${SERVICE_NAME}-web"
    echo "  sudo systemctl status ${SERVICE_NAME}-hw"
    echo "  sudo journalctl -u ${SERVICE_NAME}-web -f"
    echo "  sudo journalctl -u ${SERVICE_NAME}-hw -f"
    echo ""
    echo -e "${BLUE}Helper Scripts:${NC}"
    echo "  $INSTALL_DIR/start-web.sh"
    echo "  $INSTALL_DIR/start-hw.sh"
    echo "  $INSTALL_DIR/stop-all.sh"
    echo "  $INSTALL_DIR/logs.sh"
    echo ""
    echo -e "${YELLOW}Important Notes:${NC}"
    echo "• Ensure SPI interface is enabled: sudo raspi-config"
    echo "• Check wiring connections as per WIRING.md"
    echo "• Only run ONE interface mode at a time (web OR hardware)"
    echo "• Web interface allows unrestricted access on port 8080"
    echo ""
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo "• View logs: sudo journalctl -u ${SERVICE_NAME}-web -n 50"
    echo "• Test SPI: ls -la /dev/spi*"
    echo "• Check GPIO: cat /sys/kernel/debug/gpio"
    echo "• Documentation: $INSTALL_DIR/README.md"
    echo ""
}

# Main installation process
main() {
    echo -e "${CYAN}RFID Tool Raspberry Pi Installation${NC}"
    echo "===================================="
    echo ""

    # Pre-installation checks
    check_root
    check_raspberry_pi
    check_dependencies

    # Installation steps
    install_system_dependencies
    create_user_and_group
    install_application
    create_systemd_services
    configure_gpio_permissions
    create_scripts
    configure_firewall

    # Post-installation
    test_installation
    show_installation_summary

    log_success "Installation completed successfully!"
}

# Handle script interruption
trap 'log_error "Installation interrupted"; exit 1' INT TERM

# Run main installation
main "$@"
