package hardware

import (
	"fmt"
	"log"
	"time"

	"rfid-tool-rpi/internal/config"
	"rfid-tool-rpi/internal/rfid"

	"periph.io/x/conn/v3/gpio"
	"periph.io/x/conn/v3/gpio/gpioreg"
	"periph.io/x/host/v3"
)

// Controller represents the hardware controller
type Controller struct {
	reader      *rfid.Reader
	config      config.HardwareConfig
	readButton  gpio.PinIO
	writeButton gpio.PinIO
	statusLED   gpio.PinIO
	errorLED    gpio.PinIO
	readyLED    gpio.PinIO
	running     bool
	stopChan    chan struct{}
	cardData    []byte
}

// NewController creates a new hardware controller
func NewController(reader *rfid.Reader, cfg config.HardwareConfig) (*Controller, error) {
	// Initialize periph.io if not already done
	if _, err := host.Init(); err != nil {
		return nil, fmt.Errorf("failed to initialize periph.io: %w", err)
	}

	controller := &Controller{
		reader:   reader,
		config:   cfg,
		stopChan: make(chan struct{}),
	}

	// Initialize GPIO pins
	if err := controller.initGPIO(); err != nil {
		return nil, fmt.Errorf("failed to initialize GPIO: %w", err)
	}

	// Initialize LEDs (turn them off)
	controller.statusLED.Out(gpio.Low)
	controller.errorLED.Out(gpio.Low)
	controller.readyLED.Out(gpio.High) // Ready LED on by default

	return controller, nil
}

// initGPIO initializes all GPIO pins
func (c *Controller) initGPIO() error {
	var err error

	// Initialize read button
	c.readButton = gpioreg.ByName(fmt.Sprintf("GPIO%d", c.config.ReadButton))
	if c.readButton == nil {
		return fmt.Errorf("failed to get read button pin GPIO%d", c.config.ReadButton)
	}
	if err = c.readButton.In(gpio.PullUp, gpio.FallingEdge); err != nil {
		return fmt.Errorf("failed to configure read button: %w", err)
	}

	// Initialize write button
	c.writeButton = gpioreg.ByName(fmt.Sprintf("GPIO%d", c.config.WriteButton))
	if c.writeButton == nil {
		return fmt.Errorf("failed to get write button pin GPIO%d", c.config.WriteButton)
	}
	if err = c.writeButton.In(gpio.PullUp, gpio.FallingEdge); err != nil {
		return fmt.Errorf("failed to configure write button: %w", err)
	}

	// Initialize status LED
	c.statusLED = gpioreg.ByName(fmt.Sprintf("GPIO%d", c.config.StatusLED))
	if c.statusLED == nil {
		return fmt.Errorf("failed to get status LED pin GPIO%d", c.config.StatusLED)
	}
	if err = c.statusLED.Out(gpio.Low); err != nil {
		return fmt.Errorf("failed to configure status LED: %w", err)
	}

	// Initialize error LED
	c.errorLED = gpioreg.ByName(fmt.Sprintf("GPIO%d", c.config.ErrorLED))
	if c.errorLED == nil {
		return fmt.Errorf("failed to get error LED pin GPIO%d", c.config.ErrorLED)
	}
	if err = c.errorLED.Out(gpio.Low); err != nil {
		return fmt.Errorf("failed to configure error LED: %w", err)
	}

	// Initialize ready LED
	c.readyLED = gpioreg.ByName(fmt.Sprintf("GPIO%d", c.config.ReadyLED))
	if c.readyLED == nil {
		return fmt.Errorf("failed to get ready LED pin GPIO%d", c.config.ReadyLED)
	}
	if err = c.readyLED.Out(gpio.Low); err != nil {
		return fmt.Errorf("failed to configure ready LED: %w", err)
	}

	return nil
}

// Start starts the hardware controller
func (c *Controller) Start() {
	c.running = true
	c.readyLED.Out(gpio.High) // Show ready state

	log.Println("Hardware controller started")
	log.Println("Press the read button to scan and read card")
	log.Println("Press the write button to write stored data to card")

	// Main loop
	for c.running {
		select {
		case <-c.stopChan:
			c.running = false
			return

		default:
			// Check button presses
			c.checkButtons()
			time.Sleep(50 * time.Millisecond) // Small delay to prevent busy waiting
		}
	}
}

// Stop stops the hardware controller
func (c *Controller) Stop() {
	c.running = false
	close(c.stopChan)
}

// Close cleans up resources
func (c *Controller) Close() error {
	c.Stop()

	// Turn off all LEDs
	if c.statusLED != nil {
		c.statusLED.Out(gpio.Low)
	}
	if c.errorLED != nil {
		c.errorLED.Out(gpio.Low)
	}
	if c.readyLED != nil {
		c.readyLED.Out(gpio.Low)
	}

	return nil
}

// checkButtons checks for button presses and handles them
func (c *Controller) checkButtons() {
	// Check read button
	if c.readButton.Read() == gpio.Low {
		// Button pressed (active low with pull-up)
		c.handleReadButton()
		c.waitForButtonRelease(c.readButton)
	}

	// Check write button
	if c.writeButton.Read() == gpio.Low {
		// Button pressed (active low with pull-up)
		c.handleWriteButton()
		c.waitForButtonRelease(c.writeButton)
	}
}

