# RFID-RC522 Wiring Guide for Raspberry Pi 2B v1.1

## Board Information

- **Model**: Raspberry Pi 2B v1.1
- **SoC**: BCM2836 (Broadcom)
- **CPU**: ARM Cortex-A7 quad-core @ 900MHz
- **Architecture**: ARMv7
- **Memory**: 1GB LPDDR2 SDRAM
- **GPIO**: 40-pin header (BCM2835 driver compatible)
- **Release Date**: February 2015

## Overview

This guide provides detailed instructions for connecting the RFID-RC522 module to a Raspberry Pi 2B v1.1 using a breadboard. The setup supports both web interface and hardware button/LED interface modes, optimized specifically for the BCM2836 SoC.

## Required Components

### Essential Components (RFID Only)
- **Raspberry Pi 2B v1.1** (BCM2836, 1GB RAM)
- **RFID-RC522 Module** (13.56MHz)
- **Breadboard** (830-point recommended)
- **Jumper Wires**: 8x Male-to-Female (RPi to breadboard)

### For Hardware Interface (Optional)
- **Push Buttons**: 2x momentary, normally open
- **LEDs**: 3x (Green, Blue/White, Red)
- **Resistors**: 3x 220Ω (LED current limiting)
- **Additional Jumper Wires**: 10+ Male-to-Male (breadboard connections)

## Raspberry Pi 2B v1.1 GPIO Pinout

```
    Raspberry Pi 2B v1.1 - 40-Pin GPIO Header
    ┌─────────────────────────────────────────┐
    │  3V3  (1) (2)  5V     <- Never use 5V   │
    │ GPIO2 (3) (4)  5V        for RC522!     │
    │ GPIO3 (5) (6)  GND                      │
    │ GPIO4 (7) (8)  GPIO14                   │
    │  GND  (9) (10) GPIO15                   │
    │GPIO17 (11)(12) GPIO18                   │
    │GPIO27 (13)(14) GND                      │
    │GPIO22 (15)(16) GPIO23                   │
    │ 3V3  (17)(18) GPIO24                    │
    │GPIO10 (19)(20) GND                      │
    │ GPIO9 (21)(22) GPIO25                   │
    │GPIO11 (23)(24) GPIO8                    │
    │  GND  (25)(26) GPIO7                    │
    │ ID_SD (27)(28) ID_SC                    │
    │ GPIO5 (29)(30) GND                      │
    │ GPIO6 (31)(32) GPIO12                   │
    │GPIO13 (33)(34) GND                      │
    │GPIO19 (35)(36) GPIO16                   │
    │GPIO26 (37)(38) GPIO20                   │
    │  GND  (39)(40) GPIO21                   │
    └─────────────────────────────────────────┘
```

## RFID-RC522 Module Pinout

```
    RC522 Module Layout
    ┌─────────────────┐
    │    RC522 RFID   │
    │                 │
    │  SDA  SCK  MOSI │
    │  MISO IRQ  GND  │
    │  RST  3.3V      │
    │                 │
    │    [ANTENNA]    │
    └─────────────────┘
```

## Essential Connections (RFID Only)

### SPI Interface Connections
| RC522 Pin | Function     | RPi Pin | BCM GPIO | Wire Color | Notes |
|-----------|--------------|---------|----------|------------|-------|
| SDA       | SPI0_CE0_N   | 24      | GPIO8    | Orange     | Chip Select (active low) |
| SCK       | SPI0_SCLK    | 23      | GPIO11   | Yellow     | SPI Clock |
| MOSI      | SPI0_MOSI    | 19      | GPIO10   | Blue       | Master Out Slave In |
| MISO      | SPI0_MISO    | 21      | GPIO9    | Green      | Master In Slave Out |
| IRQ       | Interrupt    | 18      | GPIO24   | Purple     | Optional interrupt signal |
| GND       | Ground       | 20      | GND      | Black      | Common ground |
| RST       | Reset        | 15      | GPIO22   | White      | Module reset (active low) |
| 3.3V      | Power        | 17      | 3V3      | Red        | ⚠️ **3.3V ONLY!** |

### Critical Power Warning
⚠️ **The RC522 module MUST be powered with 3.3V only!**
- Using 5V will permanently damage the RC522 module
- The BCM2836 GPIO pins are 3.3V logic
- Double-check connections before powering up

