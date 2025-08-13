package rfid

import (
	"testing"

	"rfid-tool-rpi/internal/config"
)

func TestCardString(t *testing.T) {
	card := &Card{
		UID:    []byte{0x12, 0x34, 0x56, 0x78},
		Type:   CardTypeMifare1K,
		Size:   1024,
		Blocks: 64,
	}

	expected := "UID: 12345678, Type: MIFARE 1K, Size: 1024 bytes"
	if card.String() != expected {
		t.Errorf("Card.String() = %v, want %v", card.String(), expected)
	}
}

func TestCardTypeDetection(t *testing.T) {
	reader := &Reader{}

	// Test MIFARE 1K (4 byte UID)
	card1K := reader.toCard([]byte{0x12, 0x34, 0x56, 0x78})
	if card1K.Type != CardTypeMifare1K {
		t.Errorf("Expected MIFARE 1K, got %v", card1K.Type)
	}
	if card1K.Size != 1024 {
		t.Errorf("Expected size 1024, got %d", card1K.Size)
	}
	if card1K.Blocks != 64 {
		t.Errorf("Expected 64 blocks, got %d", card1K.Blocks)
	}

	// Test MIFARE Ultralight (7 byte UID)
	cardUL := reader.toCard([]byte{0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE})
	if cardUL.Type != CardTypeMifareUL {
		t.Errorf("Expected MIFARE Ultralight, got %v", cardUL.Type)
	}
	if cardUL.Size != 512 {
		t.Errorf("Expected size 512, got %d", cardUL.Size)
	}
	if cardUL.Blocks != 16 {
		t.Errorf("Expected 16 blocks, got %d", cardUL.Blocks)
	}

	// Test unknown card type
	cardUnknown := reader.toCard([]byte{0x12, 0x34})
	if cardUnknown.Type != CardTypeUnknown {
		t.Errorf("Expected Unknown, got %v", cardUnknown.Type)
	}
}

func TestDefaultConfig(t *testing.T) {
	cfg := config.Default()

	// Test RFID config defaults
	if cfg.RFID.SPIBus != 0 {
		t.Errorf("Expected SPI bus 0, got %d", cfg.RFID.SPIBus)
	}
	if cfg.RFID.SPIDevice != 0 {
		t.Errorf("Expected SPI device 0, got %d", cfg.RFID.SPIDevice)
	}
	if cfg.RFID.ResetPin != 22 {
		t.Errorf("Expected reset pin 22, got %d", cfg.RFID.ResetPin)
	}
	if cfg.RFID.SPISpeed != 500000 {
		t.Errorf("Expected SPI speed 500kHz, got %d", cfg.RFID.SPISpeed)
	}

	// Test hardware config defaults
	if cfg.Hardware.ReadButton != 2 {
		t.Errorf("Expected read button GPIO2, got %d", cfg.Hardware.ReadButton)
	}
	if cfg.Hardware.WriteButton != 3 {
		t.Errorf("Expected write button GPIO3, got %d", cfg.Hardware.WriteButton)
	}
}

func TestRegisterOperations(t *testing.T) {
	// These tests would require actual hardware or mocking
	// For now, just test that the constants are defined correctly

	if CommandReg != 0x01 {
		t.Errorf("Expected CommandReg 0x01, got 0x%02x", CommandReg)
	}
	if VersionReg != 0x37 {
		t.Errorf("Expected VersionReg 0x37, got 0x%02x", VersionReg)
	}
	if PICCReqIDL != 0x26 {
		t.Errorf("Expected PICCReqIDL 0x26, got 0x%02x", PICCReqIDL)
	}
	if PICCAuthent1A != 0x60 {
		t.Errorf("Expected PICCAuthent1A 0x60, got 0x%02x", PICCAuthent1A)
	}
}

func TestStatusCodes(t *testing.T) {
	if MIOK != 0 {
		t.Errorf("Expected MIOK 0, got %d", MIOK)
	}
	if MINoTagErr != 1 {
		t.Errorf("Expected MINoTagErr 1, got %d", MINoTagErr)
	}
	if MIErr != 2 {
		t.Errorf("Expected MIErr 2, got %d", MIErr)
	}
}
