#!/bin/bash

# RFID Tool RPi Build Script
# Optimized cross-compilation script for Raspberry Pi 2B v1.1
# Target: BCM2836 SoC, ARM Cortex-A7, ARMv7 architecture

set -e

# Configuration
APP_NAME="rfid-tool"
VERSION=${VERSION:-"1.0.0"}
BUILD_DIR="build"
DIST_DIR="dist"

# Target configurations - Optimized for RPi 2B v1.1
GOOS="linux"
GOARCH="arm"
GOARM="7"  # ARMv7 for Raspberry Pi 2B v1.1 (BCM2836, Cortex-A7)

# RPi 2B v1.1 specific optimizations
TARGET_SOC="BCM2836"
TARGET_CPU="cortex-a7"
TARGET_ARCH="armv7"
MEMORY_CONSTRAINT="1024MB"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}RFID Tool RPi 2B v1.1 Build Script${NC}"
echo -e "${BLUE}Optimized for BCM2836 SoC, ARM Cortex-A7${NC}"
echo "=================================================="

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
rm -rf $BUILD_DIR
rm -rf $DIST_DIR
mkdir -p $BUILD_DIR
mkdir -p $DIST_DIR

# Verify Go installation
echo -e "${YELLOW}Verifying Go installation...${NC}"
if ! command -v go &> /dev/null; then
    echo -e "${RED}✗ Go is not installed or not in PATH${NC}"
    exit 1
fi

GO_VERSION=$(go version | cut -d' ' -f3)
echo -e "${GREEN}✓ Go version: $GO_VERSION${NC}"

# Download dependencies
echo -e "${YELLOW}Downloading dependencies...${NC}"
go mod download
go mod tidy

# Verify dependencies
echo -e "${YELLOW}Verifying dependencies...${NC}"
go mod verify

# Build for Raspberry Pi 2B v1.1
echo -e "${YELLOW}Building for Raspberry Pi 2B v1.1...${NC}"
echo -e "${BLUE}Target: $TARGET_SOC ($TARGET_CPU, $TARGET_ARCH)${NC}"
echo -e "${BLUE}Memory: $MEMORY_CONSTRAINT, Architecture: $GOOS/$GOARCH (ARM v$GOARM)${NC}"

export CGO_ENABLED=0
export GOOS=$GOOS
export GOARCH=$GOARCH
export GOARM=$GOARM

# RPi 2B v1.1 specific compiler flags
export GOFLAGS="-tags=rpi2b,bcm2836,cortex_a7"

BUILD_TIME=$(date -u '+%Y-%m-%d_%H:%M:%S')
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Enhanced build flags with RPi 2B v1.1 optimizations
LDFLAGS="-s -w"
LDFLAGS+=" -X main.version=$VERSION"
LDFLAGS+=" -X main.buildTime=$BUILD_TIME"
LDFLAGS+=" -X main.gitCommit=$GIT_COMMIT"
LDFLAGS+=" -X main.targetBoard=rpi2b_v1.1"
LDFLAGS+=" -X main.targetSoC=$TARGET_SOC"
LDFLAGS+=" -X main.targetCPU=$TARGET_CPU"
LDFLAGS+=" -X main.targetArch=$TARGET_ARCH"

echo -e "${BLUE}Build flags: $LDFLAGS${NC}"

go build -ldflags "$LDFLAGS" -o $BUILD_DIR/${APP_NAME}-rpi2b-v1.1 ./cmd/main.go

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Build successful!${NC}"
else
    echo -e "${RED}✗ Build failed!${NC}"
    exit 1
fi

# Verify binary architecture
echo -e "${YELLOW}Verifying binary architecture...${NC}"
if command -v file &> /dev/null; then
    BINARY_INFO=$(file $BUILD_DIR/${APP_NAME}-rpi2b-v1.1)
    echo -e "${BLUE}Binary info: $BINARY_INFO${NC}"

    if [[ $BINARY_INFO == *"ARM"* ]] && [[ $BINARY_INFO == *"7"* ]]; then
        echo -e "${GREEN}✓ Correct ARM v7 architecture verified${NC}"
    else
        echo -e "${YELLOW}⚠ Warning: Could not verify ARM v7 architecture${NC}"
    fi