## Hardware Interface Connections (Optional)

### Button Connections
| Component   | RPi Pin | BCM GPIO | Function | Notes |
|-------------|---------|----------|----------|-------|
| Read Button | 3       | GPIO2    | I2C1_SDA | Has strong internal pull-up |
| Write Button| 5       | GPIO3    | I2C1_SCL | Has strong internal pull-up |

**Button Wiring**:
- One terminal → GPIO pin (3 or 5)
- Other terminal → Ground (pins 6, 9, 14, 20, 25, 30, 34, or 39)
- No external pull-up resistor needed (using internal)

### LED Connections
| LED Component | RPi Pin | BCM GPIO | Current Limit | Function |
|---------------|---------|----------|---------------|----------|
| Ready LED (Green)  | 13 | GPIO27 | 220Ω resistor | System ready status |
| Status LED (Blue)  | 7  | GPIO4  | 220Ω resistor | Operation in progress |
| Error LED (Red)    | 11 | GPIO17 | 220Ω resistor | Error indication |

**LED Wiring**:
- LED Anode (+, longer leg) → 220Ω resistor → GPIO pin
- LED Cathode (-, shorter leg) → Ground rail

## Breadboard Layout Diagram

```
    Raspberry Pi 2B v1.1 (BCM2836)
    ┌───────────────────────────────┐
    │  ●●●●●●●●●●●●●●●●●●●●  (1-20) │
    │  ●●●●●●●●●●●●●●●●●●●● (21-40) │
    └───┬───┬───┬───┬───┬───┬───┬───┘
        │   │   │   │   │   │   │
    Power Lines to Breadboard Rails
        │   │   │   │   │   │   │
        └───┼───┼───┼───┼───┼───┼──── Pin 17 (3.3V) → + Rail
            │   │   │   │   │   └──── Pin 20 (GND)  → - Rail
            │   │   │   │   └──────── Pin 15 (GPIO22/RST)
            │   │   │   └──────────── Pin 18 (GPIO24/IRQ)
            │   │   └──────────────── Pin 19 (GPIO10/MOSI)
            │   └──────────────────── Pin 21 (GPIO9/MISO)
            └──────────────────────── Pin 23 (GPIO11/SCK)
                                   Pin 24 (GPIO8/SDA)

    Breadboard Top Section (Power Rails)
    + Rail ●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━● 3.3V
    - Rail ●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━● GND

    Breadboard Main Section (RC522 Module)
        a  b  c  d  e     f  g  h  i  j
    10  ●  ●  ●  ●  ●     ●  ●  ●  ●  ●
    11  ●  ●  ●  ●  ●     ●  ●  ●  ●  ●
    12  ┌─────────────RC522 Module─────────────┐
    13  │  SDA  SCK  MOSI  MISO IRQ  GND     │
    14  │   ●    ●    ●     ●   ●    ●      │
    15  │  RST  3V3                         │
    16  │   ●    ●                          │
    17  └───────────────────────────────────────┘
    18  ●  ●  ●  ●  ●     ●  ●  ●  ●  ●
    19  ●  ●  ●  ●  ●     ●  ●  ●  ●  ●

    Connection Wires:
    Row 14: SDA(a14) → GPIO8  (Pin 24)  Orange
            SCK(b14) → GPIO11 (Pin 23)  Yellow
            MOSI(c14)→ GPIO10 (Pin 19)  Blue
            MISO(d14)→ GPIO9  (Pin 21)  Green
            IRQ(e14) → GPIO24 (Pin 18)  Purple
            GND(f14) → GND    (Pin 20)  Black
    Row 16: RST(a16) → GPIO22 (Pin 15)  White
            3V3(b16) → 3.3V   (Pin 17)  Red

    Hardware Interface Section (Optional)
        a  b  c  d  e     f  g  h  i  j
    25  ●  ●  ●  ●  ●     ●  ●  ●  ●  ●
    26 [BTN1] [BTN2]      ●  ●  ●  ●  ●
    27  ●  ●  ●  ●  ●     ●  ●  ●  ●  ●
    28  ●  ●  ●  ●  ●    LED LED LED ●  ●
    29  ●  ●  ●  ●  ●    220Ω220Ω220Ω●  ●
    30  ●  ●  ●  ●  ●     ●  ●  ●  ●  ●
```

## Step-by-Step Wiring Instructions

