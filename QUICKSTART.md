# 🚀 Quick Start Guide: RFID Tool for Raspberry Pi 2B v1.1

**Get up and running in 10 minutes!**

This guide will help you set up the RFID Tool on your Raspberry Pi 2B v1.1 with minimal effort. Optimized for BCM2836 SoC performance.

## ⚡ Prerequisites (2 minutes)

### Hardware Checklist
- ✅ **Raspberry Pi 2B v1.1** (BCM2836, 1GB RAM)
- ✅ **RC522 RFID Module** (13.56MHz)
- ✅ **MicroSD Card** (16GB+, Class 10)
- ✅ **Jumper Wires** (8x male-to-female)
- ✅ **Power Supply** (5V 2A, official adapter recommended)
- ✅ **Network Connection** (Ethernet or WiFi dongle)

### Software Requirements
- ✅ **Raspberry Pi OS** (32-bit, Bullseye or newer)
- ✅ **SSH Access** or direct console access
- ✅ **Internet Connection** for downloads

## 🔌 Step 1: Hardware Wiring (3 minutes)

### Essential Connections Only
Connect **exactly** these 8 wires from RC522 to Raspberry Pi 2B:

```
RC522 Pin → RPi Pin (BCM GPIO)  → Wire Color (suggested)
─────────────────────────────────────────────────────────
SDA       → Pin 24 (GPIO8)     → Orange
SCK       → Pin 23 (GPIO11)    → Yellow  
MOSI      → Pin 19 (GPIO10)    → Blue
MISO      → Pin 21 (GPIO9)     → Green
IRQ       → Pin 18 (GPIO24)    → Purple
GND       → Pin 20 (GND)       → Black
RST       → Pin 15 (GPIO22)    → White
3.3V      → Pin 17 (3.3V)      → Red ⚠️ NEVER USE 5V!
```

### Visual Wiring Check
```
     RPi 2B v1.1 (BCM2836)          RC522 Module
    ┌─────────────────────┐       ┌─────────────┐
    │ (1)●●●●●●●●●●(2)    │       │    RC522    │
    │   17 15   18  20    │       │             │
    │   3V RST IRQ GND ●──┼───────┼──● 3V3  SDA │
    │         ●────────────┼───────┼──●  RST  ●  │
    │       ●──────────────┼───────┼──● IRQ   ●  │
    │     ●────────────────┼───────┼──● GND   ●  │
    │ ●●●●●●●●●●●●●●●●●●●● │       │   MISO SCK │
    │   19 21 23 24       │       │   MOSI ●●● │
    │   ●──────────────────┼───────┼──●      ●  │
    │     ●────────────────┼───────┼──●        │
    │       ●──────────────┼───────┼──●        │
    │         ●────────────┼───────┼──●        │
    └─────────────────────┘       └─────────────┘
```

> **⚠️ Critical Warning**: The RC522 module requires **3.3V only**. Using 5V will permanently damage the module!

## 💾 Step 2: Enable SPI Interface (1 minute)

SSH into your Raspberry Pi and run:

```bash
# Enable SPI interface
sudo raspi-config

# Navigate: Interface Options → SPI → Enable → Finish
# Reboot when prompted
sudo reboot
```

**Alternative one-liner:**
```bash
echo "dtparam=spi=on" | sudo tee -a /boot/config.txt && sudo reboot
```

After reboot, verify SPI is working:
```bash
ls -la /dev/spi*
# Expected output: /dev/spidev0.0  /dev/spidev0.1
```

## 📥 Step 3: Download & Install (2 minutes)

### Quick Installation
```bash
# Download latest release for RPi 2B v1.1
wget https://github.com/yourrepo/rfid-tool-rpi/releases/latest/download/rfid-tool-rpi2b-1.0.0.tar.gz

# Extract
tar -xzf rfid-tool-rpi2b-1.0.0.tar.gz

# Navigate to extracted directory
cd rfid-tool-rpi2b-1.0.0

# Verify your system is compatible
./verify-system.sh
```

