#!/bin/bash

# RFID Tool RPi Build Script
# Cross-compilation script for building on macOS M1 for Raspberry Pi ARM

set -e

# Configuration
APP_NAME="rfid-tool"
VERSION=${VERSION:-"1.0.0"}
BUILD_DIR="build"
DIST_DIR="dist"

# Target configurations
GOOS="linux"
GOARCH="arm"
GOARM="6"  # ARMv6 for Raspberry Pi 2B compatibility

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}RFID Tool RPi Build Script${NC}"
echo "=================================="

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
rm -rf $BUILD_DIR
rm -rf $DIST_DIR
mkdir -p $BUILD_DIR
mkdir -p $DIST_DIR

# Download dependencies
echo -e "${YELLOW}Downloading dependencies...${NC}"
go mod download
go mod tidy

# Build for Raspberry Pi
echo -e "${YELLOW}Building for Raspberry Pi (linux/arm)...${NC}"
export CGO_ENABLED=0
export GOOS=$GOOS
export GOARCH=$GOARCH
export GOARM=$GOARM

BUILD_TIME=$(date -u '+%Y-%m-%d_%H:%M:%S')
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

LDFLAGS="-s -w -X main.version=$VERSION -X main.buildTime=$BUILD_TIME -X main.gitCommit=$GIT_COMMIT"

go build -ldflags "$LDFLAGS" -o $BUILD_DIR/${APP_NAME}-rpi ./cmd/main.go

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Build successful!${NC}"
else
    echo -e "${RED}✗ Build failed!${NC}"
    exit 1
fi

# Create distribution package
echo -e "${YELLOW}Creating distribution package...${NC}"
DIST_NAME="${APP_NAME}-rpi-${VERSION}"
DIST_PATH="$DIST_DIR/$DIST_NAME"

mkdir -p $DIST_PATH

# Copy binary
cp $BUILD_DIR/${APP_NAME}-rpi $DIST_PATH/

# Copy configuration files
cp config.json $DIST_PATH/
cp README.md $DIST_PATH/ 2>/dev/null || echo "README.md not found, skipping..."

# Create installation script
cat > $DIST_PATH/install.sh << 'EOF'
#!/bin/bash

# RFID Tool Installation Script for Raspberry Pi

set -e

APP_NAME="rfid-tool"
INSTALL_DIR="/opt/rfid-tool"
SERVICE_NAME="rfid-tool"
USER="pi"

echo "Installing RFID Tool..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Create installation directory
mkdir -p $INSTALL_DIR
cp ${APP_NAME}-rpi $INSTALL_DIR/$APP_NAME
cp config.json $INSTALL_DIR/
chmod +x $INSTALL_DIR/$APP_NAME

# Create systemd service for web mode
cat > /etc/systemd/system/${SERVICE_NAME}-web.service << EOL
[Unit]
Description=RFID Tool Web Interface
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/$APP_NAME -web -port=8080
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOL

# Create systemd service for hardware mode
cat > /etc/systemd/system/${SERVICE_NAME}-hw.service << EOL
[Unit]
Description=RFID Tool Hardware Interface
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/$APP_NAME -hardware
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd
systemctl daemon-reload

echo "Installation complete!"
echo ""
echo "To start web interface: sudo systemctl start ${SERVICE_NAME}-web"
echo "To start hardware interface: sudo systemctl start ${SERVICE_NAME}-hw"
echo "To enable auto-start: sudo systemctl enable ${SERVICE_NAME}-web"
echo "                  or: sudo systemctl enable ${SERVICE_NAME}-hw"
echo ""
echo "Web interface will be available at: http://$(hostname -I | awk '{print $1}'):8080"

EOF

chmod +x $DIST_PATH/install.sh

# Create uninstall script
cat > $DIST_PATH/uninstall.sh << 'EOF'
#!/bin/bash

# RFID Tool Uninstall Script

set -e

SERVICE_NAME="rfid-tool"
INSTALL_DIR="/opt/rfid-tool"

echo "Uninstalling RFID Tool..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Stop and disable services
systemctl stop ${SERVICE_NAME}-web 2>/dev/null || true
systemctl stop ${SERVICE_NAME}-hw 2>/dev/null || true
systemctl disable ${SERVICE_NAME}-web 2>/dev/null || true
systemctl disable ${SERVICE_NAME}-hw 2>/dev/null || true

# Remove service files
rm -f /etc/systemd/system/${SERVICE_NAME}-web.service
rm -f /etc/systemd/system/${SERVICE_NAME}-hw.service

# Reload systemd
systemctl daemon-reload

# Remove installation directory
rm -rf $INSTALL_DIR

echo "Uninstall complete!"

EOF

chmod +x $DIST_PATH/uninstall.sh

# Create wiring guide
cat > $DIST_PATH/WIRING.md << 'EOF'
# RFID-RC522 Wiring Guide for Raspberry Pi 2B

