#!/bin/bash
# NextUI Build Script
# Automatiza o processo de build do NextUI

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
PLATFORM="tg5040"
BUILD_CORES="essential"
CLEAN_FIRST="false"
VERBOSE="false"

# Functions
print_usage() {
    echo "NextUI Build Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -p, --platform PLATFORM    Target platform (tg5040, desktop) [default: tg5040]"
    echo "  -c, --cores TYPE           Core build type (none, essential, all) [default: essential]"
    echo "  -C, --clean                Clean build directory first"
    echo "  -v, --verbose              Verbose output"
    echo "  -h, --help                 Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                         # Build with essential cores"
    echo "  $0 -c none                 # Build system only (no cores)"
    echo "  $0 -c all                  # Build with all cores (may fail on some)"
    echo "  $0 -C -v                   # Clean build with verbose output"
}

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--platform)
            PLATFORM="$2"
            shift 2
            ;;
        -c|--cores)
            BUILD_CORES="$2"
            shift 2
            ;;
        -C|--clean)
            CLEAN_FIRST="true"
            shift
            ;;
        -v|--verbose)
            VERBOSE="true"
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Validate platform
if [[ "$PLATFORM" != "tg5040" && "$PLATFORM" != "desktop" ]]; then
    error "Invalid platform: $PLATFORM. Must be 'tg5040' or 'desktop'"
fi

# Validate cores option
if [[ "$BUILD_CORES" != "none" && "$BUILD_CORES" != "essential" && "$BUILD_CORES" != "all" ]]; then
    error "Invalid cores option: $BUILD_CORES. Must be 'none', 'essential', or 'all'"
fi

# Set verbose flags
MAKE_FLAGS=""
if [[ "$VERBOSE" == "true" ]]; then
    MAKE_FLAGS="MAKEFLAGS="
fi

log "NextUI Build Starting..."
log "Platform: $PLATFORM"
log "Cores: $BUILD_CORES"
log "Clean first: $CLEAN_FIRST"
log "Verbose: $VERBOSE"

# Clean if requested
if [[ "$CLEAN_FIRST" == "true" ]]; then
    log "Cleaning previous build..."
    make clean PLATFORM=$PLATFORM $MAKE_FLAGS || warn "Clean failed, continuing..."
fi

# Setup
log "Setting up build environment..."
make setup $MAKE_FLAGS || error "Setup failed"

# Build main system
log "Building main system..."
make build PLATFORM=$PLATFORM $MAKE_FLAGS || error "Main build failed"

# Build cores based on option
if [[ "$BUILD_CORES" == "essential" ]]; then
    log "Building essential cores..."
    make build-essential-cores PLATFORM=$PLATFORM $MAKE_FLAGS || warn "Some essential cores failed"
elif [[ "$BUILD_CORES" == "all" ]]; then
    log "Building all cores..."
    make build-cores PLATFORM=$PLATFORM $MAKE_FLAGS || warn "Some cores failed"
else
    log "Skipping core build"
fi

# System installation
log "Installing system components..."
make system PLATFORM=$PLATFORM $MAKE_FLAGS || error "System installation failed"

# Core installation
log "Installing cores..."
make cores PLATFORM=$PLATFORM $MAKE_FLAGS || warn "Some cores not found (normal if not built)"

# Special processing
log "Processing special components..."
make special $MAKE_FLAGS || error "Special processing failed"

# Package
log "Creating packages..."
make package $MAKE_FLAGS || error "Packaging failed"

# Done
make done $MAKE_FLAGS || true

# Summary
success "Build completed successfully!"

if [[ -d "releases" ]]; then
    log "Release files created:"
    ls -la releases/*.zip 2>/dev/null | tail -3 || true
fi

log "Build process finished."