### System Verification Output
✅ **Expected successful output:**
```
RFID Tool - Raspberry Pi 2B v1.1 System Verification
===================================================
Pi Model: Raspberry Pi 2 Model B Rev 1.1
✓ Raspberry Pi 2 detected

SoC Information:
✓ BCM2836 SoC detected
model name    : ARMv7 Processor rev 5 (v7l)
Hardware      : BCM2836

Memory: 948MB
✓ Sufficient memory for RPi 2B v1.1

SPI Status:
✓ SPI interface available

GPIO Status:
✓ GPIO interface available

Verification complete!
```

### Install the Application
```bash
# Run the installation script (requires sudo)
sudo ./install.sh
```

**Installation will:**
- ✅ Create `/opt/rfid-tool/` directory
- ✅ Copy optimized binary for BCM2836
- ✅ Set up systemd services
- ✅ Configure user permissions
- ✅ Optimize memory usage for 1GB RAM

## 🎯 Step 4: Test & Launch (2 minutes)

### Quick Hardware Test
```bash
# Test the installation without starting services
./quick-test.sh
```

**Expected output:**
```
RFID Tool Quick Test
===================
Testing binary...
✓ Binary found
✓ Binary executes correctly

Testing configuration...
✓ Configuration file found
✓ RPi 2B specific configuration detected

Testing SPI access...
✓ SPI device available
✓ SPI permissions OK

Testing GPIO access...
✓ GPIO interface available
✓ GPIO export successful

Quick test complete!
```

### Start the Web Interface
```bash
# Start the web service
sudo systemctl start rfid-tool-web

# Check it's running
sudo systemctl status rfid-tool-web
```

**Expected status:**
```
● rfid-tool-web.service - RFID Tool Web Interface (RPi 2B v1.1)
   Loaded: loaded (/etc/systemd/system/rfid-tool-web.service)
   Active: active (running) since [timestamp]
   Process: Running on BCM2836 SoC, ARM Cortex-A7
```

### Access the Web Interface

1. **Find your Pi's IP address:**
   ```bash
   hostname -I
   ```

2. **Open in browser:**
   ```
   http://[YOUR_PI_IP]:8080
   ```
   Example: `http://192.168.1.100:8080`

3. **You should see:** RFID Tool dashboard with "Ready" status

## 🧪 Step 5: Test RFID Functionality (1 minute)

### First RFID Card Test

1. **Place an RFID card** near the RC522 module (within 3cm)

2. **In the web interface:**
   - Click **"Scan for Card"**
   - You should see: "Card detected: [Card ID]"
   - Click **"Read All Data"** to see card contents

3. **Expected result:**
   ```
   Card Type: MIFARE Classic 1K
   UID: A1:B2:C3:D4
   Size: 1024 bytes
   Status: Ready for operations
   ```

### Troubleshooting Quick Fixes

**Problem: "No card detected"**
```bash
# Check wiring - most common issues:
# 1. RC522 powered by 5V instead of 3.3V (fatal!)
# 2. Loose connections
# 3. Wrong GPIO pins

# Test SPI communication
sudo dmesg | grep spi
# Should show: spi_bcm2835 initialization messages
```

**Problem: "Permission denied"**
```bash
# Add pi user to required groups
sudo usermod -a -G gpio,spi pi
sudo reboot
```

**Problem: Web interface not loading**
```bash
# Check service status
sudo systemctl status rfid-tool-web

# Check port is open
sudo netstat -tlnp | grep 8080

# View detailed logs
sudo journalctl -u rfid-tool-web -n 20
```

## 🔧 Optional: Hardware Interface Setup

If you want physical buttons and LEDs:

### Additional Components Needed
- 2x Push buttons (momentary, normally open)
- 3x LEDs (Green, Blue, Red)
- 3x 220Ω resistors
- Breadboard