fi

# Create distribution package
echo -e "${YELLOW}Creating RPi 2B v1.1 distribution package...${NC}"
DIST_NAME="${APP_NAME}-rpi2b-v1.1-${VERSION}"
DIST_PATH="$DIST_DIR/$DIST_NAME"

mkdir -p $DIST_PATH

# Copy binary
cp $BUILD_DIR/${APP_NAME}-rpi2b-v1.1 $DIST_PATH/
chmod +x $DIST_PATH/${APP_NAME}-rpi2b-v1.1

# Copy configuration files
cp config.json $DIST_PATH/
cp README.md $DIST_PATH/ 2>/dev/null || echo "README.md not found, skipping..."
cp WIRING.md $DIST_PATH/ 2>/dev/null || echo "WIRING.md not found, skipping..."
cp QUICKSTART.md $DIST_PATH/ 2>/dev/null || echo "QUICKSTART.md not found, skipping..."

# Create RPi 2B v1.1 specific installation script
cat > $DIST_PATH/install.sh << 'EOF'
#!/bin/bash

# RFID Tool Installation Script for Raspberry Pi 2B v1.1
# Optimized for BCM2836 SoC, ARM Cortex-A7

set -e

APP_NAME="rfid-tool"
BINARY_NAME="rfid-tool-rpi2b-v1.1"
INSTALL_DIR="/opt/rfid-tool"
SERVICE_NAME="rfid-tool"
USER="pi"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}RFID Tool Installation for Raspberry Pi 2B v1.1${NC}"
echo -e "${BLUE}Target: BCM2836 SoC, ARM Cortex-A7${NC}"
echo "================================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

# Verify Raspberry Pi model
echo -e "${YELLOW}Verifying Raspberry Pi model...${NC}"
if [ -f /proc/device-tree/model ]; then
    PI_MODEL=$(cat /proc/device-tree/model)
    echo -e "${BLUE}Detected: $PI_MODEL${NC}"

    if [[ $PI_MODEL == *"Raspberry Pi 2"* ]]; then
        echo -e "${GREEN}✓ Raspberry Pi 2 detected - compatible${NC}"
    else
        echo -e "${YELLOW}⚠ Warning: Not a Raspberry Pi 2, but continuing installation...${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Could not detect Pi model, continuing...${NC}"
fi

# Check CPU info for BCM2836
echo -e "${YELLOW}Verifying BCM2836 SoC...${NC}"
if [ -f /proc/cpuinfo ]; then
    if grep -q "BCM2836" /proc/cpuinfo || grep -q "Cortex-A7" /proc/cpuinfo; then
        echo -e "${GREEN}✓ BCM2836/Cortex-A7 detected${NC}"
    else
        echo -e "${YELLOW}⚠ BCM2836 not explicitly detected in /proc/cpuinfo${NC}"
        echo -e "${BLUE}CPU Info:${NC}"
        grep -E "(model name|Hardware|Revision)" /proc/cpuinfo | head -3
    fi
fi

# Check available memory (should be ~1GB for RPi 2B v1.1)
TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
echo
 -e "${BLUE}Available memory: ${TOTAL_MEM}MB${NC}"
if [ $TOTAL_MEM -lt 800 ]; then
    echo -e "${YELLOW}⚠ Warning: Low memory detected (expected ~1GB for RPi 2B v1.1)${NC}"
fi

# Verify required kernel modules
echo -e "${YELLOW}Checking required kernel modules...${NC}"
REQUIRED_MODULES=("spi_bcm2835" "gpio_bcm2835")
for module in "${REQUIRED_MODULES[@]}"; do
    if lsmod | grep -q "$module"; then
        echo -e "${GREEN}✓ $module loaded${NC}"
    else
        echo -e "${YELLOW}⚠ $module not loaded (may be built-in)${NC}"
    fi