### Step 1: Prepare the Breadboard
1. **Connect Power Rails**:
   - **Red wire**: RPi Pin 17 (3.3V) → Breadboard positive (+) rail
   - **Black wire**: RPi Pin 20 (GND) → Breadboard negative (-) rail

2. **Verify Power**:
   ```bash
   # Use multimeter to verify 3.3V between rails
   # Should read approximately 3.3V ± 0.1V
   ```

### Step 2: Install RC522 Module
1. **Mount the RC522** on breadboard rows 12-17 (recommended)

2. **Connect Power First**:
   - RC522 3.3V pin → + rail (red wire)
   - RC522 GND pin → - rail (black wire)

3. **Connect SPI Interface** (in this order):
   - **SDA** (RC522) → **Pin 24** (GPIO8) - Orange wire
   - **SCK** (RC522) → **Pin 23** (GPIO11) - Yellow wire
   - **MOSI** (RC522) → **Pin 19** (GPIO10) - Blue wire
   - **MISO** (RC522) → **Pin 21** (GPIO9) - Green wire

4. **Connect Control Signals**:
   - **RST** (RC522) → **Pin 15** (GPIO22) - White wire
   - **IRQ** (RC522) → **Pin 18** (GPIO24) - Purple wire (optional)

### Step 3: Hardware Interface (Optional)

#### Install Buttons:
1. **Read Button**:
   - One terminal → **Pin 3** (GPIO2) - Gray wire
   - Other terminal → **Ground rail** - Black wire

2. **Write Button**:
   - One terminal → **Pin 5** (GPIO3) - Brown wire
   - Other terminal → **Ground rail** - Black wire

#### Install LEDs:
1. **Ready LED (Green)**:
   - Anode (+) → 220Ω resistor → **Pin 13** (GPIO27)
   - Cathode (-) → Ground rail

2. **Status LED (Blue)**:
   - Anode (+) → 220Ω resistor → **Pin 7** (GPIO4)
   - Cathode (-) → Ground rail

3. **Error LED (Red)**:
   - Anode (+) → 220Ω resistor → **Pin 11** (GPIO17)
   - Cathode (-) → Ground rail

### Step 4: Final Verification

**Physical Inspection Checklist**:
- [ ] 3.3V rail connected to RPi Pin 17 (**NOT Pin 2 or 4!**)
- [ ] Ground rail connected to RPi Pin 20
- [ ] RC522 3.3V connected to + rail
- [ ] RC522 GND connected to - rail
- [ ] All 6 SPI/control wires connected correctly
- [ ] All LEDs have 220Ω current limiting resistors
- [ ] No loose connections
- [ ] No short circuits between + and - rails
- [ ] All connections firmly seated

## BCM2836-Specific Configuration

### Enable SPI Interface
```bash
# Method 1: Using raspi-config
sudo raspi-config
# Navigate: Interface Options → SPI → Enable

# Method 2: Direct configuration
echo "dtparam=spi=on" | sudo tee -a /boot/config.txt

# Reboot to apply changes
sudo reboot
```

### Verify SPI Setup
```bash
# Check SPI devices
ls -la /dev/spi*
# Expected output: /dev/spidev0.0  /dev/spidev0.1

# Check kernel modules
lsmod | grep spi
# Expected: spi_bcm2835

# Check device tree
ls /proc/device-tree/soc/spi@7e204000/
```

### Configure User Permissions
```bash
# Add user to required groups
sudo usermod -a -G gpio,spi pi

# Verify group membership
groups pi
# Should include: gpio spi

# Reboot for group changes to take effect
sudo reboot
```

## Testing Connections

### 1. Power Test
```bash
# Test 3.3V power supply
vcgencmd measure_volts core
# Should show approximately 1.2V (core voltage)

# Check 3.3V rail with multimeter
# Should read 3.3V ± 0.1V between + and - rails
```

### 2. SPI Communication Test
```bash
# Test SPI loopback (disconnect RC522 first!)
# Temporarily connect MOSI (Pin 19) to MISO (Pin 21)
python3 << 'EOF'
import spidev
try:
    spi = spidev.SpiDev()
    spi.open(0, 0)
    spi.max_speed_hz = 500000
    result = spi.xfer2([0xAA, 0x55, 0xFF, 0x00])
    print(f"SPI loopback test: {[hex(x) for x in result]}")
    if result == [0xAA, 0x55, 0xFF, 0x00]:
        print("✓ SPI communication working")
    else:
        print("✗ SPI communication failed")
    spi.close()
except Exception as e:
    print(f"SPI test failed: {e}")
EOF
# Remember to disconnect the loopback wire after testing!
```

