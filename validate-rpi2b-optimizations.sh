#!/bin/bash

# RPi 2B v1.1 Optimization Validation Script
# Validates that all optimizations are correctly configured for BCM2836

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}Raspberry Pi 2B v1.1 Optimization Validation${NC}"
echo -e "${BLUE}Verifying BCM2836 SoC optimizations${NC}"
echo "=============================================="

# Function to check if a value is correct
check_value() {
    local description="$1"
    local expected="$2"
    local actual="$3"

    if [[ "$actual" == "$expected" ]]; then
        echo -e "${GREEN}✓${NC} $description: $actual"
        return 0
    else
        echo -e "${RED}✗${NC} $description: Expected '$expected', got '$actual'"
        return 1
    fi
}

# Check if required files exist
echo -e "${YELLOW}Checking required files...${NC}"
REQUIRED_FILES=(
    "config.json"
    "build.sh"
    "README.md"
    "QUICKSTART.md"
    "WIRING.md"
    "Makefile"
)

MISSING_FILES=0
for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✓${NC} Found: $file"
    else
        echo -e "${RED}✗${NC} Missing: $file"
        ((MISSING_FILES++))
    fi
done

if [[ $MISSING_FILES -gt 0 ]]; then
    echo -e "${RED}Missing required files. Cannot continue validation.${NC}"
    exit 1
fi

# Validate config.json optimizations
echo ""
echo -e "${YELLOW}Validating config.json optimizations...${NC}"

if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}Warning: jq not installed. Using grep for JSON parsing.${NC}"

    # Check SPI speed (should be 500000 for RPi 2B v1.1 conservative setting)
    SPI_SPEED=$(grep -o '"spi_speed": [0-9]*' config.json | grep -o '[0-9]*')
    check_value "SPI Speed (Hz)" "500000" "$SPI_SPEED"

    # Check target board
    TARGET_BOARD=$(grep -o '"target_board": "[^"]*"' config.json | sed 's/"target_board": "\([^"]*\)"/\1/')
    check_value "Target Board" "rpi2b_v1.1" "$TARGET_BOARD"

    # Check SoC
    SOC=$(grep -o '"soc": "[^"]*"' config.json | sed 's/"soc": "\([^"]*\)"/\1/')
    check_value "SoC" "bcm2836" "$SOC"

    # Check CPU
    CPU=$(grep -o '"cpu": "[^"]*"' config.json | sed 's/"cpu": "\([^"]*\)"/\1/')
    check_value "CPU" "cortex_a7" "$CPU"

    # Check architecture
    ARCH=$(grep -o '"architecture": "[^"]*"' config.json | sed 's/"architecture": "\([^"]*\)"/\1/')
    check_value "Architecture" "armv7" "$ARCH"

    # Check max memory
    MAX_MEM=$(grep -o '"max_memory_mb": [0-9]*' config.json | grep -o '[0-9]*')
    check_value "Max Memory (MB)" "1024" "$MAX_MEM"

    # Check Cortex-A7 optimization
    CORTEX_OPT=$(grep -o '"optimized_for_cortex_a7": [a-z]*' config.json | grep -o '[a-z]*')
    check_value "Cortex-A7 Optimization" "true" "$CORTEX_OPT"

else
    # Using jq for more reliable JSON parsing
    SPI_SPEED=$(jq -r '.rfid.spi_speed' config.json)
    check_value "SPI Speed (Hz)" "500000" "$SPI_SPEED"

    TARGET_BOARD=$(jq -r '.system.target_board' config.json)
    check_value "Target Board" "rpi2b_v1.1" "$TARGET_BOARD"

    SOC=$(jq -r '.system.soc' config.json)
    check_value "SoC" "bcm2836" "$SOC"

    CPU=$(jq -r '.system.cpu' config.json)
    check_value "CPU" "cortex_a7" "$CPU"

    ARCH=$(jq -r '.system.architecture' config.json)
    check_value "Architecture" "armv7" "$ARCH"

    MAX_MEM=$(jq -r '.system.max_memory_mb' config.json)
    check_value "Max Memory (MB)" "1024" "$MAX_MEM"

    CORTEX_OPT=$(jq -r '.system.optimized_for_cortex_a7' config.json)
    check_value "Cortex-A7 Optimization" "true" "$CORTEX_OPT"

    # Check performance settings
    POLLING_INTERVAL=$(jq -r '.performance.polling_interval_ms' config.json)
    check_value "Polling Interval (ms)" "100" "$POLLING_INTERVAL"

    # Check GPIO driver
    GPIO_DRIVER=$(jq -r '.system.gpio_driver' config.json)
    check_value "GPIO Driver" "bcm2835" "$GPIO_DRIVER"

    # Check SPI max speed
    SPI_MAX_SPEED=$(jq -r '.system.spi_max_speed' config.json)
    check_value "SPI Max Speed (Hz)" "32000000" "$SPI_MAX_SPEED"
fi

# Validate build configuration
echo ""
echo -e "${YELLOW}Validating build configuration...${NC}"

