---
name: Hardware Support
about: Request support for new hardware or report hardware compatibility issues
title: '[HARDWARE] '
labels: ['hardware', 'needs-triage']
assignees: ''

---

## Hardware Information
**What hardware are you trying to use or having issues with?**
- Device/Component: [e.g., RFID-RC522, PN532, different Pi model]
- Manufacturer/Brand: [e.g., HiLetgo, Elechouse, official]
- Model/Part Number: [if available]
- Purchase Link: [if available, helps with identification]

## Request Type
- [ ] New hardware support request
- [ ] Existing hardware compatibility issue
- [ ] Wiring/connection problem
- [ ] Performance issue with supported hardware

## Current Setup
**Raspberry Pi:**
- Model: [e.g., Pi 2B, Pi 3B+, Pi 4, Pi Zero W]
- RAM: [e.g., 1GB, 2GB, 4GB, 8GB]
- OS Version: [e.g., Raspberry Pi OS Bullseye, Ubuntu 22.04]

**RFID Module:**
- Current Module: [e.g., RC522, PN532, other]
- Interface: [e.g., SPI, I2C, UART]
- Voltage: [e.g., 3.3V, 5V]

**Additional Components:**
- Buttons: [quantity and type]
- LEDs: [quantity and colors]
- Resistors: [values used]
- Other: [any other components]

## What Works / What Doesn't Work
**Currently Working:**
- [ ] Basic card detection
- [ ] Card reading
- [ ] Card writing  
- [ ] Web interface
- [ ] Hardware interface (buttons/LEDs)
- [ ] Specific card types: _______________

**Not Working:**
- [ ] No card detection
- [ ] Cannot read cards
- [ ] Cannot write cards
- [ ] Interface issues
- [ ] Specific card types: _______________
- [ ] Other: _______________

## Error Messages
```
Please paste any error messages from:
sudo journalctl -u rfid-tool-web -n 50
or
sudo journalctl -u rfid-tool-hw -n 50
```

## Wiring Configuration
**Current Wiring:**
```
RFID Module Pin -> Raspberry Pi Pin
VCC -> Pin __ (Voltage: ___)
GND -> Pin __ 
SDA/SS -> Pin __
SCK -> Pin __
MOSI -> Pin __
MISO -> Pin __
IRQ -> Pin __
RST -> Pin __
```

**Buttons/LEDs (if applicable):**
```
Component -> GPIO Pin -> Additional Info
Button 1 -> GPIO__ -> Pull-up/down: ___
Button 2 -> GPIO__ -> Pull-up/down: ___
LED 1 -> GPIO__ -> Color: ___, Resistor: ___Ω
LED 2 -> GPIO__ -> Color: ___, Resistor: ___Ω
LED 3 -> GPIO__ -> Color: ___, Resistor: ___Ω
```

## Hardware Photos
If possible, please include photos of:
- [ ] Complete setup overview
- [ ] Close-up of RFID module
- [ ] Breadboard connections
- [ ] Wiring connections to Raspberry Pi

## Configuration File
Current `/opt/rfid-tool/config.json` (remove sensitive data):
```json
{
  "rfid": {
    "spi_bus": 0,
    "spi_device": 0,
    "reset_pin": 22,
    "irq_pin": 18,
    "spi_speed": 1000000
  },
  "hardware": {
    "read_button": 2,
    "write_button": 3,
    "status_led": 4,
    "error_led": 17,
    "ready_led": 27
  }
}
```

## Testing Done
- [ ] Verified power supply voltage with multimeter
- [ ] Checked continuity of all connections
- [ ] Tested with multiple RFID cards
- [ ] Tried different SPI speeds
- [ ] Tested on different GPIO pins
- [ ] Verified SPI interface is enabled
- [ ] Checked `/dev/spidev*` exists
- [ ] Tested with minimal wiring (RFID only)

## Expected Outcome
What would you like to see happen?
- [ ] Add support for this new hardware
- [ ] Fix compatibility with existing hardware
- [ ] Provide wiring guide for this setup
- [ ] Update documentation
- [ ] Other: _______________

## Additional Context
Any other information that might help:
- Similar hardware that works
- Specific use case requirements
- Performance requirements
- Budget constraints
- Timeline needs

## Research Done
- [ ] Checked existing documentation
- [ ] Searched existing issues
- [ ] Looked for similar hardware support
- [ ] Checked manufacturer datasheets
- [ ] Tested with other software/libraries

## Willingness to Test
- [ ] I can test proposed solutions
- [ ] I can provide additional hardware information
- [ ] I can help with documentation
- [ ] I have hardware available for long-term testing