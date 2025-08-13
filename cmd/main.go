// Package main provides the entry point for the RFID Tool application.
// It supports both web interface mode and hardware button/LED mode for interacting with RFID cards.
package main

import (
	"flag"
	"log"
	"os"
	"os/signal"
	"syscall"

	"rfid-tool-rpi/internal/config"
	"rfid-tool-rpi/internal/hardware"
	"rfid-tool-rpi/internal/rfid"
	"rfid-tool-rpi/internal/server"
)

func main() {
	var (
		webMode    = flag.Bool("web", false, "Run in web interface mode")
		hwMode     = flag.Bool("hardware", false, "Run in hardware button/LED mode")
		port       = flag.String("port", "8080", "Web server port")
		configFile = flag.String("config", "config.json", "Configuration file path")
	)
	flag.Parse()

	// Load configuration
	cfg, err := config.Load(*configFile)
	if err != nil {
		log.Printf("Warning: Could not load config file, using defaults: %v", err)
		cfg = config.Default()
	}

	// Initialize RFID reader
	rfidReader, err := rfid.NewReader(cfg.RFID)
	if err != nil {
		log.Printf("Warning: Failed to initialize RFID reader: %v", err)
		log.Println("Web interface will start but RFID functionality will be unavailable")
		rfidReader = nil
	}
	defer func() {
		if rfidReader != nil {
			if err := rfidReader.Close(); err != nil {
				log.Printf("Failed to close RFID reader: %v", err)
			}
		}
	}()

	// Setup signal handling
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	if *webMode {
		log.Println("Starting in web interface mode...")
		if rfidReader == nil {
			log.Println("Note: RFID functionality will be limited due to hardware initialization failure")
		}
		webServer := server.NewWebServer(*port, rfidReader, cfg)

		go func() {
			if err := webServer.Start(); err != nil {
				log.Fatalf("Web server failed: %v", err)
			}
		}()

		<-sigChan
		log.Println("Shutting down web server...")
		if err := webServer.Stop(); err != nil {
			log.Printf("Failed to stop web server: %v", err)
		}
	} else if *hwMode {
		if rfidReader == nil {
			log.Fatalf("Cannot start hardware mode: RFID reader initialization failed")
		}
		log.Println("Starting in hardware mode...")
		hwController, err := hardware.NewController(rfidReader, cfg.Hardware)
		if err != nil {
			log.Printf("Failed to initialize hardware controller: %v", err)
			return
		}
		defer func() {
			if err := hwController.Close(); err != nil {
				log.Printf("Failed to close hardware controller: %v", err)
			}
		}()

		go hwController.Start()

		<-sigChan
		log.Println("Shutting down hardware controller...")
	} else {
		log.Println("Please specify either -web or -hardware mode")
		flag.Usage()
		return
	}

	log.Println("Application stopped")
}