### 3. GPIO Test (LEDs)
```bash
# Test LED functionality
# Export GPIO pins
echo 27 | sudo tee /sys/class/gpio/export  # Ready LED
echo 4  | sudo tee /sys/class/gpio/export  # Status LED
echo 17 | sudo tee /sys/class/gpio/export  # Error LED

# Set as outputs
echo out | sudo tee /sys/class/gpio/gpio27/direction
echo out | sudo tee /sys/class/gpio/gpio4/direction
echo out | sudo tee /sys/class/gpio/gpio17/direction

# Test LEDs (should light up)
echo 1 | sudo tee /sys/class/gpio/gpio27/value  # Ready LED ON
sleep 1
echo 1 | sudo tee /sys/class/gpio/gpio4/value   # Status LED ON
sleep 1
echo 1 | sudo tee /sys/class/gpio/gpio17/value  # Error LED ON
sleep 1

# Turn all LEDs OFF
echo 0 | sudo tee /sys/class/gpio/gpio27/value
echo 0 | sudo tee /sys/class/gpio/gpio4/value
echo 0 | sudo tee /sys/class/gpio/gpio17/value

# Clean up
echo 27 | sudo tee /sys/class/gpio/unexport
echo 4  | sudo tee /sys/class/gpio/unexport
echo 17 | sudo tee /sys/class/gpio/unexport
```

### 4. Button Test
```bash
# Test button functionality
echo 2 | sudo tee /sys/class/gpio/export   # Read button
echo 3 | sudo tee /sys/class/gpio/export   # Write button

# Set as inputs with pull-up
echo in | sudo tee /sys/class/gpio/gpio2/direction
echo in | sudo tee /sys/class/gpio/gpio3/direction

# Test buttons (should show 1 when released, 0 when pressed)
echo "Press and release the READ button..."
for i in {1..10}; do
    echo "GPIO2 (Read): $(cat /sys/class/gpio/gpio2/value)"
    sleep 1
done

echo "Press and release the WRITE button..."
for i in {1..10}; do
    echo "GPIO3 (Write): $(cat /sys/class/gpio/gpio3/value)"
    sleep 1
done

# Clean up
echo 2 | sudo tee /sys/class/gpio/unexport
echo 3 | sudo tee /sys/class/gpio/unexport
```

### 5. RC522 Communication Test
```bash
# After connecting RC522, test with the application
sudo /opt/rfid-tool/rfid-tool -web -port=8080

# Check logs for successful initialization
sudo journalctl -u rfid-tool-web -n 20

# Look for messages like:
# "MFRC522 version: 0x92" or "RC522 initialized successfully"
```

## Troubleshooting Guide

### Common Issues and Solutions

#### 1. "MFRC522 not found" Error
**Symptoms**: Application reports RC522 not detected
**Solutions**:
```bash
# Verify SPI is enabled
ls /dev/spi*  # Should show spidev0.0

# Check wiring - most common issues:
# - Using 5V instead of 3.3V (fatal to RC522!)
# - Loose connections
# - Wrong GPIO pin assignments
# - SDA and SCK swapped

# Test SPI with oscilloscope or logic analyzer if available
```

#### 2. Permission Denied Errors
**Symptoms**: "Permission denied" accessing GPIO/SPI
**Solutions**:
```bash
# Check user groups
groups $USER

# Add to required groups
sudo usermod -a -G gpio,spi $USER

# Check file permissions
ls -la /dev/spidev0.0
ls -la /dev/gpiomem

# Reboot after group changes
sudo reboot
```

#### 3. Intermittent Card Detection
**Symptoms**: Cards detected sometimes, not always
**Solutions**:
- Reduce SPI speed in config.json (try 250kHz)
- Check antenna connections on RC522
- Ensure stable 3.3V power supply
- Try different card positions
- Check for interference from other devices

#### 4. LEDs Not Working
**Symptoms**: LEDs don't light up or behave incorrectly
**Solutions**:
```bash
# Check LED polarity (longer leg = anode/+)
# Verify 220Ω resistors are in series with anodes
# Test LED with multimeter in diode test mode
# Check GPIO pin assignments in config.json
```

