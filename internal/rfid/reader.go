package rfid

import (
	"fmt"
	"log"
	"time"

	"rfid-tool-rpi/internal/config"

	"periph.io/x/conn/v3/gpio"
	"periph.io/x/conn/v3/gpio/gpioreg"
	"periph.io/x/conn/v3/physic"
	"periph.io/x/conn/v3/spi"
	"periph.io/x/conn/v3/spi/spireg"
	"periph.io/x/host/v3"
)

// MFRC522 registers
const (
	// Command and status
	CommandReg    = 0x01
	ComIEnReg     = 0x02
	DivIEnReg     = 0x03
	ComIrqReg     = 0x04
	DivIrqReg     = 0x05
	ErrorReg      = 0x06
	Status1Reg    = 0x07
	Status2Reg    = 0x08
	FIFODataReg   = 0x09
	FIFOLevelReg  = 0x0A
	WaterLevelReg = 0x0B
	ControlReg    = 0x0C
	BitFramingReg = 0x0D
	CollReg       = 0x0E

	// Command
	ModeReg        = 0x11
	TxModeReg      = 0x12
	RxModeReg      = 0x13
	TxControlReg   = 0x14
	TxAutoReg      = 0x15
	TxSelReg       = 0x16
	RxSelReg       = 0x17
	RxThresholdReg = 0x18
	DemodReg       = 0x19
	MfTxReg        = 0x1C
	MfRxReg        = 0x1D
	SerialSpeedReg = 0x1F

	// Configuration
	CRCResultRegH     = 0x21
	CRCResultRegL     = 0x22
	ModWidthReg       = 0x24
	RFCfgReg          = 0x26
	GsNReg            = 0x27
	CWGsPReg          = 0x28
	ModGsPReg         = 0x29
	TModeReg          = 0x2A
	TPrescalerReg     = 0x2B
	TReloadRegH       = 0x2C
	TReloadRegL       = 0x2D
	TCounterValueRegH = 0x2E
	TCounterValueRegL = 0x2F

	// Test
	TestSel1Reg     = 0x31
	TestSel2Reg     = 0x32
	TestPinEnReg    = 0x33
	TestPinValueReg = 0x34
	TestBusReg      = 0x35
	AutoTestReg     = 0x36
	VersionReg      = 0x37
	AnalogTestReg   = 0x38
	TestDAC1Reg     = 0x39
	TestDAC2Reg     = 0x3A
	TestADCReg      = 0x3B
)

// MFRC522 commands
const (
	PCD_IDLE       = 0x00
	PCD_AUTHENT    = 0x0E
	PCD_RECEIVE    = 0x08
	PCD_TRANSMIT   = 0x04
	PCD_TRANSCEIVE = 0x0C
	PCD_RESETPHASE = 0x0F
	PCD_CALCCRC    = 0x03
)

// PICC commands
const (
	PICC_REQIDL    = 0x26
	PICC_REQALL    = 0x52
	PICC_ANTICOLL  = 0x93
	PICC_SElECTTAG = 0x93
	PICC_AUTHENT1A = 0x60
	PICC_AUTHENT1B = 0x61
	PICC_READ      = 0x30
	PICC_WRITE     = 0xA0
	PICC_DECREMENT = 0xC0
	PICC_INCREMENT = 0xC1
	PICC_RESTORE   = 0xC2
	PICC_TRANSFER  = 0xB0
	PICC_HALT      = 0x50
)

// Status codes
const (
	MI_OK       = 0
	MI_NOTAGERR = 1
	MI_ERR      = 2
)

// CardType represents different card types
type CardType string

const (
	CardTypeMifare1K CardType = "MIFARE 1K"
	CardTypeMifare4K CardType = "MIFARE 4K"
	CardTypeMifareUL CardType = "MIFARE Ultralight"
	CardTypeUnknown  CardType = "Unknown"
)

// Card represents an RFID card
type Card struct {
	UID       []byte
	Type      CardType
	Size      int
	Blocks    int
	SectorKey []byte
}

// String returns a string representation of the card
func (c *Card) String() string {
	return fmt.Sprintf("UID: %x, Type: %s, Size: %d bytes", c.UID, c.Type, c.Size)
}