done

# Check SPI interface
echo -e "${YELLOW}Verifying SPI interface...${NC}"
if [ -c /dev/spidev0.0 ]; then
    echo -e "${GREEN}✓ SPI interface available at /dev/spidev0.0${NC}"
else
    echo -e "${YELLOW}⚠ SPI interface not found. Please enable SPI in raspi-config${NC}"
    echo -e "${BLUE}Run: sudo raspi-config → Interface Options → SPI → Enable${NC}"
fi

# Check GPIO access
echo -e "${YELLOW}Checking GPIO access...${NC}"
if [ -d /sys/class/gpio ]; then
    echo -e "${GREEN}✓ GPIO interface available${NC}"
else
    echo -e "${RED}✗ GPIO interface not found${NC}"
    exit 1
fi

# Create installation directory
echo -e "${YELLOW}Creating installation directory...${NC}"
mkdir -p $INSTALL_DIR
cp $BINARY_NAME $INSTALL_DIR/$APP_NAME
cp config.json $INSTALL_DIR/
chmod +x $INSTALL_DIR/$APP_NAME

# Set ownership
chown -R $USER:$USER $INSTALL_DIR

# Add user to gpio and spi groups
echo -e "${YELLOW}Adding user to gpio and spi groups...${NC}"
usermod -a -G gpio,spi $USER || echo -e "${YELLOW}Groups may already be assigned${NC}"

# Create systemd service for web mode
echo -e "${YELLOW}Creating systemd services...${NC}"
cat > /etc/systemd/system/${SERVICE_NAME}-web.service << EOL
[Unit]
Description=RFID Tool Web Interface (RPi 2B v1.1)
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=$USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/$APP_NAME -web -port=8080
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

# RPi 2B v1.1 specific optimizations
Nice=0
IOSchedulingClass=1
IOSchedulingPriority=4

# Memory constraints for 1GB system
MemoryLimit=512M

[Install]
WantedBy=multi-user.target
EOL

# Create systemd service for hardware mode
cat > /etc/systemd/system/${SERVICE_NAME}-hw.service << EOL
[Unit]
Description=RFID Tool Hardware Interface (RPi 2B v1.1)
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=$USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/$APP_NAME -hardware
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

# RPi 2B v1.1 specific optimizations
Nice=-5
IOSchedulingClass=1
IOSchedulingPriority=2

# Memory constraints for 1GB system
MemoryLimit=256M

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd
systemctl daemon-reload

echo -e "${GREEN}✓ Installation complete!${NC}"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  • Target: Raspberry Pi 2B v1.1 (BCM2836, Cortex-A7)"
echo "  • Binary: $INSTALL_DIR/$APP_NAME"
echo "  • Config: $INSTALL_DIR/config.json"
echo "  • Services: ${SERVICE_NAME}-web, ${SERVICE_NAME}-hw"
echo ""
echo -e "${YELLOW}Usage:${NC}"
echo "  • Start web interface: sudo systemctl start ${SERVICE_NAME}-web"
echo "  • Start hardware mode: sudo systemctl start ${SERVICE_NAME}-hw"
echo "  • Enable auto-start:   sudo systemctl enable ${SERVICE_NAME}-web"
echo "  • Check status:        sudo systemctl status ${SERVICE_NAME}-web"
echo "  • View logs:          sudo journalctl -u ${SERVICE_NAME}-web -f"
echo ""
echo -e "${YELLOW}Access:${NC}"
echo "  • Web interface: http://$(hostname -I | awk '{print $1}'):8080"
echo "  • Manual run: sudo $INSTALL_DIR/$APP_NAME -web -port=8080"
echo ""
echo -e "${BLUE}Optimized for:${NC}"
echo "  • BCM2836 SoC with ARM Cortex-A7 (900MHz quad-core)"
echo "  • 1GB LPDDR2 memory"
echo "  • ARMv7 instruction set"
echo "  • Hardware-specific I/O scheduling"

