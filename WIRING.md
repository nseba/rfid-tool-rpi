# RFID-RC522 Wiring Guide for Raspberry Pi 2B

## Overview
This guide provides detailed instructions for connecting the RFID-RC522 module to a Raspberry Pi 2B using a breadboard. The setup supports both web interface and hardware button/LED interface modes.

## Required Components

### Essential Components
- **Raspberry Pi 2B** (or newer)
- **RFID-RC522 Module**
- **Breadboard** (830-point recommended)
- **Jumper Wires**:
  - 8x Male-to-Female (RPi to breadboard)
  - 10+ Male-to-Male (breadboard connections)

### For Hardware Interface (Optional)
- **2x Push Buttons** (momentary, normally open)
- **3x LEDs**:
  - 1x Green LED (Ready indicator)
  - 1x Blue/White LED (Status indicator)
  - 1x Red LED (Error indicator)
- **3x 220Ω Resistors** (for LED current limiting)
- **2x 10kΩ Resistors** (optional, for external pull-ups)

## Pin Layout Reference

### Raspberry Pi 2B GPIO Pinout
```
     3V3  (1) (2)  5V
   GPIO2  (3) (4)  5V
   GPIO3  (5) (6)  GND
   GPIO4  (7) (8)  GPIO14
     GND  (9) (10) GPIO15
  GPIO17 (11) (12) GPIO18
  GPIO27 (13) (14) GND
  GPIO22 (15) (16) GPIO23
     3V3 (17) (18) GPIO24
  GPIO10 (19) (20) GND
   GPIO9 (21) (22) GPIO25
  GPIO11 (23) (24) GPIO8
     GND (25) (26) GPIO7
```

### RFID-RC522 Module Pinout
```
┌─────────────┐
│ RC522 Module│
├─────────────┤
│ SDA  ●  ● ? │
│ SCK  ●  ● ? │
│ MOSI ●  ● ? │
│ MISO ●  ● ? │
│ IRQ  ●  ● ? │
│ GND  ●  ● ? │
│ RST  ●  ● ? │
│ 3.3V ●  ● ? │
└─────────────┘
```

## Connection Tables

### RFID-RC522 to Raspberry Pi Connections
| RC522 Pin | Function | RPi Pin | RPi GPIO | Wire Color | Notes |
|-----------|----------|---------|----------|------------|--------|
| SDA       | SPI CS   | 24      | GPIO8    | Orange     | SPI Chip Select |
| SCK       | SPI CLK  | 23      | GPIO11   | Yellow     | SPI Clock |
| MOSI      | SPI MOSI | 19      | GPIO10   | Blue       | Master Out Slave In |
| MISO      | SPI MISO | 21      | GPIO9    | Green      | Master In Slave Out |
| IRQ       | Interrupt| 18      | GPIO24   | Purple     | Optional interrupt pin |
| GND       | Ground   | 20      | GND      | Black      | Common ground |
| RST       | Reset    | 15      | GPIO22   | White      | Reset signal |
| 3.3V      | Power    | 17      | 3.3V     | Red        | **IMPORTANT: 3.3V only!** |

### Hardware Interface Connections (Optional)
| Component      | RPi Pin | RPi GPIO | Resistor | Wire Color | Notes |
|----------------|---------|----------|----------|------------|--------|
| Read Button    | 3       | GPIO2    | 10kΩ*    | Gray       | Pull-up to 3.3V |
| Write Button   | 5       | GPIO3    | 10kΩ*    | Brown      | Pull-up to 3.3V |
| Ready LED (+)  | 13      | GPIO27   | 220Ω     | Green      | Current limiting |
| Status LED (+) | 7       | GPIO4    | 220Ω     | Blue       | Current limiting |
| Error LED (+)  | 11      | GPIO17   | 220Ω     | Red        | Current limiting |
| All LEDs (-)   | 20      | GND      | -        | Black      | Common cathode |
| Button Commons | 20      | GND      | -        | Black      | Button other terminal |

*Software pull-ups are used by default; external resistors are optional.

## Breadboard Layout Diagram