# Check Makefile GOARM setting
MAKEFILE_GOARM=$(grep "GOARM.*:=.*7" Makefile | head -1)
if [[ -n "$MAKEFILE_GOARM" ]]; then
    echo -e "${GREEN}✓${NC} Makefile GOARM set to 7 (ARMv7)"
else
    echo -e "${RED}✗${NC} Makefile GOARM not set to 7"
fi

# Check build script targets
BUILD_SCRIPT_TARGET=$(grep "GOARM.*7.*#.*RPi.*2B.*v1.1" build.sh)
if [[ -n "$BUILD_SCRIPT_TARGET" ]]; then
    echo -e "${GREEN}✓${NC} Build script targets RPi 2B v1.1"
else
    echo -e "${RED}✗${NC} Build script target not configured for RPi 2B v1.1"
fi

# Check for BCM2836 references
BCM2836_REFS=$(grep -c "BCM2836" build.sh config.json README.md 2>/dev/null || echo "0")
if [[ $BCM2836_REFS -gt 5 ]]; then
    echo -e "${GREEN}✓${NC} BCM2836 SoC properly referenced ($BCM2836_REFS references)"
else
    echo -e "${YELLOW}⚠${NC} Limited BCM2836 references found ($BCM2836_REFS)"
fi

# Validate binary if it exists
echo ""
echo -e "${YELLOW}Validating binary (if built)...${NC}"

BINARY_PATHS=(
    "build/rfid-tool-rpi2b-v1.1"
    "build/rfid-tool-rpi2b"
    "dist/rfid-tool-rpi2b-v1.1-1.0.0/rfid-tool-rpi2b-v1.1"
)

BINARY_FOUND=false
for binary in "${BINARY_PATHS[@]}"; do
    if [[ -f "$binary" ]]; then
        BINARY_FOUND=true
        echo -e "${GREEN}✓${NC} Binary found: $binary"

        # Check binary architecture
        if command -v file &> /dev/null; then
            BINARY_ARCH=$(file "$binary")
            if [[ $BINARY_ARCH == *"ARM"* && $BINARY_ARCH == *"32-bit"* ]]; then
                echo -e "${GREEN}✓${NC} Binary architecture: ARM 32-bit"

                # Check for ARMv7 indicators
                if [[ $BINARY_ARCH == *"EABI5"* ]]; then
                    echo -e "${GREEN}✓${NC} Binary uses EABI5 (ARMv7 compatible)"
                else
                    echo -e "${YELLOW}⚠${NC} Binary EABI version unknown"
                fi
            else
                echo -e "${RED}✗${NC} Binary architecture incorrect: $BINARY_ARCH"
            fi
        else
            echo -e "${YELLOW}⚠${NC} Cannot verify binary architecture (file command not available)"
        fi

        # Check binary size (should be reasonable for embedded system)
        BINARY_SIZE=$(stat -f%z "$binary" 2>/dev/null || stat -c%s "$binary" 2>/dev/null || echo "0")
        BINARY_SIZE_MB=$((BINARY_SIZE / 1024 / 1024))
        if [[ $BINARY_SIZE_MB -lt 20 ]]; then
            echo -e "${GREEN}✓${NC} Binary size: ${BINARY_SIZE_MB}MB (appropriate for RPi 2B)"
        else
            echo -e "${YELLOW}⚠${NC} Binary size: ${BINARY_SIZE_MB}MB (large for embedded system)"
        fi
        break
    fi
done

if [[ $BINARY_FOUND == false ]]; then
    echo -e "${YELLOW}⚠${NC} No binary found. Run './build.sh' to build."
fi

# Check documentation
echo ""
echo -e "${YELLOW}Validating documentation...${NC}"

# Check README mentions RPi 2B v1.1
if grep -q "Raspberry Pi 2B v1.1" README.md; then
    echo -e "${GREEN}✓${NC} README specifically mentions RPi 2B v1.1"
else
    echo -e "${RED}✗${NC} README does not mention RPi 2B v1.1 specifically"
fi

# Check QUICKSTART mentions BCM2836
if grep -q "BCM2836" QUICKSTART.md; then
    echo -e "${GREEN}✓${NC} QUICKSTART mentions BCM2836 SoC"
else
    echo -e "${RED}✗${NC} QUICKSTART does not mention BCM2836 SoC"
fi

# Check wiring guide mentions RPi 2B
if grep -q "Raspberry Pi 2B" WIRING.md; then
    echo -e "${GREEN}✓${NC} WIRING guide mentions Raspberry Pi 2B"
else
    echo -e "${RED}✗${NC} WIRING guide does not mention Raspberry Pi 2B"
fi

# Validate GPIO pin assignments are RPi 2B compatible
echo ""
echo -e "${YELLOW}Validating GPIO pin assignments...${NC}"