#### 5. High CPU/Temperature on BCM2836
**Symptoms**: System running hot or slow
**Solutions**:
```bash
# Check CPU temperature
vcgencmd measure_temp

# Monitor CPU frequency
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq

# If temperature > 70°C, consider:
# - Adding heat sink
# - Improving case ventilation
# - Reducing SPI polling frequency
# - Using low-power configuration
```

## BCM2836 Performance Optimization

### SPI Speed Tuning for BCM2836
```json
{
  "rfid": {
    "spi_speed": 500000    // Conservative, reliable
    // "spi_speed": 1000000   // Higher performance
    // "spi_speed": 250000    // Ultra-conservative for noisy environments
  }
}
```

### Memory Management (1GB System)
- Web interface: ~45MB RAM typical usage
- Hardware interface: ~25MB RAM typical usage
- Leave 200-300MB free for system operations
- Monitor with `free -h` and `htop`

### Temperature Monitoring
```bash
# Create monitoring script
cat > /home/pi/temp_monitor.sh << 'EOF'
#!/bin/bash
while true; do
    TEMP=$(vcgencmd measure_temp | cut -d= -f2 | cut -d\' -f1)
    echo "$(date): CPU Temperature: ${TEMP}°C"
    if (( $(echo "$TEMP > 75" | bc -l) )); then
        echo "WARNING: High temperature detected!"
    fi
    sleep 60
done
EOF

chmod +x /home/pi/temp_monitor.sh
# Run: ./temp_monitor.sh
```

## Advanced Configuration

### Custom SPI Settings
```bash
# Add to /boot/config.txt for advanced SPI configuration
echo "dtparam=spi=on" | sudo tee -a /boot/config.txt
echo "dtoverlay=spi0-1cs" | sudo tee -a /boot/config.txt  # Single CS line
echo "core_freq=250" | sudo tee -a /boot/config.txt       # Stable core freq
```

### GPIO Drive Strength (if needed)
```bash
# Increase drive strength for long wires (2-16mA available)
echo "gpio=8,9,10,11=op,dh"  # High drive strength for SPI pins
```

### Real-time Priority (Hardware Mode)
```bash
# Enable real-time scheduling for hardware interface
sudo systemctl edit rfid-tool-hw

# Add:
# [Service]
# Nice=-10
# IOSchedulingClass=1
# IOSchedulingPriority=1
```

## Safety and Best Practices

### Electrical Safety
- **Always power off** before making connections
- **Never exceed 3.3V** on RC522 pins
- **Use proper current limiting** for LEDs (220Ω minimum)
- **Avoid short circuits** between power rails
- **Handle components carefully** (static sensitive)

### Mechanical Considerations
- **Secure connections** - use quality jumper wires
- **Strain relief** - avoid pulling on wires
- **Proper spacing** - prevent accidental shorts
- **Heat dissipation** - ensure adequate cooling
- **Vibration resistance** - secure breadboard in case

### Documentation
- **Label connections** with tape/markers
- **Take photos** of working configurations
- **Keep wiring diagrams** updated
- **Document any modifications**

## Final Checklist

Before powering up your system:

- [ ] **Power Supply**: 3.3V to RC522, NOT 5V
- [ ] **SPI Connections**: All 4 SPI pins connected correctly
- [ ] **Control Signals**: RST and optionally IRQ connected
- [ ] **Ground**: Common ground between RPi and RC522
- [ ] **SPI Enabled**: `dtparam=spi=on` in /boot/config.txt
- [ ] **User Groups**: pi user in gpio and spi groups
- [ ] **No Shorts**: Verified no short circuits
- [ ] **Secure Connections**: All wires firmly connected
- [ ] **LED Resistors**: 220Ω resistors in series with all LEDs
- [ ] **Button Pull-ups**: Using internal pull-ups (GPIO2/3)

Your Raspberry Pi 2B v1.1 RFID system should now be ready for operation!

---

**Hardware Target**: Raspberry Pi 2B v1.1 (BCM2836, ARM Cortex-A7)  
**Optimized for**: 1GB LPDDR2, 900MHz quad-core, 3.3V GPIO  
**Tested with**: Raspberry Pi OS Bullseye/Bookworm, Kernel 5.4+