// Reader represents an RFID reader
type Reader struct {
	spiPort  spi.Port
	spiConn  spi.Conn
	resetPin gpio.PinIO
	irqPin   gpio.PinIO
	config   config.RFIDConfig
	lastCard *Card
}

// NewReader creates a new RFID reader instance
func NewReader(cfg config.RFIDConfig) (*Reader, error) {
	// Initialize periph.io host
	if _, err := host.Init(); err != nil {
		return nil, fmt.Errorf("failed to initialize periph.io: %w", err)
	}

	// Open SPI connection
	spiPort, err := spireg.Open(fmt.Sprintf("/dev/spidev%d.%d", cfg.SPIBus, cfg.SPIDevice))
	if err != nil {
		return nil, fmt.Errorf("failed to open SPI: %w", err)
	}

	// Configure SPI
	spiConn, err := spiPort.Connect(physic.Frequency(cfg.SPISpeed)*physic.Hertz, spi.Mode0, 8)
	if err != nil {
		return nil, fmt.Errorf("failed to configure SPI: %w", err)
	}

	// Configure GPIO pins
	resetPin := gpioreg.ByName(fmt.Sprintf("GPIO%d", cfg.ResetPin))
	if resetPin == nil {
		return nil, fmt.Errorf("failed to get reset pin GPIO%d", cfg.ResetPin)
	}

	var irqPin gpio.PinIO
	if cfg.IRQPin > 0 {
		irqPin = gpioreg.ByName(fmt.Sprintf("GPIO%d", cfg.IRQPin))
		if irqPin == nil {
			return nil, fmt.Errorf("failed to get IRQ pin GPIO%d", cfg.IRQPin)
		}
	}

	reader := &Reader{
		spiPort:  spiPort,
		spiConn:  spiConn,
		resetPin: resetPin,
		irqPin:   irqPin,
		config:   cfg,
	}

	// Initialize the reader
	if err := reader.init(); err != nil {
		return nil, fmt.Errorf("failed to initialize reader: %w", err)
	}

	return reader, nil
}

// Close closes the reader and releases resources
func (r *Reader) Close() error {
	// SPI connections in periph.io are automatically closed when they go out of scope
	// No explicit close method is needed for spi.Port
	return nil
}

// init initializes the MFRC522 chip
func (r *Reader) init() error {
	// Reset the chip
	if err := r.resetPin.Out(gpio.Low); err != nil {
		return err
	}
	time.Sleep(10 * time.Millisecond)

	if err := r.resetPin.Out(gpio.High); err != nil {
		return err
	}
	time.Sleep(50 * time.Millisecond)

	// Soft reset
	r.writeRegister(CommandReg, PCD_RESETPHASE)
	time.Sleep(50 * time.Millisecond)

	// Configure timer
	r.writeRegister(TModeReg, 0x8D)
	r.writeRegister(TPrescalerReg, 0x3E)
	r.writeRegister(TReloadRegL, 30)
	r.writeRegister(TReloadRegH, 0)

	// Configure transmission
	r.writeRegister(TxAutoReg, 0x40)
	r.writeRegister(ModeReg, 0x3D)

	// Enable antenna
	r.setRegisterBitMask(TxControlReg, 0x03)

	// Check version
	version := r.readRegister(VersionReg)
	log.Printf("MFRC522 version: 0x%02x", version)

	if version == 0x00 || version == 0xFF {
		return fmt.Errorf("MFRC522 not found or not responding")
	}

	return nil
}

// readRegister reads a single register from the MFRC522
func (r *Reader) readRegister(reg byte) byte {
	write := []byte{(reg << 1) | 0x80, 0x00}
	read := make([]byte, 2)
	r.spiConn.Tx(write, read)
	return read[1]
}

// writeRegister writes a single register to the MFRC522
func (r *Reader) writeRegister(reg, value byte) {
	write := []byte{reg << 1, value}
	r.spiConn.Tx(write, nil)
}

// setRegisterBitMask sets specific bits in a register
func (r *Reader) setRegisterBitMask(reg, mask byte) {
	current := r.readRegister(reg)
	r.writeRegister(reg, current|mask)
}