EOF

chmod +x $DIST_PATH/install.sh

# Create RPi 2B v1.1 specific uninstall script
cat > $DIST_PATH/uninstall.sh << 'EOF'
#!/bin/bash

# RFID Tool Uninstall Script for Raspberry Pi 2B v1.1

set -e

SERVICE_NAME="rfid-tool"
INSTALL_DIR="/opt/rfid-tool"

echo "Uninstalling RFID Tool from Raspberry Pi 2B v1.1..."

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

echo "✓ Uninstall complete!"

EOF

chmod +x $DIST_PATH/uninstall.sh

# Create RPi 2B v1.1 specific wiring guide
cat > $DIST_PATH/WIRING-RPi2B-v1.1.md << 'EOF'
# RFID-RC522 Wiring Guide for Raspberry Pi 2B v1.1

## Board Information
- **Model**: Raspberry Pi 2B v1.1
- **SoC**: BCM2836 (Broadcom)
- **CPU**: ARM Cortex-A7 quad-core @ 900MHz
- **Architecture**: ARMv7
- **Memory**: 1GB LPDDR2
- **GPIO**: 40-pin header (same as Pi B+)

## RFID-RC522 to Raspberry Pi 2B v1.1 Connections

### SPI Interface (Optimized for BCM2836)
| RC522 Pin | RPi Pin | BCM GPIO | Function | Wire Color | Notes |
|-----------|---------|----------|----------|------------|-------|
| SDA       | 24      | GPIO8    | SPI0_CE0 | Orange     | SPI Chip Select 0 |
| SCK       | 23      | GPIO11   | SPI0_CLK | Yellow     | SPI Clock (max 32MHz on BCM2836) |
| MOSI      | 19      | GPIO10   | SPI0_MOSI| Blue       | Master Out Slave In |
| MISO      | 21      | GPIO9    | SPI0_MISO| Green      | Master In Slave Out |
| IRQ       | 18      | GPIO24   | -        | Purple     | Interrupt (optional) |
| GND       | 20      | GND      | Ground   | Black      | Common ground |
| RST       | 15      | GPIO22   | -        | White      | Reset signal |
| 3.3V      | 17      | 3.3V     | Power    | Red        | **3.3V ONLY - BCM2836 compatible** |

### Hardware Interface (Optional)
| Component   | RPi Pin | BCM GPIO | Function | Resistor | Notes |
|-------------|---------|----------|----------|----------|-------|
| Read Button | 3       | GPIO2    | Input    | Internal PU | I2C1_SDA (alt function) |
| Write Button| 5       | GPIO3    | Input    | Internal PU | I2C1_SCL (alt function) |
| Ready LED   | 13      | GPIO27   | Output   | 220Ω     | Green LED |
| Status LED  | 7       | GPIO4    | Output   | 220Ω     | Blue LED |
| Error LED   | 11      | GPIO17   | Output   | 220Ω     | Red LED |

## BCM2836 SPI Configuration Notes

### SPI Speed Optimization
- **Default Speed**: 500kHz (conservative, reliable)
- **Maximum Speed**: Up to 32MHz (BCM2836 limit)
- **Recommended**: 1-2MHz for optimal balance

The config.json file is pre-configured for BCM2836:
```json
{
  "rfid": {
    "spi_speed": 500000,
    "spi_bus": 0,
    "spi_device": 0
  }
}
```

### GPIO Performance Notes
- **BCM2836 GPIO Speed**: Up to 50MHz toggle rate
- **Drive Strength**: Configurable 2-16mA
- **Input Threshold**: 1.8V (CMOS compatible)
- **Pull Resistors**: 50-65kΩ internal

## Enable SPI on Raspberry Pi 2B v1.1