# RPi 2B v1.1 has 40-pin GPIO header (same as B+ and later)
# Check that pins used are within valid range (0-53 for BCM numbering)
GPIO_PINS=(
    $(grep -o '".*_pin": [0-9]*' config.json | grep -o '[0-9]*' | sort -n | uniq)
    $(grep -o '".*_button": [0-9]*' config.json | grep -o '[0-9]*' | sort -n | uniq)
    $(grep -o '".*_led": [0-9]*' config.json | grep -o '[0-9]*' | sort -n | uniq)
)

INVALID_PINS=0
for pin in "${GPIO_PINS[@]}"; do
    if [[ $pin -ge 0 && $pin -le 53 ]]; then
        echo -e "${GREEN}✓${NC} GPIO pin $pin is valid for BCM2835/2836"
    else
        echo -e "${RED}✗${NC} GPIO pin $pin is invalid for BCM2835/2836"
        ((INVALID_PINS++))
    fi
done

# Specific pin validation for SPI and common pins
SPI_SDA=$(grep -o '".*spi.*": 0' config.json | grep -o '0')
if [[ -n "$SPI_SDA" ]]; then
    echo -e "${GREEN}✓${NC} SPI bus 0 is correct for BCM2836"
fi

# Check memory constraints
echo ""
echo -e "${YELLOW}Validating memory constraints...${NC}"

# Check if systemd service files mention memory limits (if they exist in dist)
DIST_DIRS=$(find dist -name "install.sh" -exec dirname {} \; 2>/dev/null)
for dist_dir in $DIST_DIRS; do
    if grep -q "MemoryLimit=" "$dist_dir/install.sh"; then
        WEB_MEM_LIMIT=$(grep "MemoryLimit=" "$dist_dir/install.sh" | grep "web" | grep -o '[0-9]*')
        HW_MEM_LIMIT=$(grep "MemoryLimit=" "$dist_dir/install.sh" | grep "hw" | grep -o '[0-9]*')

        if [[ $WEB_MEM_LIMIT -le 512 ]]; then
            echo -e "${GREEN}✓${NC} Web service memory limit: ${WEB_MEM_LIMIT}M (appropriate for 1GB system)"
        else
            echo -e "${YELLOW}⚠${NC} Web service memory limit: ${WEB_MEM_LIMIT}M (high for 1GB system)"
        fi

        if [[ $HW_MEM_LIMIT -le 256 ]]; then
            echo -e "${GREEN}✓${NC} Hardware service memory limit: ${HW_MEM_LIMIT}M (appropriate)"
        else
            echo -e "${YELLOW}⚠${NC} Hardware service memory limit: ${HW_MEM_LIMIT}M (high)"
        fi
    fi
done

# Final summary
echo ""
echo -e "${CYAN}Validation Summary${NC}"
echo "=================="

# Count checks (this is a simplified count)
TOTAL_CHECKS=15
PASSED_CHECKS=0

# Re-run key validations for summary (simplified)
if [[ -f "config.json" ]]; then ((PASSED_CHECKS++)); fi
if grep -q "500000" config.json; then ((PASSED_CHECKS++)); fi
if grep -q "rpi2b_v1.1" config.json; then ((PASSED_CHECKS++)); fi
if grep -q "bcm2836" config.json; then ((PASSED_CHECKS++)); fi
if grep -q "cortex_a7" config.json; then ((PASSED_CHECKS++)); fi
if grep -q "armv7" config.json; then ((PASSED_CHECKS++)); fi
if grep -q "1024" config.json; then ((PASSED_CHECKS++)); fi
if grep -q "GOARM.*:=.*7" Makefile; then ((PASSED_CHECKS++)); fi
if grep -q "BCM2836.*RPi.*2B.*v1.1" build.sh; then ((PASSED_CHECKS++)); fi
if grep -q "Raspberry Pi 2B v1.1" README.md; then ((PASSED_CHECKS++)); fi
if grep -q "BCM2836" QUICKSTART.md; then ((PASSED_CHECKS++)); fi
if grep -q "Raspberry Pi 2B" WIRING.md; then ((PASSED_CHECKS++)); fi
if [[ $INVALID_PINS -eq 0 ]]; then ((PASSED_CHECKS++)); fi
if [[ $MISSING_FILES -eq 0 ]]; then ((PASSED_CHECKS++)); fi
if [[ $BCM2836_REFS -gt 5 ]]; then ((PASSED_CHECKS++)); fi

PASS_RATE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))

echo "Checks passed: $PASSED_CHECKS/$TOTAL_CHECKS ($PASS_RATE%)"

if [[ $PASS_RATE -ge 90 ]]; then
    echo -e "${GREEN}✓ EXCELLENT${NC} - Optimizations are properly configured for RPi 2B v1.1"
    exit 0
elif [[ $PASS_RATE -ge 75 ]]; then
    echo -e "${YELLOW}⚠ GOOD${NC} - Most optimizations are correct, minor issues found"
    exit 0
elif [[ $PASS_RATE -ge 60 ]]; then
    echo -e "${YELLOW}⚠ FAIR${NC} - Some optimizations need attention"
    exit 1
else
    echo -e "${RED}✗ POOR${NC} - Major optimization issues found"
    exit 1
fi