// waitForButtonRelease waits for a button to be released
func (c *Controller) waitForButtonRelease(button gpio.PinIO) {
	for button.Read() == gpio.Low {
		time.Sleep(10 * time.Millisecond)
	}
	time.Sleep(50 * time.Millisecond) // Debounce delay
}

// handleReadButton handles read button press
func (c *Controller) handleReadButton() {
	log.Println("Read button pressed")

	c.setLEDState(false, false, false) // Turn off all LEDs
	c.statusLED.Out(gpio.High)         // Show scanning status

	// Scan for card
	card, err := c.reader.ScanForCard()
	if err != nil {
		log.Printf("Failed to scan card: %v", err)
		c.showError("Failed to scan card")
		return
	}

	log.Printf("Card detected: %s", card.String())

	// Read all data from card
	data, err := c.reader.ReadCard()
	if err != nil {
		log.Printf("Failed to read card data: %v", err)
		c.showError("Failed to read card")
		return
	}

	// Store the data from block 1 for writing (block 0 is usually read-only)
	if blockData, exists := data[1]; exists {
		c.cardData = blockData
		log.Printf("Stored data from block 1: %x", blockData)
	} else {
		// Use default data if block 1 doesn't exist or can't be read
		c.cardData = []byte{0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x20, 0x52, 0x46, 0x49, 0x44, 0x21, 0x00, 0x00, 0x00, 0x00, 0x00}
		log.Println("Using default data for writing")
	}

	// Show success
	c.showSuccess("Card read successfully")

	// Print readable data
	log.Println("Card data:")
	for block, blockData := range data {
		ascii := ""
		for _, b := range blockData {
			if b >= 32 && b <= 126 {
				ascii += string(b)
			} else {
				ascii += "."
			}
		}
		log.Printf("Block %2d: %x [%s]", block, blockData, ascii)
	}
}

// handleWriteButton handles write button press
func (c *Controller) handleWriteButton() {
	log.Println("Write button pressed")

	if c.cardData == nil {
		log.Println("No data to write. Please read a card first.")
		c.showError("No data to write")
		return
	}

	c.setLEDState(false, false, false) // Turn off all LEDs
	c.statusLED.Out(gpio.High)         // Show writing status

	// Scan for card
	card, err := c.reader.ScanForCard()
	if err != nil {
		log.Printf("Failed to scan card: %v", err)
		c.showError("Failed to scan card")
		return
	}

	log.Printf("Writing to card: %s", card.String())

	// Write data to block 1 (block 0 is usually read-only)
	if err := c.reader.WriteBlock(1, c.cardData); err != nil {
		log.Printf("Failed to write to card: %v", err)
		c.showError("Failed to write card")
		return
	}

	log.Printf("Successfully wrote data to block 1: %x", c.cardData)
	c.showSuccess("Card written successfully")

	// Verify the write by reading it back
	readData, err := c.reader.ReadBlock(1)
	if err != nil {
		log.Printf("Warning: Could not verify write: %v", err)
	} else {
		log.Printf("Verification read: %x", readData)
		// Compare data
		match := true
		if len(readData) == len(c.cardData) {
			for i := range readData {
				if readData[i] != c.cardData[i] {
					match = false
					break
				}
			}
		} else {
			match = false
		}

		if match {
			log.Println("Write verification successful")
		} else {
			log.Println("Write verification failed - data doesn't match")
		}
	}
}

// setLEDState sets the state of all LEDs
func (c *Controller) setLEDState(ready, status, error bool) {
	if ready {
		c.readyLED.Out(gpio.High)
	} else {
		c.readyLED.Out(gpio.Low)
	}

	if status {
		c.statusLED.Out(gpio.High)
	} else {
		c.statusLED.Out(gpio.Low)
	}

	if error {
		c.errorLED.Out(gpio.High)
	} else {
		c.errorLED.Out(gpio.Low)
	}
}

// showError shows an error indication
func (c *Controller) showError(message string) {
	log.Printf("Error: %s", message)
	c.setLEDState(false, false, true) // Only error LED on

	// Blink error LED for emphasis
	go func() {
		for i := 0; i < 6; i++ {
			c.errorLED.Out(gpio.Low)
			time.Sleep(200 * time.Millisecond)
			c.errorLED.Out(gpio.High)
			time.Sleep(200 * time.Millisecond)
		}
		c.setLEDState(true, false, false) // Back to ready state
	}()
}

// showSuccess shows a success indication
func (c *Controller) showSuccess(message string) {
	log.Printf("Success: %s", message)
	c.setLEDState(false, true, false) // Only status LED on

	// Keep status LED on for 2 seconds, then back to ready
	go func() {
		time.Sleep(2 * time.Second)
		c.setLEDState(true, false, false) // Back to ready state
	}()
}

// GetStoredData returns the currently stored card data
func (c *Controller) GetStoredData() []byte {
	return c.cardData
}

// SetStoredData sets the data to be written to cards
func (c *Controller) SetStoredData(data []byte) error {
	if len(data) != 16 {
		return fmt.Errorf("data must be exactly 16 bytes")
	}
	c.cardData = make([]byte, 16)
	copy(c.cardData, data)
	log.Printf("Stored new data for writing: %x", c.cardData)
	return nil
}
