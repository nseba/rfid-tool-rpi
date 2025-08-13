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
		log.Fatalf("Failed to initialize RFID reader: %v", err)
	}
	defer rfidReader.Close()

	// Setup signal handling
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	if *webMode {
		log.Println("Starting in web interface mode...")
		webServer := server.NewWebServer(*port, rfidReader, cfg)

		go func() {
			if err := webServer.Start(); err != nil {
				log.Fatalf("Web server failed: %v", err)
			}
		}()

		<-sigChan
		log.Println("Shutting down web server...")
		webServer.Stop()

	} else if *hwMode {
		log.Println("Starting in hardware mode...")
		hwController, err := hardware.NewController(rfidReader, cfg.Hardware)
		if err != nil {
			log.Fatalf("Failed to initialize hardware controller: %v", err)
		}
		defer hwController.Close()

		go hwController.Start()

		<-sigChan
		log.Println("Shutting down hardware controller...")

	} else {
		log.Println("Please specify either -web or -hardware mode")
		flag.Usage()
		os.Exit(1)
	}

	log.Println("Application stopped")
}