```
                Raspberry Pi 2B
              ┌─────────────────┐
              │  ●●●●●●●●●●●●●●●●●●●● │ 
              │  ●●●●●●●●●●●●●●●●●●●● │
              └─────────────────┘
                     │ │ │ │ │ │ │ │
    ┌────────────────┘ │ │ │ │ │ │ └── 3.3V (Pin 17)
    │  ┌───────────────┘ │ │ │ │ └──── GPIO22/RST (Pin 15)
    │  │  ┌──────────────┘ │ │ └────── GPIO24/IRQ (Pin 18)  
    │  │  │  ┌─────────────┘ └──────── GND (Pin 20)
    │  │  │  │  ┌────────────────────── GPIO11/SCK (Pin 23)
    │  │  │  │  │  ┌───────────────────── GPIO8/SDA (Pin 24)
    │  │  │  │  │  │  ┌──────────────────── GPIO10/MOSI (Pin 19)
    │  │  │  │  │  │  │  ┌─────────────────── GPIO9/MISO (Pin 21)
    │  │  │  │  │  │  │  │
    v  v  v  v  v  v  v  v

Breadboard Top Section (RFID Module):
  + Rail  a b c d e    f g h i j  - Rail
     │    1 2 3 4 5    6 7 8 9 10    │
  ●──┴────┬─┬─┬─┬─┬────┬─┬─┬─┬─┬────┴──●  ← 3.3V Rail
     │    │ │ │ │ │    │ │ │ │ │       │
  20 │    ● ● ● ● ●    ● ● ● ● ●       │
  21 │    │ │ │ │ │    │ │ │ │ │       │
  22 │    │ │ │ │ │    RC522 Module    │
  23 │    │ │ │ │ │    SDA SCK MOSI    │
  24 │    │ │ │ │ │    MISO IRQ GND    │
  25 │    │ │ │ │ │    RST  3V3        │
  26 │    │ │ │ │ │    │ │ │ │ │       │
  27 │    ● ● ● ● ●    ● ● ● ● ●       │
  28 │      │ │ │ │      │ │ │         │
  29 │      │ │ │ │      │ │ │         │
  30 │      │ │ │ └──────┘ │ └─────────┴──●  ← GND Rail
     │      │ │ └──────────┘
     │      │ └─────────── To RPi GPIO pins
     │      └───────────── (see connection table)
     │

Breadboard Bottom Section (Hardware Interface):
  35 │    ● ● ● ● ●    ● ● ● ● ●       │
  36 │    │ │ │   │    │ │ │           │
  37 │   [B1] │  LED1 LED2 LED3       │  ← Buttons & LEDs
  38 │    │ │ │  220Ω 220Ω 220Ω       │
  39 │    │ │ │   │    │   │           │
  40 │    ● ● ●   ●    ●   ●           │
  41 │    │ │     │    │   │           │
  42 │    │ │     └────┴───┴───────────┴──●  ← GND Rail
  43 │    │ └── To RPi GPIO2 (Read Button)
  44 │    └──── To RPi GPIO3 (Write Button)
     │
  + Rail = 3.3V    - Rail = GND
```

## Step-by-Step Wiring Instructions

### Step 1: Prepare the Breadboard
1. **Connect Power Rails**:
   - Red wire: RPi Pin 17 (3.3V) → Breadboard + rail
   - Black wire: RPi Pin 20 (GND) → Breadboard - rail
   
2. **Verify Power**:
   - Use multimeter to confirm 3.3V between rails
   - ⚠️ **NEVER connect 5V to RC522 - it will damage the module!**

### Step 2: Install RFID-RC522 Module
1. **Mount Module** on breadboard (rows 22-27 recommended)
2. **Connect Power**:
   - 3.3V pin → + rail (red wire)
   - GND pin → - rail (black wire)
3. **Connect SPI Interface**:
   - SDA → GPIO8 (Pin 24) - Orange wire
   - SCK → GPIO11 (Pin 23) - Yellow wire  
   - MOSI → GPIO10 (Pin 19) - Blue wire
   - MISO → GPIO9 (Pin 21) - Green wire
4. **Connect Control Pins**:
   - RST → GPIO22 (Pin 15) - White wire
   - IRQ → GPIO24 (Pin 18) - Purple wire (optional)

### Step 3: Install Hardware Interface (Optional)

#### Buttons:
1. **Read Button**:
   - One terminal → GPIO2 (Pin 3) - Gray wire
   - Other terminal → GND rail - Black wire
   
2. **Write Button**:
   - One terminal → GPIO3 (Pin 5) - Brown wire
   - Other terminal → GND rail - Black wire

#### LEDs (with current limiting resistors):
1. **Ready LED (Green)**:
   - Anode (+, longer leg) → 220Ω resistor → GPIO27 (Pin 13)
   - Cathode (-, shorter leg) → GND rail
   
2. **Status LED (Blue/White)**:
   - Anode (+) → 220Ω resistor → GPIO4 (Pin 7)
   - Cathode (-) → GND rail
   
