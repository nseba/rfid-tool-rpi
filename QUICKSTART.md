# Quick Start Guide - RFID Tool for Raspberry Pi

This guide will get you up and running with the RFID Tool in under 10 minutes.

## Prerequisites

- Raspberry Pi 2B or newer with Raspberry Pi OS
- RFID-RC522 module
- Breadboard and jumper wires
- SD card with at least 8GB
- Internet connection

## Step 1: Hardware Setup (5 minutes)

### Essential Connections Only
Connect your RFID-RC522 module to the Raspberry Pi as follows:

| RC522 Pin | RPi Pin | RPi GPIO | Wire Color |
|-----------|---------|----------|------------|
| 3.3V      | 17      | 3.3V     | Red        |
| RST       | 15      | GPIO22   | White      |
| GND       | 20      | GND      | Black      |
| IRQ       | 18      | GPIO24   | Purple     |
| MISO      | 21      | GPIO9    | Green      |
| MOSI      | 19      | GPIO10   | Blue       |
| SCK       | 23      | GPIO11   | Yellow     |
| SDA       | 24      | GPIO8    | Orange     |

⚠️ **CRITICAL**: Use 3.3V only! 5V will damage the RC522 module.

## Step 2: Enable SPI (1 minute)

```bash
sudo raspi-config
```
- Navigate to: **Interface Options** → **SPI** → **Enable**
- Reboot: `sudo reboot`

## Step 3: Install RFID Tool (2 minutes)

```bash
# Download the latest release
wget https://github.com/yourrepo/rfid-tool-rpi/releases/latest/download/rfid-tool-rpi-1.0.0.tar.gz

# Extract
tar -xzf rfid-tool-rpi-1.0.0.tar.gz
cd rfid-tool-rpi-1.0.0

# Install
sudo ./install.sh
```

## Step 4: Start Web Interface (30 seconds)

```bash
# Start the web service
sudo systemctl start rfid-tool-web

# Check it's running
sudo systemctl status rfid-tool-web
```

## Step 5: Access Web Interface (30 seconds)

1. Find your Raspberry Pi's IP address:
   ```bash
   hostname -I
   ```

2. Open your browser and go to: `http://[your-pi-ip]:8080`

3. You should see the RFID Tool interface!

## Step 6: Test with an RFID Card (1 minute)

1. Click **"Scan for Card"**
2. Place an RFID card near the RC522 module
3. You should see card information appear
4. Click **"Read All Data"** to see the card contents
5. Use the write section to modify card data

## Alternative: Hardware Interface Mode

If you prefer physical buttons and LEDs:

### Additional Hardware Needed:
- 2x Push buttons
- 3x LEDs (Red, Green, Blue)  
- 3x 220Ω resistors
- Additional jumper wires

### Additional Connections:
| Component | RPi Pin | RPi GPIO |
|-----------|---------|----------|
| Read Button | 3 | GPIO2 |
| Write Button | 5 | GPIO3 |
| Ready LED | 13 | GPIO27 |
| Status LED | 7 | GPIO4 |
| Error LED | 11 | GPIO17 |

### Start Hardware Mode:
```bash
# Stop web service first
sudo systemctl stop rfid-tool-web

# Start hardware service
sudo systemctl start rfid-tool-hw
```

### Usage:
- **Green LED**: System ready
- **Press READ button**: Scan and store card data
- **Press WRITE button**: Write stored data to new card
- **Blue LED**: Operation in progress
- **Red LED**: Error occurred

## Troubleshooting

### "MFRC522 not found" Error
- Check SPI is enabled: `sudo raspi-config`
- Verify 3.3V connection (not 5V!)
- Double-check all wire connections

### "Permission denied" Error
- Run with sudo: `sudo systemctl start rfid-tool-web`
- Check user groups: `groups pi`

### Web interface not accessible
- Check service status: `sudo systemctl status rfid-tool-web`
- Check firewall: `sudo ufw status`
- Verify port 8080 is not blocked

### Card detection issues
- Ensure card is MIFARE compatible
- Try different card positions
- Check for loose antenna connections

## Getting Help

- **Logs**: `sudo journalctl -u rfid-tool-web -f`
- **Configuration**: `/opt/rfid-tool/config.json`
- **Full documentation**: `README.md`
- **Wiring guide**: `WIRING.md`

## What's Next?

- **Auto-start on boot**: `sudo systemctl enable rfid-tool-web`
- **Customize GPIO pins**: Edit `/opt/rfid-tool/config.json`
- **Add authentication**: Modify the web interface
- **Backup cards**: Use the read/write functions to clone cards

You're now ready to read and write RFID cards with your Raspberry Pi! 🎉

---

For detailed wiring diagrams, advanced configuration, and troubleshooting, see the full `README.md` and `WIRING.md` files.