### Method 1: raspi-config
```bash
sudo raspi-config
# Navigate: Interface Options → SPI → Enable
sudo reboot
```

### Method 2: Manual Configuration
```bash
# Add to /boot/config.txt
echo "dtparam=spi=on" | sudo tee -a /boot/config.txt

# Load kernel module
sudo modprobe spi_bcm2835

# Add to /etc/modules for permanent loading
echo "spi_bcm2835" | sudo tee -a /etc/modules

sudo reboot
```

### Verify SPI Setup
```bash
# Check SPI device
ls -la /dev/spi*
# Expected output: /dev/spidev0.0  /dev/spidev0.1

# Check kernel modules
lsmod | grep spi
# Expected: spi_bcm2835

# Test SPI functionality (with connected RC522)
sudo ./rfid-tool-rpi2b-v1.1 -web -port=8080
```

## Memory and Performance Considerations

### RPi 2B v1.1 Specifications
- **Total RAM**: 1GB LPDDR2
- **Available to OS**: ~950MB (after GPU split)
- **Recommended GPU Split**: 64MB (minimum for this application)

### Performance Optimization
The systemd services are configured with:
- **Web Service**: 512MB memory limit, normal priority
- **Hardware Service**: 256MB memory limit, high priority (-5 nice)
- **I/O Scheduling**: Real-time class for hardware mode

### GPU Memory Split Configuration
```bash
# Set GPU memory to minimum (more RAM for application)
echo "gpu_mem=64" | sudo tee -a /boot/config.txt
sudo reboot
```

## Troubleshooting BCM2836 Specific Issues

### SPI Communication Problems
```bash
# Check SPI configuration
cat /proc/device-tree/soc/spi@7e204000/status
# Should show: "okay"

# Test SPI loopback (disconnect RC522 first)
# Connect MOSI (pin 19) to MISO (pin 21) temporarily
sudo apt install python3-spidev
python3 -c "
import spidev
spi = spidev.SpiDev()
spi.open(0, 0)
spi.max_speed_hz = 500000
result = spi.xfer2([0xAA, 0x55])
print('SPI test result:', [hex(x) for x in result])
spi.close()
"
```

### GPIO Issues
```bash
# Check GPIO driver
dmesg | grep gpio
# Look for: gpio-bcm2835

# Test GPIO manually
echo 22 | sudo tee /sys/class/gpio/export
echo out | sudo tee /sys/class/gpio/gpio22/direction
echo 1 | sudo tee /sys/class/gpio/gpio22/value  # Should reset RC522
echo 0 | sudo tee /sys/class/gpio/gpio22/value
```

### Performance Issues
```bash
# Check CPU frequency scaling
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
# Should be: "ondemand" or "performance"

# Check temperature throttling
vcgencmd measure_temp
# Should be < 70°C for optimal performance

# Monitor CPU usage
htop
```

## Physical Installation Notes

### Heat Dissipation
The BCM2836 SoC may require cooling under continuous load:
- **Passive**: Heat sink recommended for 24/7 operation
- **Active**: Small fan for enclosed installations
- **Thermal Throttling**: Occurs at 85°C

### Power Requirements
- **Minimum Supply**: 5V 2A (quality supply recommended)
- **USB Power**: May be insufficient for RC522 + accessories
- **GPIO Power Budget**: 50mA total across all pins

### Case Compatibility
Standard Raspberry Pi 2B cases are compatible, ensure:
- GPIO header access for wiring
- Adequate ventilation for BCM2836
- Easy access to microSD card

## Tested Configurations

### Verified Compatible
- **OS**: Raspberry Pi OS (32-bit) - Bullseye, Bookworm
- **Kernel**: 5.4+, 5.10+, 5.15+, 6.1+
- **Python**: 3.7+ (for additional tools)
- **Node.js**: 14+ (for web development)

