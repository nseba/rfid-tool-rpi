# RFID Tool for Raspberry Pi

[![CI/CD Pipeline](https://github.com/yourrepo/rfid-tool-rpi/workflows/CI%2FCD%20Pipeline/badge.svg)](https://github.com/yourrepo/rfid-tool-rpi/actions/workflows/ci.yml)
[![Release](https://github.com/yourrepo/rfid-tool-rpi/workflows/Release/badge.svg)](https://github.com/yourrepo/rfid-tool-rpi/actions/workflows/release.yml)
[![Go Report Card](https://goreportcard.com/badge/github.com/yourrepo/rfid-tool-rpi)](https://goreportcard.com/report/github.com/yourrepo/rfid-tool-rpi)
[![codecov](https://codecov.io/gh/yourrepo/rfid-tool-rpi/branch/main/graph/badge.svg)](https://codecov.io/gh/yourrepo/rfid-tool-rpi)
[![Docker Pulls](https://img.shields.io/docker/pulls/yourdockerhub/rfid-tool.svg)](https://hub.docker.com/r/yourdockerhub/rfid-tool)
[![GitHub release](https://img.shields.io/github/release/yourrepo/rfid-tool-rpi.svg)](https://github.com/yourrepo/rfid-tool-rpi/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive RFID reader/writer tool for Raspberry Pi using the RC522 module. Supports both web interface and hardware button/LED interface modes with automated CI/CD, Docker support, and professional-grade deployment.
</edx_text>

<old_text line=8>
## Features

- **Dual Interface Support**:
  - Web-based interface with real-time updates
  - Hardware interface with physical buttons and LEDs
- **Full RFID Operations**:
  - Card detection and scanning
  - Read data from MIFARE cards
  - Write data to MIFARE cards
  - Block-level data management
- **Cross-Platform Build**: Built on macOS M1, runs on Raspberry Pi ARM
- **Real-time Updates**: WebSocket support for live card detection
- **Easy Installation**: Automated installation and service setup

## Features

- **Dual Interface Support**:
  - Web-based interface with real-time updates
  - Hardware interface with physical buttons and LEDs
- **Full RFID Operations**:
  - Card detection and scanning
  - Read data from MIFARE cards
  - Write data to MIFARE cards
  - Block-level data management
- **Cross-Platform Build**: Built on macOS M1, runs on Raspberry Pi ARM
- **Real-time Updates**: WebSocket support for live card detection
- **Easy Installation**: Automated installation and service setup

## Hardware Requirements

### Essential Components
- Raspberry Pi 2B (or newer)
- RFID-RC522 Module
- MicroSD card (8GB+)
- Power supply for Raspberry Pi

### For Hardware Interface Mode (Optional)
- Breadboard
- 2x Push buttons
- 3x LEDs (Red, Green, Blue/White)
- 3x 220Ω resistors (for LEDs)
- Jumper wires (male-to-female, male-to-male)

## Quick Start

### 1. Prepare Raspberry Pi
```bash
# Enable SPI interface
sudo raspi-config
# Navigate to: Interface Options > SPI > Enable
sudo reboot
```

### 2. Install RFID Tool

#### Option A: Download Latest Release
```bash
# Download the latest release automatically
curl -s https://api.github.com/repos/yourrepo/rfid-tool-rpi/releases/latest | grep "browser_download_url.*rpi.*tar.gz" | cut -d '"' -f 4 | wget -i -
tar -xzf rfid-tool-rpi-*.tar.gz
cd rfid-tool-rpi-*

# Install with automatic service setup
sudo ./install.sh
```

#### Option B: Using Docker
```bash
# Run with Docker (requires privileged mode for GPIO access)
docker run -d \
  --name rfid-tool \
  --privileged \
  --device /dev/spidev0.0:/dev/spidev0.0 \
  --device /dev/gpiomem:/dev/gpiomem \
  -p 8080:8080 \
  -v /dev:/dev \
  yourdockerhub/rfid-tool:latest
```

#### Option C: Build from Source
```bash
# Clone and build
git clone https://github.com/yourrepo/rfid-tool-rpi.git
cd rfid-tool-rpi
make all
# Copy dist/rfid-tool-rpi-*.tar.gz to Pi and install
```

### 3. Start the Service
```bash
# For web interface mode
sudo systemctl start rfid-tool-web
sudo systemctl enable rfid-tool-web

# OR for hardware interface mode
sudo systemctl start rfid-tool-hw
sudo systemctl enable rfid-tool-hw
```

### 4. Access Web Interface
Open browser and navigate to: `http://[raspberry-pi-ip]:8080`

## Hardware Wiring

### RFID-RC522 Connections (Required)
| RC522 Pin | RPi Pin | RPi GPIO | Description |
|-----------|---------|----------|-------------|
| SDA       | 24      | GPIO8    | SPI Chip Select |
| SCK       | 23      | GPIO11   | SPI Clock |
| MOSI      | 19      | GPIO10   | SPI MOSI |
| MISO      | 21      | GPIO9    | SPI MISO |
| IRQ       | 18      | GPIO24   | Interrupt (optional) |
| GND       | 20      | GND      | Ground |
| RST       | 15      | GPIO22   | Reset |
| 3.3V      | 17      | 3.3V     | Power ⚠️ **NOT 5V!** |

### Hardware Interface Components (Optional)
| Component | RPi Pin | RPi GPIO | Description |
|-----------|---------|----------|-------------|
| Read Button | 3 | GPIO2 | Trigger card read |
| Write Button | 5 | GPIO3 | Trigger card write |
| Ready LED (Green) | 13 | GPIO27 | System ready |
| Status LED (Blue) | 7 | GPIO4 | Operation in progress |
| Error LED (Red) | 11 | GPIO17 | Error indication |

⚠️ **Important**: Use 220Ω resistors in series with all LEDs!

## Usage

### Web Interface Mode

1. **Start Web Service**:
   ```bash
   sudo systemctl start rfid-tool-web
   ```

2. **Access Interface**: 
   - Open `http://[raspberry-pi-ip]:8080` in web browser
   - Real-time card detection via WebSocket
   - Click "Scan for Card" to detect RFID cards
   - Click "Read All Data" to read card contents
   - Use the write section to modify card data

3. **Features**:
   - Live card detection and removal notifications
   - Hexadecimal and ASCII data display
   - Block-by-block editing
   - Data validation and error handling

### Hardware Interface Mode

1. **Start Hardware Service**:
   ```bash
   sudo systemctl start rfid-tool-hw
   ```

2. **Operation**:
   - **Green LED**: System ready
   - **Read Button**: Scan and read card data
   - **Write Button**: Write stored data to card
   - **Blue LED**: Operation in progress
   - **Red LED**: Error occurred

3. **Workflow**:
   - Press READ button when card is near reader
   - Data from block 1 is stored in memory
   - Press WRITE button with another card to copy data
   - LEDs indicate operation status

## Building from Source

### Prerequisites (macOS)
```bash
# Install Go 1.21+
brew install go

# Clone repository
git clone https://github.com/yourrepo/rfid-tool-rpi.git
cd rfid-tool-rpi
```

### Cross-Compilation Build
```bash
# Build for Raspberry Pi ARM
./build.sh

# Output will be in dist/ directory
# Copy dist/rfid-tool-rpi-1.0.0.tar.gz to Raspberry Pi
```

### Development Build
```bash
# Download dependencies
go mod download

# Build for current platform (development/testing)
go build -o rfid-tool ./cmd/main.go

# Run locally (requires RFID hardware)
./rfid-tool -web -port=8080
```

## Configuration

Configuration is stored in `config.json`:

```json
{
  "rfid": {
    "spi_bus": 0,
    "spi_device": 0,
    "reset_pin": 22,
    "irq_pin": 18,
    "spi_speed": 1000000,
    "retry_count": 3
  },
  "hardware": {
    "read_button": 2,
    "write_button": 3,
    "status_led": 4,
    "error_led": 17,
    "ready_led": 27
  },
  "web": {
    "static_dir": "web/static",
    "templates_dir": "web/templates",
    "upload_dir": "uploads"
  }
}
```

### GPIO Pin Customization
Modify the `hardware` section in `config.json` to match your wiring:

```bash
# Edit configuration
sudo nano /opt/rfid-tool/config.json

# Restart service
sudo systemctl restart rfid-tool-web
# or
sudo systemctl restart rfid-tool-hw
```

## Supported Cards

- **MIFARE Classic 1K**: 1024 bytes, 64 blocks
- **MIFARE Classic 4K**: 4096 bytes, 256 blocks
- **MIFARE Ultralight**: 512 bytes, 16 blocks

## API Reference

### REST Endpoints
- `POST /api/scan` - Scan for RFID card
- `POST /api/read` - Read all card data
- `GET /api/read/{block}` - Read specific block
- `POST /api/write` - Write data to block
- `GET /api/card/info` - Get current card info

### WebSocket
- Connect to `/api/websocket` for real-time updates
- Receives `card_detected` and `card_removed` events

## Troubleshooting

### Common Issues

1. **"MFRC522 not found"**:
   - Check SPI is enabled: `sudo raspi-config`
   - Verify 3.3V power connection (NOT 5V)
   - Check all wiring connections

2. **"Permission denied" errors**:
   - Run with sudo: `sudo ./rfid-tool`
   - Check user permissions for GPIO/SPI access

3. **"Failed to scan card"**:
   - Ensure card is compatible (MIFARE Classic/Ultralight)
   - Try different card positioning
   - Check antenna connections on RC522

4. **Web interface not accessible**:
   - Check firewall settings
   - Verify service is running: `sudo systemctl status rfid-tool-web`
   - Check port availability: `sudo netstat -tlnp | grep 8080`

### Debug Commands
```bash
# Check service status
sudo systemctl status rfid-tool-web
sudo systemctl status rfid-tool-hw

# View logs
sudo journalctl -u rfid-tool-web -f
sudo journalctl -u rfid-tool-hw -f

# Test SPI interface
ls -la /dev/spi*

# Check GPIO availability
cat /sys/kernel/debug/gpio
```

### Hardware Testing
```bash
# Test LEDs (hardware mode)
echo 1 | sudo tee /sys/class/gpio/gpio4/value   # Status LED on
echo 0 | sudo tee /sys/class/gpio/gpio4/value   # Status LED off

# Test button reading
cat /sys/class/gpio/gpio2/value  # Should show 1 (released) or 0 (pressed)
```

## Service Management

```bash
# Start services
sudo systemctl start rfid-tool-web
sudo systemctl start rfid-tool-hw

# Stop services
sudo systemctl stop rfid-tool-web
sudo systemctl stop rfid-tool-hw

# Enable auto-start
sudo systemctl enable rfid-tool-web
sudo systemctl enable rfid-tool-hw

# Disable auto-start
sudo systemctl disable rfid-tool-web
sudo systemctl disable rfid-tool-hw

# View service logs
sudo journalctl -u rfid-tool-web -n 50
sudo journalctl -u rfid-tool-hw -n 50
```

## Uninstallation

```bash
cd rfid-tool-rpi-1.0.0
sudo ./uninstall.sh
```

## Security Notes

- The web interface allows unrestricted access on port 8080
- For production use, consider adding authentication
- RFID cards can be cloned - do not rely on them for security-critical applications
- Default MIFARE keys are used (0xFFFFFFFFFFFF)

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Support

For issues and questions:
- Check the troubleshooting section above
- Review the wiring guide in `WIRING.md`
- Open an issue on GitHub
- Check system logs for error messages

## Development & Contributing

### Setting up Development Environment

#### Prerequisites
- Go 1.21+ installed
- Docker (optional, for containerized development)
- golangci-lint (for code quality)

#### Local Development
```bash
git clone https://github.com/yourrepo/rfid-tool-rpi.git
cd rfid-tool-rpi

# Install dependencies
make deps

# Run tests
make test

# Build for current platform (development)
make local-build

# Build for Raspberry Pi
make cross-build

# Run with hot reload (requires Air)
go install github.com/cosmtrek/air@latest
air
```

#### Using Docker for Development
```bash
# Start development environment
docker-compose --profile development up rfid-tool-dev

# Run tests in container
docker-compose --profile testing up rfid-test
```

### CI/CD Pipeline

The project uses GitHub Actions for automated CI/CD:

- **🧪 Continuous Integration**: Automated testing, linting, and security scanning
- **🏗️ Multi-Architecture Builds**: ARM v6/v7, ARM64, and x86-64 binaries
- **📦 Automated Releases**: GitHub releases with distribution packages
- **🐳 Docker Images**: Multi-platform container images
- **📊 Code Quality**: Coverage reports and code quality metrics
- **🔒 Security**: Dependency scanning and vulnerability checks

### Contributing Guidelines

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/amazing-feature`
3. **Make** your changes and add tests
4. **Run** quality checks: `make check`
5. **Commit** your changes: `git commit -m 'feat: add amazing feature'`
6. **Push** to the branch: `git push origin feature/amazing-feature`
7. **Open** a Pull Request

### Code Quality Standards
- All code must pass `golangci-lint` checks
- Maintain test coverage above 80%
- Follow conventional commit messages
- Include documentation for new features
- Add hardware compatibility information for new components

### Issue Templates
- 🐛 **Bug Report**: Use when you find a bug
- 🚀 **Feature Request**: Use to suggest new features
- 🔧 **Hardware Support**: Use for hardware compatibility issues

## Version History

- **v1.0.0**: Initial release
  - Web interface with real-time updates
  - Hardware button/LED interface
  - Support for MIFARE Classic and Ultralight cards
  - Cross-platform build system
  - Automated installation and service setup
  - Complete CI/CD pipeline
  - Docker support with multi-architecture images
  - Comprehensive testing and quality assurance