// clearRegisterBitMask clears specific bits in a register
func (r *Reader) clearRegisterBitMask(reg, mask byte) {
	current := r.readRegister(reg)
	r.writeRegister(reg, current&(^mask))
}

// toCard converts raw data to a Card struct
func (r *Reader) toCard(uid []byte) *Card {
	card := &Card{
		UID:       uid,
		SectorKey: []byte{0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF}, // Default key
	}

	// Determine card type based on UID length and ATQA/SAK
	switch len(uid) {
	case 4:
		card.Type = CardTypeMifare1K
		card.Size = 1024
		card.Blocks = 64
	case 7:
		card.Type = CardTypeMifareUL
		card.Size = 512
		card.Blocks = 16
	default:
		card.Type = CardTypeUnknown
		card.Size = 0
		card.Blocks = 0
	}

	return card
}

// ScanForCard scans for a card and returns it if found
func (r *Reader) ScanForCard() (*Card, error) {
	// Request card
	status, _ := r.request(PICC_REQIDL)
	if status != MI_OK {
		return nil, fmt.Errorf("no card detected")
	}

	// Anti-collision
	status, uid := r.antiCollision()
	if status != MI_OK {
		return nil, fmt.Errorf("anti-collision failed")
	}

	card := r.toCard(uid)
	r.lastCard = card

	log.Printf("Card detected: %s", card.String())
	return card, nil
}

// ReadBlock reads a specific block from the card
func (r *Reader) ReadBlock(block int) ([]byte, error) {
	if r.lastCard == nil {
		return nil, fmt.Errorf("no card selected")
	}

	// Authenticate
	status := r.authenticate(PICC_AUTHENT1A, block, r.lastCard.SectorKey, r.lastCard.UID)
	if status != MI_OK {
		return nil, fmt.Errorf("authentication failed")
	}

	// Read block
	status, data := r.read(block)
	if status != MI_OK {
		return nil, fmt.Errorf("read failed")
	}

	return data, nil
}

// WriteBlock writes data to a specific block on the card
func (r *Reader) WriteBlock(block int, data []byte) error {
	if r.lastCard == nil {
		return fmt.Errorf("no card selected")
	}

	if len(data) != 16 {
		return fmt.Errorf("data must be exactly 16 bytes")
	}

	// Authenticate
	status := r.authenticate(PICC_AUTHENT1A, block, r.lastCard.SectorKey, r.lastCard.UID)
	if status != MI_OK {
		return fmt.Errorf("authentication failed")
	}

	// Write block
	status = r.write(block, data)
	if status != MI_OK {
		return fmt.Errorf("write failed")
	}

	return nil
}

// ReadCard reads all accessible blocks from the card
func (r *Reader) ReadCard() (map[int][]byte, error) {
	if r.lastCard == nil {
		return nil, fmt.Errorf("no card selected")
	}

	data := make(map[int][]byte)

	// Read all blocks except sector trailers
	for block := 0; block < r.lastCard.Blocks; block++ {
		// Skip sector trailer blocks (every 4th block starting from 3)
		if (block+1)%4 == 0 {
			continue
		}

		blockData, err := r.ReadBlock(block)
		if err != nil {
			log.Printf("Warning: Failed to read block %d: %v", block, err)
			continue
		}

		data[block] = blockData
	}

	return data, nil
}

// Low-level MFRC522 operations

func (r *Reader) request(mode byte) (int, []byte) {
	r.writeRegister(BitFramingReg, 0x07)

	tagType := []byte{mode}
	status, backData, _ := r.toCard2(PCD_TRANSCEIVE, tagType)

	if status != MI_OK || len(backData) != 2 {
		return MI_ERR, nil
	}

	return MI_OK, backData
}

func (r *Reader) antiCollision() (int, []byte) {
	r.writeRegister(BitFramingReg, 0x00)

	serNum := []byte{PICC_ANTICOLL, 0x20}
	status, backData, _ := r.toCard2(PCD_TRANSCEIVE, serNum)

	if status == MI_OK && len(backData) == 5 {
		serNumCheck := byte(0)
		for i := 0; i < 4; i++ {
			serNumCheck ^= backData[i]
		}
		if serNumCheck != backData[4] {
			return MI_ERR, nil
		}
	}

	return status, backData[:4]
}

