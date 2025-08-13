# CI/CD Pipeline Documentation

This document describes the comprehensive CI/CD pipeline implemented for the RFID Tool project, providing automated testing, building, and deployment capabilities.

## Overview

The CI/CD pipeline is built using GitHub Actions and provides:

- 🧪 **Automated Testing**: Unit tests, integration tests, and code coverage
- 🔍 **Code Quality**: Linting, formatting, and security scanning
- 🏗️ **Multi-Platform Builds**: ARM v6/v7, ARM64, and x86-64 binaries
- 📦 **Automated Releases**: GitHub releases with distribution packages
- 🐳 **Container Images**: Multi-platform Docker images
- 📊 **Monitoring**: Code coverage and quality metrics
- 🔒 **Security**: Dependency scanning and vulnerability checks

## Pipeline Structure

### 1. Main CI/CD Pipeline (`ci.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main`
- Tag pushes (`v*`)

**Jobs:**

#### Test Job
- Runs on `ubuntu-latest`
- Sets up Go 1.21
- Downloads and verifies dependencies
- Runs tests with race detection and coverage
- Uploads coverage reports to Codecov

#### Lint Job
- Runs `golangci-lint` with comprehensive rules
- Enforces code style and best practices
- Checks for common issues and vulnerabilities

#### Security Job
- Runs Gosec security scanner
- Generates SARIF reports
- Uploads security findings to GitHub Security tab

#### Build Job
- Cross-compiles for multiple architectures:
  - `linux/arm/v6` (Raspberry Pi 2B) 
  - `linux/arm64` (Raspberry Pi 4, modern ARM)
  - `linux/amd64` (x86-64 Linux)
- Creates optimized binaries with build metadata
- Uploads build artifacts

#### Package Job
- Creates distribution packages for each architecture
- Includes documentation, installation scripts, and checksums
- Generates platform-specific packages

#### Docker Job
- Builds multi-platform container images
- Pushes to DockerHub and GitHub Container Registry
- Supports ARM v6, ARM v7, ARM64, and AMD64 architectures

### 2. Release Pipeline (`release.yml`)

**Triggers:**
- Tag pushes (`v*`)
- Manual workflow dispatch

**Features:**
- Version validation and changelog generation
- Complete test suite execution
- Multi-architecture binary builds
- Docker image creation and publishing
- GitHub release creation with comprehensive release notes
- Notification system (Discord/Slack integration)

## Configuration Files

### `.golangci.yml`
Comprehensive linting configuration with:
- 30+ enabled linters
- Custom rules for hardware-specific code
- Performance and security checks
- Style enforcement

### `Dockerfile`
Multi-stage build for production containers:
- Minimal scratch-based runtime
- Security hardening
- Health checks
- Multi-platform support

### `Dockerfile.dev`
Development container with:
- Hot reload capability (Air)
- Debugging tools (Delve)
- Development utilities
- Volume mounting for live development

### `docker-compose.yml`
Complete development environment:
- Web and hardware interface services
- Development container with hot reload
- Monitoring stack (Prometheus/Grafana)
- Testing services

### `.air.toml`
Hot reload configuration for development:
- Automatic rebuilds on file changes
- Configurable file watching
- Build error logging

## Dependency Management

### Dependabot Configuration (`.github/dependabot.yml`)
- Weekly dependency updates
- Grouped updates for related packages
- Automated PR creation
- Security vulnerability scanning

### Supported Dependencies
- **Go Modules**: periph.io, Gorilla toolkit
- **GitHub Actions**: Automated action updates
- **Docker**: Base image updates

## Quality Gates

### Code Quality Requirements
- ✅ All tests must pass
- ✅ Minimum 80% code coverage
- ✅ Zero linting errors
- ✅ Security scan passes
- ✅ Dependency audit clean

### Build Requirements
- ✅ Successful cross-compilation for all targets
- ✅ Binary size optimization
- ✅ Static linking verification

### Release Requirements
- ✅ Version tag validation
- ✅ Changelog generation
- ✅ Asset integrity verification
- ✅ Docker image publishing

## Local Development

### Using Make Commands
```bash
# Run complete CI pipeline locally
make ci-full

# Individual CI steps
make ci-setup     # Setup CI tools
make ci-test      # Run tests with coverage
make ci-lint      # Run linter
make ci-security  # Security scan
make ci-build-all # Build all architectures
make ci-package   # Create packages
```

### Using Docker
```bash
# Development environment
docker-compose --profile development up

# Run tests
docker-compose --profile testing up

# Full monitoring stack
docker-compose --profile monitoring up
```

## Build Artifacts

### Binary Distributions
- `rfid-tool-rpi-VERSION.tar.gz` - Raspberry Pi 2B/3/4 (ARM v6)
- `rfid-tool-armv7-VERSION.tar.gz` - ARM v7 systems
- `rfid-tool-arm64-VERSION.tar.gz` - ARM64 systems
- `rfid-tool-amd64-VERSION.tar.gz` - x86-64 Linux

