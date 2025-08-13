# RFID Tool RPi Makefile
# Cross-compilation Makefile for building on macOS M1 for Raspberry Pi ARM

.PHONY: all build clean test deps install-deps cross-build local-build help

# Configuration
APP_NAME := rfid-tool
VERSION ?= 1.0.0
BUILD_DIR := build
DIST_DIR := dist
CMD_DIR := cmd

# Go build configuration for cross-compilation
GOOS := linux
GOARCH := arm
GOARM := 6

# Build flags
BUILD_TIME := $(shell date -u '+%Y-%m-%d_%H:%M:%S')
GIT_COMMIT := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
LDFLAGS := -s -w -X main.version=$(VERSION) -X main.buildTime=$(BUILD_TIME) -X main.gitCommit=$(GIT_COMMIT)

# Colors for output
CYAN := \033[36m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
NC := \033[0m

# Default target
all: clean deps cross-build package

# Help target
help:
	@echo "$(CYAN)RFID Tool RPi Makefile$(NC)"
	@echo "========================"
	@echo ""
	@echo "$(GREEN)Available targets:$(NC)"
	@echo "  $(YELLOW)all$(NC)          - Clean, install deps, cross-build, and package"
	@echo "  $(YELLOW)build$(NC)        - Alias for cross-build"
	@echo "  $(YELLOW)cross-build$(NC)  - Build for Raspberry Pi (linux/arm)"
	@echo "  $(YELLOW)local-build$(NC)  - Build for current platform"
	@echo "  $(YELLOW)deps$(NC)         - Download Go dependencies"
	@echo "  $(YELLOW)install-deps$(NC) - Install development dependencies"
	@echo "  $(YELLOW)test$(NC)         - Run tests"
	@echo "  $(YELLOW)clean$(NC)        - Clean build artifacts"
	@echo "  $(YELLOW)package$(NC)      - Create distribution package"
	@echo "  $(YELLOW)format$(NC)       - Format Go code"
	@echo "  $(YELLOW)lint$(NC)         - Run Go linter"
	@echo ""
	@echo "$(GREEN)CI/CD targets:$(NC)"
	@echo "  $(YELLOW)ci-setup$(NC)     - Setup CI environment"
	@echo "  $(YELLOW)ci-test$(NC)      - Run CI tests with coverage"
	@echo "  $(YELLOW)ci-lint$(NC)      - Run CI linting"
	@echo "  $(YELLOW)ci-security$(NC)  - Run security scanning"
	@echo "  $(YELLOW)ci-build-all$(NC) - Build all architectures"
	@echo "  $(YELLOW)ci-package$(NC)   - Create all distribution packages"
	@echo "  $(YELLOW)ci-full$(NC)      - Run complete CI pipeline"
	@echo ""
	@echo "$(GREEN)Docker targets:$(NC)"
	@echo "  $(YELLOW)docker-build$(NC) - Build Docker image"
	@echo "  $(YELLOW)docker-build-dev$(NC) - Build development Docker image"
	@echo "  $(YELLOW)docker-run$(NC)   - Run Docker container"
	@echo "  $(YELLOW)docker-stop$(NC)  - Stop Docker container"
	@echo "  $(YELLOW)docker-dev$(NC)   - Start development environment"
	@echo "  $(YELLOW)docker-test$(NC)  - Run tests in Docker"
	@echo ""
	@echo "$(GREEN)Utility targets:$(NC)"
	@echo "  $(YELLOW)coverage$(NC)     - Generate test coverage report"
	@echo "  $(YELLOW)benchmark$(NC)    - Run benchmarks"
	@echo "  $(YELLOW)profile$(NC)      - Build with profiling support"
	@echo "  $(YELLOW)update-deps$(NC)  - Update all dependencies"
	@echo "  $(YELLOW)verify-deps$(NC)  - Verify dependency checksums"
	@echo "  $(YELLOW)audit$(NC)        - Run security audit on dependencies"
	@echo "  $(YELLOW)generate$(NC)     - Run go generate"
	@echo "  $(YELLOW)help$(NC)         - Show this help message"
	@echo ""
	@echo "$(GREEN)Environment variables:$(NC)"
	@echo "  $(YELLOW)VERSION$(NC)      - Build version (default: $(VERSION))"
	@echo ""

# Install development dependencies
install-deps:
	@echo "$(YELLOW)Installing development dependencies...$(NC)"
	@command -v go >/dev/null 2>&1 || { echo "$(RED)Go is not installed$(NC)"; exit 1; }
	@go version
	@echo "$(GREEN)✓ Go is available$(NC)"

# Download Go dependencies
deps:
	@echo "$(YELLOW)Downloading Go dependencies...$(NC)"
	@go mod download
	@go mod tidy
	@echo "$(GREEN)✓ Dependencies updated$(NC)"

# Run tests
test:
	@echo "$(YELLOW)Running tests...$(NC)"
	@go test -v ./...

# Format Go code
format:
	@echo "$(YELLOW)Formatting Go code...$(NC)"
	@go fmt ./...
	@echo "$(GREEN)✓ Code formatted$(NC)"

# Run Go linter
lint:
	@echo "$(YELLOW)Running Go linter...$(NC)"
	@command -v golangci-lint >/dev/null 2>&1 || { echo "$(RED)golangci-lint not installed. Run: brew install golangci-lint$(NC)"; exit 1; }
	@golangci-lint run ./...
	@echo "$(GREEN)✓ Linting passed$(NC)"

# Clean build artifacts
clean:
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	@rm -rf $(BUILD_DIR)
	@rm -rf $(DIST_DIR)
	@echo "$(GREEN)✓ Clean completed$(NC)"

# Cross-compile for Raspberry Pi
cross-build: deps
	@echo "$(YELLOW)Cross-compiling for Raspberry Pi ($(GOOS)/$(GOARCH))...$(NC)"
	@mkdir -p $(BUILD_DIR)
	@CGO_ENABLED=0 GOOS=$(GOOS) GOARCH=$(GOARCH) GOARM=$(GOARM) \
		go build -ldflags "$(LDFLAGS)" -o $(BUILD_DIR)/$(APP_NAME)-rpi ./$(CMD_DIR)/main.go
	@echo "$(GREEN)✓ Cross-compilation completed$(NC)"
	@ls -lh $(BUILD_DIR)/$(APP_NAME)-rpi

# Build for current platform (development)
local-build: deps
	@echo "$(YELLOW)Building for current platform...$(NC)"
	@mkdir -p $(BUILD_DIR)
	@go build -ldflags "$(LDFLAGS)" -o $(BUILD_DIR)/$(APP_NAME) ./$(CMD_DIR)/main.go
	@echo "$(GREEN)✓ Local build completed$(NC)"
	@ls -lh $(BUILD_DIR)/$(APP_NAME)

# Alias for cross-build
build: cross-build

# Create distribution package
package: cross-build
	@echo "$(YELLOW)Creating distribution package...$(NC)"
	@mkdir -p $(DIST_DIR)
	@./build.sh
	@echo "$(GREEN)✓ Distribution package created$(NC)"

# Development server (requires hardware)
dev-web: local-build
	@echo "$(YELLOW)Starting development web server...$(NC)"
	@echo "$(RED)Warning: Requires RFID hardware to be connected$(NC)"
	@sudo ./$(BUILD_DIR)/$(APP_NAME) -web -port=8080

# Development hardware mode (requires hardware)
dev-hw: local-build
	@echo "$(YELLOW)Starting development hardware mode...$(NC)"
	@echo "$(RED)Warning: Requires RFID hardware and buttons/LEDs$(NC)"
	@sudo ./$(BUILD_DIR)/$(APP_NAME) -hardware

# Quick development check
check: format lint test
	@echo "$(GREEN)✓ All checks passed$(NC)"

# Release build
release: clean check cross-build package
	@echo "$(GREEN)✓ Release build completed$(NC)"
	@echo "Distribution package: $(DIST_DIR)/$(APP_NAME)-rpi-$(VERSION).tar.gz"

# Show build info
info:
	@echo "$(CYAN)Build Information$(NC)"
	@echo "=================="
	@echo "App name: $(APP_NAME)"
	@echo "Version: $(VERSION)"
	@echo "Target: $(GOOS)/$(GOARCH) (ARM v$(GOARM))"
	@echo "Build time: $(BUILD_TIME)"
	@echo "Git commit: $(GIT_COMMIT)"
	@echo "LDFLAGS: $(LDFLAGS)"

# CI/CD targets
ci-setup:
	@echo "$(YELLOW)Setting up CI environment...$(NC)"
	@go version
	@which golangci-lint || (echo "Installing golangci-lint..." && go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest)

ci-test: deps
	@echo "$(YELLOW)Running CI tests...$(NC)"
	@go test -v -race -coverprofile=coverage.out ./...
	@go tool cover -html=coverage.out -o coverage.html

ci-lint:
	@echo "$(YELLOW)Running CI linter...$(NC)"
	@golangci-lint run --timeout=5m ./...

ci-security:
	@echo "$(YELLOW)Running security scan...$(NC)"
	@which gosec || (echo "Installing gosec..." && go install github.com/securecodewarrior/gosec/v2/cmd/gosec@latest)
	@gosec -no-fail -fmt sarif -out results.sarif ./...

ci-build-all: clean deps
	@echo "$(YELLOW)Building all CI targets...$(NC)"
	@mkdir -p $(BUILD_DIR)
	# ARM v6 (Raspberry Pi 2B)
	@CGO_ENABLED=0 GOOS=linux GOARCH=arm GOARM=6 \
		go build -ldflags "$(LDFLAGS)" -o $(BUILD_DIR)/$(APP_NAME)-rpi ./$(CMD_DIR)/main.go
	# ARM v7 (Raspberry Pi 3/4)
	@CGO_ENABLED=0 GOOS=linux GOARCH=arm GOARM=7 \
		go build -ldflags "$(LDFLAGS)" -o $(BUILD_DIR)/$(APP_NAME)-armv7 ./$(CMD_DIR)/main.go
	# ARM64
	@CGO_ENABLED=0 GOOS=linux GOARCH=arm64 \
		go build -ldflags "$(LDFLAGS)" -o $(BUILD_DIR)/$(APP_NAME)-arm64 ./$(CMD_DIR)/main.go
	# AMD64
	@CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
		go build -ldflags "$(LDFLAGS)" -o $(BUILD_DIR)/$(APP_NAME)-amd64 ./$(CMD_DIR)/main.go
	@echo "$(GREEN)✓ All CI builds completed$(NC)"

ci-package: ci-build-all
	@echo "$(YELLOW)Creating CI distribution packages...$(NC)"
	@mkdir -p $(DIST_DIR)
	@for arch in rpi armv7 arm64 amd64; do \
		DIST_NAME="$(APP_NAME)-$$arch-$(VERSION)"; \
		DIST_PATH="$(DIST_DIR)/$$DIST_NAME"; \
		mkdir -p "$$DIST_PATH"; \
		cp "$(BUILD_DIR)/$(APP_NAME)-$$arch" "$$DIST_PATH/$(APP_NAME)"; \
		chmod +x "$$DIST_PATH/$(APP_NAME)"; \
		cp config.json README.md WIRING.md QUICKSTART.md "$$DIST_PATH/"; \
		if [ "$$arch" = "rpi" ]; then \
			cp scripts/install-rpi.sh "$$DIST_PATH/install.sh"; \
		else \
			sed 's/rfid-tool-rpi/rfid-tool/g' scripts/install-rpi.sh > "$$DIST_PATH/install.sh"; \
		fi; \
		chmod +x "$$DIST_PATH/install.sh"; \
		cd $(DIST_DIR) && tar -czf "$$DIST_NAME.tar.gz" "$$DIST_NAME" && cd ..; \
	done
	@echo "$(GREEN)✓ All CI packages created$(NC)"

ci-full: ci-setup ci-lint ci-security ci-test ci-package
	@echo "$(GREEN)✓ Full CI pipeline completed$(NC)"

# Docker targets
docker-build:
	@echo "$(YELLOW)Building Docker image...$(NC)"
	@docker build -t $(APP_NAME):latest .

docker-build-dev:
	@echo "$(YELLOW)Building development Docker image...$(NC)"
	@docker build -f Dockerfile.dev -t $(APP_NAME):dev .

docker-run:
	@echo "$(YELLOW)Running Docker container...$(NC)"
	@docker run -d \
		--name $(APP_NAME) \
		--privileged \
		--device /dev/spidev0.0:/dev/spidev0.0 2>/dev/null || true \
		--device /dev/gpiomem:/dev/gpiomem 2>/dev/null || true \
		-p 8080:8080 \
		-v /dev:/dev \
		$(APP_NAME):latest

docker-stop:
	@echo "$(YELLOW)Stopping Docker container...$(NC)"
	@docker stop $(APP_NAME) 2>/dev/null || true
	@docker rm $(APP_NAME) 2>/dev/null || true

docker-dev:
	@echo "$(YELLOW)Starting development environment...$(NC)"
	@docker-compose --profile development up -d rfid-tool-dev

docker-test:
	@echo "$(YELLOW)Running tests in Docker...$(NC)"
	@docker-compose --profile testing up --build rfid-test

# Utility targets
coverage:
	@echo "$(YELLOW)Generating coverage report...$(NC)"
	@go test -v -coverprofile=coverage.out ./...
	@go tool cover -html=coverage.out -o coverage.html
	@go tool cover -func=coverage.out

benchmark:
	@echo "$(YELLOW)Running benchmarks...$(NC)"
	@go test -bench=. -benchmem ./...

profile:
	@echo "$(YELLOW)Running with profiling...$(NC)"
	@go build -ldflags "$(LDFLAGS)" -o $(BUILD_DIR)/$(APP_NAME)-profile ./$(CMD_DIR)/main.go
	@echo "Run with: $(BUILD_DIR)/$(APP_NAME)-profile -web -port=8080 -cpuprofile=cpu.prof -memprofile=mem.prof"

# Maintenance targets
update-deps:
	@echo "$(YELLOW)Updating dependencies...$(NC)"
	@go get -u ./...
	@go mod tidy

verify-deps:
	@echo "$(YELLOW)Verifying dependencies...$(NC)"
	@go mod verify

audit:
	@echo "$(YELLOW)Running security audit...$(NC)"
	@which nancy || (echo "Installing nancy..." && go install github.com/sonatypeoss/nancy@latest)
	@go list -json -m all | nancy sleuth

generate:
	@echo "$(YELLOW)Running go generate...$(NC)"
	@go generate ./...
