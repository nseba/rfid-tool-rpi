---
name: Bug Report
about: Create a report to help us improve
title: '[BUG] '
labels: ['bug', 'needs-triage']
assignees: ''

---

## Bug Description
A clear and concise description of what the bug is.

## Environment
**Hardware:**
- Raspberry Pi model: [e.g., Pi 2B, Pi 3B+, Pi 4]
- RC522 module: [e.g., standard RC522, brand/model if known]
- Additional hardware: [e.g., buttons, LEDs, breadboard setup]

**Software:**
- RFID Tool version: [e.g., v1.0.0]
- Raspberry Pi OS version: [e.g., Bullseye, Bookworm]
- Interface mode: [Web interface / Hardware interface]

## Steps to Reproduce
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

## Expected Behavior
A clear and concise description of what you expected to happen.

## Actual Behavior
A clear and concise description of what actually happened.

## Screenshots/Logs
If applicable, add screenshots to help explain your problem.

**Service Logs:**
```bash
# Please include relevant logs from:
sudo journalctl -u rfid-tool-web -n 50
# or
sudo journalctl -u rfid-tool-hw -n 50
```

**Error Messages:**
```
Paste any error messages here
```

## Wiring Setup
- [ ] I have verified all connections match the wiring guide
- [ ] I am using 3.3V power (NOT 5V)
- [ ] SPI interface is enabled (`sudo raspi-config`)
- [ ] I can see `/dev/spidev0.0`

## Additional Context
Add any other context about the problem here.

## Troubleshooting Attempted
- [ ] Checked service status (`systemctl status rfid-tool-*`)
- [ ] Verified SPI is enabled
- [ ] Double-checked wiring connections
- [ ] Tested with different RFID cards
- [ ] Rebooted the Raspberry Pi
- [ ] Reviewed logs for error messages

## Configuration
If you modified the default configuration, please include relevant parts of `/opt/rfid-tool/config.json`:

```json
{
  "rfid": {
    "spi_bus": 0,
    "spi_device": 0,
    "reset_pin": 22
  }
}
```