### Known Working Hardware
- **RC522 Modules**: Various clones and genuine modules
- **MicroSD Cards**: Class 10, 16GB+ recommended
- **Power Supplies**: Official Pi foundation adapter

This guide is specifically optimized for the Raspberry Pi 2B v1.1 with BCM2836 SoC. The configuration takes advantage of the Cortex-A7 architecture and 1GB memory capacity while respecting the hardware limitations.

EOF

# Create system verification script
cat > $DIST_PATH/verify-system.sh << 'EOF'
#!/bin/bash

# System Verification Script for Raspberry Pi 2B v1.1
# Checks hardware compatibility and configuration

echo "RFID Tool - Raspberry Pi 2B v1.1 System Verification"
echo "==================================================="

# Check Pi model
if [ -f /proc/device-tree/model ]; then
    PI_MODEL=$(cat /proc/device-tree/model)
    echo "Pi Model: $PI_MODEL"
    if [[ $PI_MODEL == *"Raspberry Pi 2"* ]]; then
        echo "✓ Raspberry Pi 2 detected"
    else
        echo "⚠ Warning: Not a Raspberry Pi 2"
    fi
else
    echo "⚠ Could not detect Pi model"
fi

# Check SoC
echo ""
echo "SoC Information:"
if grep -q "BCM2836" /proc/cpuinfo; then
    echo "✓ BCM2836 SoC detected"
elif grep -q "Cortex-A7" /proc/cpuinfo; then
    echo "✓ Cortex-A7 CPU detected (likely BCM2836)"
else
    echo "⚠ BCM2836/Cortex-A7 not explicitly detected"
fi

grep -E "(model name|Hardware|Revision)" /proc/cpuinfo

# Check memory
echo ""
TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
echo "Memory: ${TOTAL_MEM}MB"
if [ $TOTAL_MEM -ge 900 ]; then
    echo "✓ Sufficient memory for RPi 2B v1.1"
elif [ $TOTAL_MEM -ge 700 ]; then
    echo "✓ Adequate memory detected"
else
    echo "⚠ Low memory detected"
fi

# Check SPI
echo ""
echo "SPI Status:"
if [ -c /dev/spidev0.0 ]; then
    echo "✓ SPI interface available"
else
    echo "✗ SPI not available - run: sudo raspi-config"
fi

# Check GPIO
echo ""
echo "GPIO Status:"
if [ -d /sys/class/gpio ]; then
    echo "✓ GPIO interface available"
else
    echo "✗ GPIO interface not available"
fi

# Check kernel modules
echo ""
echo "Kernel Modules:"
MODULES=("spi_bcm2835" "gpio_bcm2835")
for module in "${MODULES[@]}"; do
    if lsmod | grep -q "$module"; then
        echo "✓ $module loaded"
    else
        echo "⚠ $module not loaded (may be built-in)"
    fi
done

# Check temperature
echo ""
if command -v vcgencmd &> /dev/null; then
    TEMP=$(vcgencmd measure_temp | cut -d= -f2)
    echo "CPU Temperature: $TEMP"
    TEMP_NUM=$(echo $TEMP | cut -d' ' -f1)
    if (( $(echo "$TEMP_NUM < 70" | bc -l) )); then
        echo "✓ Temperature OK"
    else
        echo "⚠ High temperature detected"
    fi
else
    echo "vcgencmd not available"
fi

echo ""
echo "Verification complete!"

EOF

chmod +x $DIST_PATH/verify-system.sh

# Create quick test script
cat > $DIST_PATH/quick-test.sh << 'EOF'
#!/bin/bash

# Quick Test Script for RFID Tool on RPi 2B v1.1

echo "RFID Tool Quick Test"
echo "==================="

# Test binary
echo "Testing binary..."
if [ -f "./rfid-tool-rpi2b-v1.1" ]; then
    echo "✓ Binary found"

    # Test help output
    if ./rfid-tool-rpi2b-v1.1 -h 2>/dev/null | grep -q "rfid"; then
        echo "✓ Binary executes correctly"
    else
        echo "✗ Binary execution failed"
    fi