## Required Components
- Raspberry Pi 2B
- RFID-RC522 Module
- Breadboard
- Jumper wires (male-to-female and male-to-male)
- 2x Push buttons (for hardware mode)
- 3x LEDs (for hardware mode)
- 3x 220Ω resistors (for LEDs)
- 2x 10kΩ resistors (for button pull-ups, if not using internal pull-ups)

## RFID-RC522 to Raspberry Pi Connections

| RC522 Pin | RPi Pin | RPi GPIO | Wire Color |
|-----------|---------|----------|------------|
| SDA       | 24      | GPIO8    | Orange     |
| SCK       | 23      | GPIO11   | Yellow     |
| MOSI      | 19      | GPIO10   | Blue       |
| MISO      | 21      | GPIO9    | Green      |
| IRQ       | 18      | GPIO24   | Purple     |
| GND       | 20      | GND      | Black      |
| RST       | 15      | GPIO22   | White      |
| 3.3V      | 17      | 3.3V     | Red        |

## Hardware Interface Components (Optional)

### Buttons
| Component   | RPi Pin | RPi GPIO | Notes              |
|-------------|---------|----------|--------------------|
| Read Button | 3       | GPIO2    | Active low with pull-up |
| Write Button| 5       | GPIO3    | Active low with pull-up |

### LEDs
| LED         | RPi Pin | RPi GPIO | Resistor | Purpose            |
|-------------|---------|----------|----------|--------------------|
| Ready LED   | 13      | GPIO27   | 220Ω     | Green - System ready |
| Status LED  | 7       | GPIO4    | 220Ω     | Blue - Operation in progress |
| Error LED   | 11      | GPIO17   | 220Ω     | Red - Error indication |

## Breadboard Layout

```
     RC522 Module                    Raspberry Pi 2B
    ┌─────────────┐                 ┌───────────────────┐
    │ SDA  SCK    │                 │                   │
    │ MOSI MISO   │ ────────────────│ SPI Interface     │
    │ IRQ  GND    │                 │                   │
    │ RST  3.3V   │                 │                   │
    └─────────────┘                 └───────────────────┘
                                           │
    Buttons & LEDs                         │
    ┌─────────────┐                        │
    │ [READ]      │ ───────────────────────┤
    │ [WRITE]     │                        │
    │ Ready LED   │ ───────────────────────┤
    │ Status LED  │                        │
    │ Error LED   │ ───────────────────────┘
    └─────────────┘
```

## Breadboard Connections Step-by-Step

### 1. Power Rails
- Connect RPi pin 17 (3.3V) to breadboard positive rail
- Connect RPi pin 20 (GND) to breadboard negative rail

### 2. RFID-RC522 Module
- Place RC522 module on breadboard
- Connect as per table above using jumper wires

### 3. LEDs (for hardware mode)
- Connect LED anodes (+) to GPIO pins through 220Ω resistors
- Connect LED cathodes (-) to ground rail

### 4. Buttons (for hardware mode)
- Connect one side of each button to respective GPIO pins
- Connect other side to ground rail
- Enable internal pull-ups in software (default configuration)

## Enable SPI Interface
Run on Raspberry Pi:
```bash
sudo raspi-config
```
- Go to "Interface Options"
- Enable "SPI"
- Reboot: `sudo reboot`

## Testing Connections
After installation, test with:
```bash
# Web mode
sudo /opt/rfid-tool/rfid-tool -web -port=8080

# Hardware mode
sudo /opt/rfid-tool/rfid-tool -hardware
```

## Troubleshooting
- Ensure SPI is enabled
- Check all connections are secure
- Verify 3.3V power (NOT 5V - will damage RC522)
- Use multimeter to verify continuity
- Check GPIO pin assignments in config.json

EOF

# Create archive
echo -e "${YELLOW}Creating distribution archive...${NC}"
cd $DIST_DIR
tar -czf ${DIST_NAME}.tar.gz $DIST_NAME
cd ..

# Show build information
echo ""
echo -e "${GREEN}Build Summary${NC}"
echo "=================================="
echo "Target: $GOOS/$GOARCH (ARM v$GOARM)"
echo "Version: $VERSION"
echo "Build time: $BUILD_TIME"
echo "Git commit: $GIT_COMMIT"
echo "Binary size: $(ls -lh $BUILD_DIR/${APP_NAME}-rpi | awk '{print $5}')"
echo "Distribution: $DIST_DIR/${DIST_NAME}.tar.gz"
echo ""
echo -e "${GREEN}✓ Build completed successfully!${NC}"
echo ""
echo "To deploy to Raspberry Pi:"
echo "1. Copy ${DIST_NAME}.tar.gz to your Raspberry Pi"
echo "2. Extract: tar -xzf ${DIST_NAME}.tar.gz"
echo "3. Run: cd ${DIST_NAME} && sudo ./install.sh"
echo ""
echo "For manual execution:"
echo "- Web mode: ./${APP_NAME}-rpi -web -port=8080"
echo "- Hardware mode: ./${APP_NAME}-rpi -hardware"