Each package includes:
- Optimized binary
- Configuration file
- Installation scripts
- Complete documentation
- SHA256 checksums

### Container Images
```bash
# Production images
docker pull yourdockerhub/rfid-tool:latest
docker pull yourdockerhub/rfid-tool:v1.0.0

# GitHub Container Registry
docker pull ghcr.io/yourrepo/rfid-tool:latest
```

## Security Features

### Code Scanning
- **Gosec**: Go security analyzer
- **CodeQL**: GitHub's semantic analysis
- **Dependency scanning**: Known vulnerability detection
- **SARIF reporting**: Integration with GitHub Security

### Container Security
- **Minimal base images**: Scratch/distroless
- **Non-root execution**: Security hardening
- **Signature verification**: Image integrity
- **Regular updates**: Automated base image updates

## Monitoring and Observability

### Metrics Collected
- Build success/failure rates
- Test coverage trends
- Build duration metrics
- Deployment frequency
- Security scan results

### Available Dashboards
- **GitHub Actions**: Build and deployment status
- **Codecov**: Test coverage reports
- **Docker Hub**: Image pull statistics
- **GitHub Security**: Vulnerability tracking

## Release Process

### Automatic Releases
1. **Tag Creation**: Push a version tag (`git tag v1.0.0 && git push --tags`)
2. **Pipeline Execution**: Automatic CI/CD pipeline triggers
3. **Asset Creation**: Binaries and packages built automatically
4. **Release Publication**: GitHub release with changelog
5. **Container Publishing**: Docker images pushed to registries

### Manual Releases
```bash
# Using GitHub CLI
gh workflow run release.yml -f version=v1.0.0 -f prerelease=false

# Or via GitHub web interface
# Actions → Release → Run workflow
```

## Issue Templates and Automation

### Available Templates
- **Bug Report**: Structured bug reporting with environment details
- **Feature Request**: Feature suggestions with use cases
- **Hardware Support**: Hardware compatibility issues

### Automated Responses
- PR template with comprehensive checklist
- Automatic labeling based on file changes
- Milestone assignment for releases

## Environment Variables and Secrets

### Required Secrets
- `GITHUB_TOKEN`: Automatic releases and container registry
- `DOCKERHUB_USERNAME`: Docker Hub publishing
- `DOCKERHUB_TOKEN`: Docker Hub authentication
- `CODECOV_TOKEN`: Code coverage reporting (optional)
- `DISCORD_WEBHOOK`: Release notifications (optional)
- `SLACK_WEBHOOK`: Release notifications (optional)

### Environment Configuration
- Go version: 1.21 (configurable in workflow)
- Target architectures: ARM v6/v7, ARM64, AMD64
- Build optimization: Enabled by default
- Security scanning: Always enabled

## Troubleshooting

### Common Issues

**Build Failures:**
- Check Go version compatibility
- Verify dependency availability
- Review cross-compilation settings

**Test Failures:**
- Check hardware-specific test mocks
- Verify GPIO/SPI simulation
- Review test environment setup

**Security Scan Issues:**
- Update vulnerable dependencies
- Review Gosec exclusions
- Check for hardcoded secrets

**Docker Build Issues:**
- Verify multi-platform buildx setup
- Check base image availability
- Review layer caching configuration

### Debug Commands
```bash
# Local CI simulation
act -j test  # Run GitHub Actions locally

# Docker debugging
docker build --progress=plain --no-cache .
docker run --rm -it rfid-tool:dev /bin/bash

# Coverage analysis
go tool cover -html=coverage.out
```

## Performance Optimizations

### Build Optimizations
- **Parallel builds**: Multiple architecture builds run concurrently
- **Layer caching**: Docker layer caching for faster builds
- **Artifact caching**: Go module and build caches
- **Incremental builds**: Only build changed components

### Resource Management
- **Build timeouts**: Prevent hanging builds
- **Resource limits**: Memory and CPU constraints
- **Cleanup policies**: Automatic artifact cleanup
- **Cost optimization**: Efficient runner usage

## Future Enhancements

### Planned Features
- [ ] Integration testing with hardware simulation
- [ ] Performance benchmarking in CI
- [ ] Automated security updates
- [ ] Multi-environment deployments
- [ ] A/B testing capabilities
- [ ] Chaos engineering tests

### Infrastructure Improvements
- [ ] Self-hosted runners for ARM builds
- [ ] Kubernetes deployment automation
- [ ] Infrastructure as Code (Terraform)
- [ ] Advanced monitoring and alerting
- [ ] Automated rollback capabilities

This CI/CD pipeline ensures high-quality, secure, and reliable releases while maintaining developer productivity and operational excellence.