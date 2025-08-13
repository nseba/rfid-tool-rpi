# Multi-stage Dockerfile for RFID Tool
# Supports cross-platform builds for ARM and x64

# Build stage
FROM --platform=$BUILDPLATFORM golang:1.24-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates tzdata

# Set working directory
WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download && go mod verify

# Copy source code
COPY . .

# Build arguments for cross-compilation
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT

# Set build environment
ENV CGO_ENABLED=0
ENV GOOS=$TARGETOS
ENV GOARCH=$TARGETARCH

# Set ARM variant if applicable
RUN if [ "$TARGETARCH" = "arm" ]; then \
    if [ "$TARGETVARIANT" = "v6" ]; then \
    export GOARM=6; \
    elif [ "$TARGETVARIANT" = "v7" ]; then \
    export GOARM=7; \
    else \
    export GOARM=6; \
    fi; \
    fi

# Build the application
RUN go build \
    -ldflags='-w -s -extldflags "-static"' \
    -a -installsuffix cgo \
    -o rfid-tool \
    ./cmd/main.go

# Runtime stage
FROM scratch

# Copy CA certificates for HTTPS
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy timezone data
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# Copy the binary
COPY --from=builder /app/rfid-tool /rfid-tool

# Copy configuration
COPY --from=builder /app/config.json /config.json

# Create non-root user (even though we're using scratch)
USER 65534:65534

# Expose web interface port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ["/rfid-tool", "-web", "-port=8080", "-config=/config.json"]

# Default command
ENTRYPOINT ["/rfid-tool"]
CMD ["-web", "-port=8080", "-config=/config.json"]

# Labels for metadata
LABEL maintainer="RFID Tool Team" \
    description="RFID Reader/Writer Tool for Raspberry Pi and Linux systems" \
    version="1.0.0" \
    org.opencontainers.image.title="RFID Tool" \
    org.opencontainers.image.description="RFID Reader/Writer with web and hardware interfaces" \
    org.opencontainers.image.vendor="RFID Tool Project" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.source="https://github.com/yourrepo/rfid-tool-rpi" \
    org.opencontainers.image.documentation="https://github.com/yourrepo/rfid-tool-rpi/blob/main/README.md"