3. **Error LED (Red)**:
   - Anode (+) → 220Ω resistor → GPIO17 (Pin 11)
   - Cathode (-) → GND rail

### Step 4: Double-Check Connections
Use the following checklist:

- [ ] 3.3V rail connected to RPi Pin 17
- [ ] GND rail connected to RPi Pin 20  
- [ ] RC522 3.3V connected to + rail
- [ ] RC522 GND connected to - rail
- [ ] All 6 SPI/control wires connected correctly
- [ ] All LEDs have current limiting resistors
- [ ] Button connections verified
- [ ] No loose connections
- [ ] No short circuits between + and - rails

## Testing Your Wiring

### 1. Basic Power Test
```bash
# Check SPI interface is available
ls -la /dev/spi*
# Should show: /dev/spidev0.0

# Test GPIO access
sudo gpio readall  # If gpio utility is installed
```

### 2. LED Test (Hardware Mode)
```bash
# Test LEDs manually (GPIO pin numbers)
echo 27 | sudo tee /sys/class/gpio/export
echo out | sudo tee /sys/class/gpio/gpio27/direction
echo 1 | sudo tee /sys/class/gpio/gpio27/value    # LED on
echo 0 | sudo tee /sys/class/gpio/gpio27/value    # LED off
```

### 3. Button Test
```bash
# Test button reading (GPIO pin numbers)
echo 2 | sudo tee /sys/class/gpio/export
echo in | sudo tee /sys/class/gpio/gpio2/direction
cat /sys/class/gpio/gpio2/value  # Should show 1 (released) or 0 (pressed)
```

### 4. RFID Module Test
```bash
# Run the application to test RFID
sudo ./rfid-tool -web -port=8080
# Check logs for "MFRC522 version: 0x92" or similar
```

## Common Wiring Issues

### Problem: "MFRC522 not found"
- **Check**: 3.3V power connection (NOT 5V!)
- **Check**: All SPI connections (SDA, SCK, MOSI, MISO)
- **Check**: Reset pin connection
- **Verify**: SPI is enabled in raspi-config

### Problem: "Permission denied" accessing GPIO
- **Check**: User is in gpio group: `groups pi`
- **Run**: `sudo usermod -a -G gpio,spi pi`
- **Reboot** after adding to groups

### Problem: LEDs not working
- **Check**: 220Ω resistors are in series with LED anodes
- **Check**: LED polarity (longer leg = anode/+)
- **Check**: Connection to correct GPIO pins
- **Test**: Manual GPIO control (see testing section above)

### Problem: Buttons not responsive
- **Check**: One terminal to GPIO, other to GND
- **Check**: No external pull-up conflicts
- **Verify**: Button is normally-open type
- **Test**: Manual GPIO reading (see testing section above)

## Breadboard Layout Tips

1. **Organization**: Keep power connections on one side, signal connections on the other
2. **Color Coding**: Use consistent colors (red=power, black=ground, etc.)
3. **Short Wires**: Use shortest practical wire lengths to reduce interference
4. **Secure Connections**: Ensure all connections are fully inserted
5. **Documentation**: Take a photo of your final wiring for reference

## Safety Notes

- **Never exceed 3.3V** on RC522 module pins
- **Always disconnect power** before making wiring changes
- **Use appropriate current limiting resistors** for LEDs
- **Avoid short circuits** between power rails
- **Handle components carefully** - static electricity can damage them

## Troubleshooting Checklist

Before asking for help, verify:

- [ ] SPI enabled: `sudo raspi-config`
- [ ] Correct voltage: 3.3V (measured with multimeter)
- [ ] All connections match the tables above
- [ ] No loose or intermittent connections
- [ ] LEDs have current limiting resistors
- [ ] No short circuits
- [ ] Software installed and configured correctly
- [ ] Logs checked for specific error messages

## Alternative Layouts

### Compact Layout (RC522 only)
If you only need the RFID functionality without buttons/LEDs, you can use a smaller breadboard or even direct connections:

```
RPi Pin → RC522 Pin (Direct Connection)
17 (3.3V) → 3.3V
20 (GND)  → GND
15 (GPIO22) → RST
18 (GPIO24) → IRQ
19 (GPIO10) → MOSI
21 (GPIO9)  → MISO
23 (GPIO11) → SCK
24 (GPIO8)  → SDA
```

### Full Feature Layout
For the complete experience with both interfaces, use the full breadboard layout shown in the main diagram above.

This wiring guide should provide everything you need to successfully connect your RFID-RC522 module to your Raspberry Pi 2B. Take your time with the connections and double-check everything before powering up!