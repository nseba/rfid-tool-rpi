package config

import (
	"encoding/json"
	"os"
)

// Config holds the application configuration
type Config struct {
	RFID     RFIDConfig     `json:"rfid"`
	Hardware HardwareConfig `json:"hardware"`
	Web      WebConfig      `json:"web"`
}

// RFIDConfig holds RFID-specific configuration
type RFIDConfig struct {
	SPIBus     int `json:"spi_bus"`     // SPI bus number (usually 0)
	SPIDevice  int `json:"spi_device"`  // SPI device number (usually 0)
	ResetPin   int `json:"reset_pin"`   // GPIO pin for reset (usually 22)
	IRQPin     int `json:"irq_pin"`     // GPIO pin for IRQ (optional, usually 18)
	SPISpeed   int `json:"spi_speed"`   // SPI speed in Hz
	RetryCount int `json:"retry_count"` // Number of retries for operations
}

// HardwareConfig holds hardware interface configuration
type HardwareConfig struct {
	ReadButton  int `json:"read_button"`  // GPIO pin for read button
	WriteButton int `json:"write_button"` // GPIO pin for write button
	StatusLED   int `json:"status_led"`   // GPIO pin for status LED
	ErrorLED    int `json:"error_led"`    // GPIO pin for error LED
	ReadyLED    int `json:"ready_led"`    // GPIO pin for ready LED
}

// WebConfig holds web server configuration
type WebConfig struct {
	StaticDir    string `json:"static_dir"`
	TemplatesDir string `json:"templates_dir"`
	UploadDir    string `json:"upload_dir"`
}

// Default returns a default configuration
func Default() *Config {
	return &Config{
		RFID: RFIDConfig{
			SPIBus:     0,
			SPIDevice:  0,
			ResetPin:   22,
			IRQPin:     18,
			SPISpeed:   1000000, // 1MHz
			RetryCount: 3,
		},
		Hardware: HardwareConfig{
			ReadButton:  2,  // GPIO2
			WriteButton: 3,  // GPIO3
			StatusLED:   4,  // GPIO4
			ErrorLED:    17, // GPIO17
			ReadyLED:    27, // GPIO27
		},
		Web: WebConfig{
			StaticDir:    "web/static",
			TemplatesDir: "web/templates",
			UploadDir:    "uploads",
		},
	}
}

// Load loads configuration from a JSON file
func Load(filename string) (*Config, error) {
	data, err := os.ReadFile(filename)
	if err != nil {
		return nil, err
	}

	var config Config
	if err := json.Unmarshal(data, &config); err != nil {
		return nil, err
	}

	return &config, nil
}

// Save saves the configuration to a JSON file
func (c *Config) Save(filename string) error {
	data, err := json.MarshalIndent(c, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(filename, data, 0644)
}