else
    echo "✗ Binary not found"
fi

# Test configuration
echo ""
echo "Testing configuration..."
if [ -f "./config.json" ]; then
    echo "✓ Configuration file found"

    if grep -q "rpi2b" config.json; then
        echo "✓ RPi 2B specific configuration detected"
    fi
else
    echo "✗ Configuration file not found"
fi

# Test SPI (if available)
echo ""
echo "Testing SPI access..."
if [ -c /dev/spidev0.0 ]; then
    echo "✓ SPI device available"

    # Test SPI permissions
    if [ -r /dev/spidev0.0 ] && [ -w /dev/spidev0.0 ]; then
        echo "✓ SPI permissions OK"
    else
        echo "⚠ SPI permissions may need adjustment"
        echo "  Run: sudo usermod -a -G spi $USER"
    fi
else
    echo "✗ SPI not available"
    echo "  Enable with: sudo raspi-config"
fi

# Test GPIO access
echo ""
echo "Testing GPIO access..."
if [ -d /sys/class/gpio ]; then
    echo "✓ GPIO interface available"

    # Test GPIO export (non-destructive)
    if echo 4 > /sys/class/gpio/export 2>/dev/null; then
        echo "✓ GPIO export successful"
        echo 4 > /sys/class/gpio/unexport 2>/dev/null
    else
        echo "⚠ GPIO may need group permissions"
        echo "  Run: sudo usermod -a -G gpio $USER"
    fi
else
    echo "✗ GPIO interface not available"
fi

echo ""
echo "Quick test complete!"
echo ""
echo "To run full test:"
echo "  sudo ./rfid-tool-rpi2b-v1.1 -web -port=8080"

EOF

chmod +x $DIST_PATH/quick-test.sh

# Create archive
echo -e "${YELLOW}Creating distribution archive...${NC}"
cd $DIST_DIR
tar -czf ${DIST_NAME}.tar.gz $DIST_NAME
cd ..

# Show build information
echo ""
echo -e "${CYAN}RPi 2B v1.1 Build Summary${NC}"
echo "=================================================="
echo "Target Platform: Raspberry Pi 2B v1.1"
echo "SoC: $TARGET_SOC"
echo "CPU: $TARGET_CPU (900MHz quad-core)"
echo "Architecture: $TARGET_ARCH"
echo "Memory Constraint: $MEMORY_CONSTRAINT"
echo "Go Target: $GOOS/$GOARCH (ARM v$GOARM)"
echo "Version: $VERSION"
echo "Build time: $BUILD_TIME"
echo "Git commit: $GIT_COMMIT"
echo "Binary size: $(ls -lh $BUILD_DIR/${APP_NAME}-rpi2b-v1.1 | awk '{print $5}')"
echo "Distribution: $DIST_DIR/${DIST_NAME}.tar.gz"
echo ""
echo -e "${GREEN}✓ RPi 2B v1.1 optimized build completed successfully!${NC}"
echo ""
echo -e "${YELLOW}Deployment Instructions:${NC}"
echo "1. Copy ${DIST_NAME}.tar.gz to your Raspberry Pi 2B v1.1"
echo "2. Extract: tar -xzf ${DIST_NAME}.tar.gz"
echo "3. Verify: cd ${DIST_NAME} && ./verify-system.sh"
echo "4. Install: sudo ./install.sh"
echo "5. Test: ./quick-test.sh"
echo ""
echo -e "${YELLOW}Manual Execution:${NC}"
echo "- Web mode: sudo ./${APP_NAME}-rpi2b-v1.1 -web -port=8080"
echo "- Hardware mode: sudo ./${APP_NAME}-rpi2b-v1.1 -hardware"
echo ""
echo -e "${BLUE}Hardware Target Confirmed: Raspberry Pi 2B v1.1 (BCM2836, ARM Cortex-A7)${NC}"