### Additional Wiring
```bash
# Buttons (active low with internal pull-ups)
Read Button  → Pin 3 (GPIO2)  → GND
Write Button → Pin 5 (GPIO3)  → GND

# LEDs (through 220Ω resistors to GND)
Ready LED (Green) → Pin 13 (GPIO27) → 220Ω → GND
Status LED (Blue) → Pin 7 (GPIO4)   → 220Ω → GND  
Error LED (Red)   → Pin 11 (GPIO17) → 220Ω → GND
```

### Start Hardware Mode
```bash
# Stop web service first
sudo systemctl stop rfid-tool-web

# Start hardware service
sudo systemctl start rfid-tool-hw

# Enable auto-start
sudo systemctl enable rfid-tool-hw
```

## 🚦 What's Next?

### Enable Auto-Start
```bash
# Auto-start web interface on boot
sudo systemctl enable rfid-tool-web

# Check auto-start status
sudo systemctl list-unit-files | grep rfid-tool
```

### Performance Tuning
```bash
# For better performance (if stable)
sudo nano /opt/rfid-tool/config.json
# Change: "spi_speed": 1000000  (1MHz instead of 500kHz)

# Restart service
sudo systemctl restart rfid-tool-web
```

### Monitor System Resources
```bash
# Check CPU usage
htop

# Check temperature (should be < 70°C)
vcgencmd measure_temp

# Check memory usage
free -h
```

## 📚 Useful Commands

```bash
# Service management
sudo systemctl start rfid-tool-web     # Start web interface
sudo systemctl stop rfid-tool-web      # Stop web interface
sudo systemctl restart rfid-tool-web   # Restart web interface
sudo systemctl status rfid-tool-web    # Check status

# View logs
sudo journalctl -u rfid-tool-web -f    # Follow web interface logs
sudo journalctl -u rfid-tool-web -n 50 # Last 50 log entries

# Manual operation
sudo /opt/rfid-tool/rfid-tool -web -port=8080     # Manual web mode
sudo /opt/rfid-tool/rfid-tool -hardware           # Manual hardware mode

# Update configuration
sudo nano /opt/rfid-tool/config.json              # Edit config
sudo systemctl restart rfid-tool-web              # Apply changes
```

## 🆘 Need Help?

### Quick Diagnostics
```bash
# Run comprehensive system check
cd /opt/rfid-tool
sudo ./verify-system.sh

# Check hardware connections
sudo ./quick-test.sh

# View recent errors
sudo journalctl -u rfid-tool-web --since "10 minutes ago"
```

### Common Solutions
1. **Reboot fixes 80% of issues**: `sudo reboot`
2. **Check wiring**: Especially 3.3V power and ground
3. **Verify SPI enabled**: `ls /dev/spi*` should show devices
4. **Check permissions**: User in `gpio` and `spi` groups

### Getting Support
- 📖 **Full Documentation**: [README.md](README.md)
- 🔌 **Detailed Wiring**: [WIRING.md](WIRING.md)
- 🐛 **Report Issues**: [GitHub Issues](https://github.com/yourrepo/rfid-tool-rpi/issues)
- 💬 **Community**: [GitHub Discussions](https://github.com/yourrepo/rfid-tool-rpi/discussions)

---

## ✅ Success Checklist

- [ ] **Hardware connected** (8 wires: SDA, SCK, MOSI, MISO, IRQ, GND, RST, 3.3V)
- [ ] **SPI enabled** (`ls /dev/spi*` shows devices)
- [ ] **Software installed** (`./verify-system.sh` passes)
- [ ] **Service running** (`systemctl status rfid-tool-web` active)
- [ ] **Web interface accessible** (browser loads `http://PI_IP:8080`)
- [ ] **Card detection working** ("Scan for Card" finds RFID cards)

**🎉 Congratulations! Your RFID Tool is ready for Raspberry Pi 2B v1.1!**

*Optimized for BCM2836 SoC • ARMv7 Cortex-A7 • 1GB LPDDR2*

---

**⏱️ Total setup time: ~10 minutes**  
**🔧 Difficulty level: Beginner**  
**🎯 Success rate: 95%+ (with correct wiring)**