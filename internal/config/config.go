package config

import (
	"encoding/json"
	"os"
	"runtime"
)

// Config holds the application configuration
type Config struct {
	RFID          RFIDConfig          `json:"rfid"`
	Hardware      HardwareConfig      `json:"hardware"`
	Web           WebConfig           `json:"web"`
	System        SystemConfig        `json:"system"`
	Performance   PerformanceConfig   `json:"performance"`
	Compatibility CompatibilityConfig `json:"compatibility"`
}

// RFIDConfig holds RFID-specific configuration optimized for RPi 2B v1.1
type RFIDConfig struct {
	SPIBus     int `json:"spi_bus"`     // SPI bus number (0 for BCM2836)
	SPIDevice  int `json:"spi_device"`  // SPI device number (0 for CE0)
	ResetPin   int `json:"reset_pin"`   // GPIO pin for reset (22 recommended for RPi 2B)
	IRQPin     int `json:"irq_pin"`     // GPIO pin for IRQ (18/24 recommended)
	SPISpeed   int `json:"spi_speed"`   // SPI speed in Hz (500kHz conservative for BCM2836)
	RetryCount int `json:"retry_count"` // Number of retries for operations
}

// HardwareConfig holds hardware interface configuration for RPi 2B v1.1
type HardwareConfig struct {
	ReadButton  int `json:"read_button"`  // GPIO pin for read button (I2C pins work well)
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

// SystemConfig holds RPi 2B v1.1 specific system configuration
type SystemConfig struct {
	TargetBoard       string `json:"target_board"`            // Target board identifier
	SoC               string `json:"soc"`                     // System on Chip identifier
	Architecture      string `json:"architecture"`            // CPU architecture
	CPU               string `json:"cpu"`                     // CPU type
	MaxMemoryMB       int    `json:"max_memory_mb"`           // Maximum available memory in MB
	GPIODriver        string `json:"gpio_driver"`             // GPIO driver name
	SPIMaxSpeed       int    `json:"spi_max_speed"`           // Maximum SPI speed supported
	OptimizedCortexA7 bool   `json:"optimized_for_cortex_a7"` // Enable Cortex-A7 optimizations
}

// PerformanceConfig holds performance tuning parameters for RPi 2B v1.1
type PerformanceConfig struct {
	PollingIntervalMs  int `json:"polling_interval_ms"`  // RFID polling interval in ms
	DebounceDelayMs    int `json:"debounce_delay_ms"`    // Button debounce delay in ms
	LEDFadeTimeMs      int `json:"led_fade_time_ms"`     // LED fade transition time
	OperationTimeoutMs int `json:"operation_timeout_ms"` // Operation timeout in ms
	WebRefreshRateMs   int `json:"web_refresh_rate_ms"`  // Web interface refresh rate
}

// CompatibilityConfig holds compatibility information
type CompatibilityConfig struct {
	RaspberryPiModels     []string `json:"raspberry_pi_models"`     // Supported Pi models
	BCMSoCVersions        []string `json:"bcm_soc_versions"`        // Supported BCM SoC versions
	TestedKernelVersions  []string `json:"tested_kernel_versions"`  // Tested kernel versions
	RequiredKernelModules []string `json:"required_kernel_modules"` // Required kernel modules
}

// Default returns a default configuration optimized for Raspberry Pi 2B v1.1
func Default() *Config {
	return &Config{
		RFID: RFIDConfig{
			SPIBus:     0,      // SPI0 on BCM2836
			SPIDevice:  0,      // CE0 (GPIO8)
			ResetPin:   22,     // GPIO22 - good for reset signal
			IRQPin:     18,     // GPIO24 - interrupt pin (optional)
			SPISpeed:   500000, // 500kHz - conservative for reliable operation
			RetryCount: 3,      // 3 retries for operations
		},
		Hardware: HardwareConfig{
			ReadButton:  2,  // GPIO2 (I2C1_SDA) - has internal pull-up
			WriteButton: 3,  // GPIO3 (I2C1_SCL) - has internal pull-up
			StatusLED:   4,  // GPIO4 - general purpose
			ErrorLED:    17, // GPIO17 - general purpose
			ReadyLED:    27, // GPIO27 - general purpose
		},
		Web: WebConfig{
			StaticDir:    "web/static",
			TemplatesDir: "web/templates",
			UploadDir:    "uploads",
		},
		System: SystemConfig{
			TargetBoard:       "rpi2b_v1.1",
			SoC:               "bcm2836",
			Architecture:      "armv7",
			CPU:               "cortex_a7",
			MaxMemoryMB:       1024,      // 1GB total memory
			GPIODriver:        "bcm2835", // GPIO driver for BCM283x series
			SPIMaxSpeed:       32000000,  // 32MHz max SPI speed on BCM2836
			OptimizedCortexA7: true,      // Enable Cortex-A7 specific optimizations
		},
		Performance: PerformanceConfig{
			PollingIntervalMs:  100,  // 10Hz RFID polling - good balance
			DebounceDelayMs:    50,   // 50ms button debounce
			LEDFadeTimeMs:      250,  // 250ms LED transitions
			OperationTimeoutMs: 5000, // 5 second operation timeout
			WebRefreshRateMs:   1000, // 1Hz web refresh rate
		},
		Compatibility: CompatibilityConfig{
			RaspberryPiModels: []string{
				"2B_v1.1", // Primary target
				"2B",      // Also compatible
				"3B",      // Forward compatible
				"3B+",     // Forward compatible
				"4B",      // Forward compatible
			},
			BCMSoCVersions: []string{
				"BCM2836", // Primary target (RPi 2B v1.1)
				"BCM2837", // RPi 3B/3B+ (compatible)
				"BCM2711", // RPi 4B (compatible)
			},
			TestedKernelVersions: []string{
				"5.4+",  // Raspberry Pi OS Buster
				"5.10+", // Raspberry Pi OS Bullseye
				"5.15+", // Raspberry Pi OS Bullseye (later)
				"6.1+",  // Raspberry Pi OS Bookworm
			},
			RequiredKernelModules: []string{
				"spi_bcm2835",  // SPI driver for BCM283x
				"gpio_bcm2835", // GPIO driver for BCM283x
			},
		},
	}
}

// DefaultForRPi2B returns configuration specifically optimized for RPi 2B v1.1
func DefaultForRPi2B() *Config {
	config := Default()

	// RPi 2B v1.1 specific optimizations
	config.RFID.SPISpeed = 500000              // Conservative speed for BCM2836
	config.Performance.PollingIntervalMs = 100 // Balanced for 900MHz quad-core

	return config
}

// DefaultHighPerformance returns a high-performance configuration for RPi 2B v1.1
func DefaultHighPerformance() *Config {
	config := Default()

	// High-performance settings
	config.RFID.SPISpeed = 2000000            // 2MHz - higher speed for better performance
	config.Performance.PollingIntervalMs = 50 // 20Hz polling - more responsive
	config.Performance.DebounceDelayMs = 25   // Faster button response
	config.Performance.LEDFadeTimeMs = 150    // Faster LED transitions
	config.Performance.WebRefreshRateMs = 500 // 2Hz web refresh

	return config
}

// DefaultLowPower returns a low-power configuration for RPi 2B v1.1
func DefaultLowPower() *Config {
	config := Default()

	// Low-power settings
	config.RFID.SPISpeed = 250000              // Slower speed for lower power
	config.Performance.PollingIntervalMs = 200 // 5Hz polling - less CPU usage
	config.Performance.DebounceDelayMs = 100   // Longer debounce
	config.Performance.LEDFadeTimeMs = 500     // Slower LED transitions
	config.Performance.WebRefreshRateMs = 2000 // 0.5Hz web refresh

	return config
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

	// Validate configuration for RPi 2B v1.1
	config.validateAndAdjust()

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

// validateAndAdjust validates and adjusts configuration values for RPi 2B v1.1
func (c *Config) validateAndAdjust() {
	// Validate SPI speed limits for BCM2836
	if c.RFID.SPISpeed > c.System.SPIMaxSpeed {
		c.RFID.SPISpeed = c.System.SPIMaxSpeed
	}
	if c.RFID.SPISpeed < 100000 { // Minimum 100kHz
		c.RFID.SPISpeed = 100000
	}

	// Validate GPIO pin ranges (BCM2835/2836 has GPIO 0-53)
	gpioMax := 53
	if c.Hardware.ReadButton > gpioMax || c.Hardware.ReadButton < 0 {
		c.Hardware.ReadButton = 2 // Default safe value
	}
	if c.Hardware.WriteButton > gpioMax || c.Hardware.WriteButton < 0 {
		c.Hardware.WriteButton = 3 // Default safe value
	}
	if c.Hardware.StatusLED > gpioMax || c.Hardware.StatusLED < 0 {
		c.Hardware.StatusLED = 4 // Default safe value
	}
	if c.Hardware.ErrorLED > gpioMax || c.Hardware.ErrorLED < 0 {
		c.Hardware.ErrorLED = 17 // Default safe value
	}
	if c.Hardware.ReadyLED > gpioMax || c.Hardware.ReadyLED < 0 {
		c.Hardware.ReadyLED = 27 // Default safe value
	}

	// Validate performance parameters
	if c.Performance.PollingIntervalMs < 10 {
		c.Performance.PollingIntervalMs = 10 // Minimum 10ms (100Hz max)
	}
	if c.Performance.PollingIntervalMs > 5000 {
		c.Performance.PollingIntervalMs = 5000 // Maximum 5s
	}

	if c.Performance.DebounceDelayMs < 5 {
		c.Performance.DebounceDelayMs = 5 // Minimum 5ms
	}
	if c.Performance.DebounceDelayMs > 1000 {
		c.Performance.DebounceDelayMs = 1000 // Maximum 1s
	}
}

// GetOptimizedSPISpeed returns the optimal SPI speed based on system capabilities
func (c *Config) GetOptimizedSPISpeed() int {
	// Determine optimal SPI speed based on architecture
	if runtime.GOARCH == "arm" && c.System.OptimizedCortexA7 {
		// For RPi 2B v1.1 with Cortex-A7
		if c.RFID.SPISpeed <= 500000 {
			return c.RFID.SPISpeed // Use configured conservative speed
		} else if c.RFID.SPISpeed <= 2000000 {
			return c.RFID.SPISpeed // Use configured performance speed
		} else {
			return 2000000 // Cap at 2MHz for reliability
		}
	}

	// Default fallback
	return c.RFID.SPISpeed
}

// IsCompatibleBoard checks if the current configuration is compatible with the detected board
func (c *Config) IsCompatibleBoard(detectedModel string) bool {
	for _, model := range c.Compatibility.RaspberryPiModels {
		if model == detectedModel {
			return true
		}
	}
	return false
}

// GetMemoryConstrainedSettings returns settings appropriate for the available memory
func (c *Config) GetMemoryConstrainedSettings(availableMemoryMB int) *Config {
	adjustedConfig := *c

	// Adjust settings based on available memory
	if availableMemoryMB < 512 {
		// Very low memory - use conservative settings
		adjustedConfig.Performance.PollingIntervalMs = 200
		adjustedConfig.Performance.WebRefreshRateMs = 2000
	} else if availableMemoryMB < 800 {
		// Low memory - moderate settings
		adjustedConfig.Performance.PollingIntervalMs = 150
		adjustedConfig.Performance.WebRefreshRateMs = 1500
	}
	// For 1GB (normal RPi 2B v1.1), use default settings

	return &adjustedConfig
}

// GetDescription returns a human-readable description of the configuration
func (c *Config) GetDescription() string {
	return "RFID Tool configuration optimized for Raspberry Pi 2B v1.1 (BCM2836, ARM Cortex-A7)"
}

// GetSystemInfo returns system-specific information
func (c *Config) GetSystemInfo() map[string]interface{} {
	return map[string]interface{}{
		"target_board":  c.System.TargetBoard,
		"soc":           c.System.SoC,
		"architecture":  c.System.Architecture,
		"cpu":           c.System.CPU,
		"max_memory_mb": c.System.MaxMemoryMB,
		"gpio_driver":   c.System.GPIODriver,
		"spi_max_speed": c.System.SPIMaxSpeed,
		"optimized":     c.System.OptimizedCortexA7,
		"go_arch":       runtime.GOARCH,
		"go_os":         runtime.GOOS,
	}
}