func (r *Reader) authenticate(authMode byte, blockAddr int, sectorKey, serNum []byte) int {
	buff := []byte{authMode, byte(blockAddr)}
	buff = append(buff, sectorKey...)
	buff = append(buff, serNum...)

	status, _, _ := r.toCard2(PCD_AUTHENT, buff)

	if status != MI_OK || (r.readRegister(Status2Reg)&0x08) == 0 {
		return MI_ERR
	}

	return MI_OK
}

func (r *Reader) read(blockAddr int) (int, []byte) {
	recvData := []byte{PICC_READ, byte(blockAddr)}
	status, backData, _ := r.toCard2(PCD_TRANSCEIVE, recvData)

	if status != MI_OK || len(backData) != 16 {
		return MI_ERR, nil
	}

	return MI_OK, backData
}

func (r *Reader) write(blockAddr int, writeData []byte) int {
	buff := []byte{PICC_WRITE, byte(blockAddr)}
	status, _, _ := r.toCard2(PCD_TRANSCEIVE, buff)

	if status != MI_OK || (r.readRegister(Status2Reg)&0x08) == 0 {
		return MI_ERR
	}

	status, _, _ = r.toCard2(PCD_TRANSCEIVE, writeData)

	if status != MI_OK || (r.readRegister(Status2Reg)&0x08) == 0 {
		return MI_ERR
	}

	return MI_OK
}

func (r *Reader) toCard2(command byte, sendData []byte) (int, []byte, int) {
	var backData []byte
	var backLen int
	irqEn := byte(0x00)
	waitIRq := byte(0x00)

	switch command {
	case PCD_AUTHENT:
		irqEn = 0x12
		waitIRq = 0x10
	case PCD_TRANSCEIVE:
		irqEn = 0x77
		waitIRq = 0x30
	}

	r.writeRegister(ComIEnReg, irqEn|0x80)
	r.clearRegisterBitMask(ComIrqReg, 0x80)
	r.setRegisterBitMask(FIFOLevelReg, 0x80)

	r.writeRegister(CommandReg, PCD_IDLE)

	for _, data := range sendData {
		r.writeRegister(FIFODataReg, data)
	}

	r.writeRegister(CommandReg, command)

	if command == PCD_TRANSCEIVE {
		r.setRegisterBitMask(BitFramingReg, 0x80)
	}

	// Wait for completion
	i := 2000
	for i > 0 {
		n := r.readRegister(ComIrqReg)
		i--
		if n&0x01 != 0 {
			return MI_ERR, nil, 0
		}
		if n&waitIRq != 0 {
			break
		}
	}

	r.clearRegisterBitMask(BitFramingReg, 0x80)

	if i == 0 {
		return MI_ERR, nil, 0
	}

	error := r.readRegister(ErrorReg)
	if error&0x1B != 0 {
		return MI_ERR, nil, 0
	}

	status := MI_OK

	if command == PCD_TRANSCEIVE {
		n := r.readRegister(FIFOLevelReg)
		lastBits := r.readRegister(ControlReg) & 0x07

		if lastBits != 0 {
			backLen = (int(n)-1)*8 + int(lastBits)
		} else {
			backLen = int(n) * 8
		}

		if n == 0 {
			n = 1
		}
		if n > 16 {
			n = 16
		}

		backData = make([]byte, n)
		for i := byte(0); i < n; i++ {
			backData[i] = r.readRegister(FIFODataReg)
		}
	}

	return status, backData, backLen
}

// GetLastCard returns the last scanned card
func (r *Reader) GetLastCard() *Card {
	return r.lastCard
}

// IsCardPresent checks if a card is currently present
func (r *Reader) IsCardPresent() bool {
	_, err := r.ScanForCard()
	return err == nil
}

// StopCrypto stops the crypto operations
func (r *Reader) StopCrypto() {
	r.clearRegisterBitMask(Status2Reg, 0x08)
}
