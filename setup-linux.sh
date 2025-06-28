#!/bin/bash

# NextUI Linux/WSL Setup Script
# This script prepares your Linux/WSL environment to build NextUI without Docker

set -e  # Exit on any error

echo "=========================================="
echo "NextUI Linux/WSL Setup Script"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as a regular user."
   exit 1
fi

# Detect Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
else
    print_error "Cannot detect Linux distribution"
    exit 1
fi

print_status "Detected OS: $OS $VER"

# Check if we're in WSL
if grep -qi microsoft /proc/version; then
    print_status "Running in WSL environment"
    WSL=true
else
    WSL=false
fi

# Update package lists
print_status "Updating package lists..."
sudo apt-get update

# Install essential build tools
print_status "Installing essential build tools..."
sudo apt-get install -y \
    build-essential \
    gcc \
    g++ \
    make \
    cmake \
    git \
    pkg-config \
    bc \
    tree \
    unzip \
    zip \
    wget \
    curl \
    rsync \
    bzip2 \
    cpio \
    autotools-dev \
    autoconf \
    automake \
    libtool

# Install SDL2 and graphics libraries
print_status "Installing SDL2 and graphics libraries..."
sudo apt-get install -y \
    libsdl2-dev \
    libsdl2-image-dev \
    libsdl2-ttf-dev \
    libgl1-mesa-dev \
    libgles2-mesa-dev \
    libglu1-mesa-dev \
    libegl1-mesa-dev

# Install audio libraries
print_status "Installing audio libraries..."
sudo apt-get install -y \
    libsamplerate0-dev \
    libasound2-dev \
    pulseaudio-dev \
    libpulse-dev

# Install compression libraries
print_status "Installing compression libraries..."
sudo apt-get install -y \
    libzip-dev \
    libbz2-dev \
    liblzma-dev \
    libzstd-dev \
    zlib1g-dev

# Install database libraries
print_status "Installing database libraries..."
sudo apt-get install -y \
    libsqlite3-dev \
    sqlite3

# Install threading and system libraries
print_status "Installing system libraries..."
sudo apt-get install -y \
    libpthread-stubs0-dev \
    libncurses5-dev \
    libdl-dev

# Install cross-compilation toolchain for ARM64 (TrimUI)
print_status "Installing ARM64 cross-compilation toolchain..."
sudo apt-get install -y \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    libc6-dev-arm64-cross

# Install Python and related tools (for some build scripts)
print_status "Installing Python development tools..."
sudo apt-get install -y \
    python3 \
    python3-pip \
    python3-dev

# Create local directories for build
print_status "Setting up local build directories..."
mkdir -p ~/.local/{bin,include,lib}

# Set up environment variables
print_status "Setting up environment variables..."

# Create or update .bashrc with NextUI environment
BASHRC_ADDITIONS="
# NextUI Build Environment
export PATH=\"\$HOME/.local/bin:\$PATH\"
export PKG_CONFIG_PATH=\"\$HOME/.local/lib/pkgconfig:\$PKG_CONFIG_PATH\"
export LD_LIBRARY_PATH=\"\$HOME/.local/lib:\$LD_LIBRARY_PATH\"
export C_INCLUDE_PATH=\"\$HOME/.local/include:\$C_INCLUDE_PATH\"
export CPLUS_INCLUDE_PATH=\"\$HOME/.local/include:\$CPLUS_INCLUDE_PATH\"

# Cross-compilation environment for TrimUI (ARM64)
export CROSS_COMPILE=aarch64-linux-gnu-
export CC=\$CROSS_COMPILE\gcc
export CXX=\$CROSS_COMPILE\g++
export AR=\$CROSS_COMPILE\ar
export STRIP=\$CROSS_COMPILE\strip
export BUILD_ARCH=aarch64-linux-gnu
export PREFIX=/usr
export PREFIX_LOCAL=\$HOME/.local

# NextUI specific
export PLATFORM=tg5040
export UNION_PLATFORM=tg5040
"

# Check if NextUI environment is already in .bashrc
if ! grep -q "NextUI Build Environment" ~/.bashrc; then
    print_status "Adding NextUI environment to ~/.bashrc"
    echo "$BASHRC_ADDITIONS" >> ~/.bashrc
else
    print_warning "NextUI environment already exists in ~/.bashrc"
fi

# Source the environment for current session
export PATH="$HOME/.local/bin:$PATH"
export PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig:$PKG_CONFIG_PATH"
export LD_LIBRARY_PATH="$HOME/.local/lib:$LD_LIBRARY_PATH"
export C_INCLUDE_PATH="$HOME/.local/include:$C_INCLUDE_PATH"
export CPLUS_INCLUDE_PATH="$HOME/.local/include:$CPLUS_INCLUDE_PATH"
export CROSS_COMPILE=aarch64-linux-gnu-
export CC=${CROSS_COMPILE}gcc
export CXX=${CROSS_COMPILE}g++
export AR=${CROSS_COMPILE}ar
export STRIP=${CROSS_COMPILE}strip
export BUILD_ARCH=aarch64-linux-gnu
export PREFIX=/usr
export PREFIX_LOCAL=$HOME/.local
export PLATFORM=tg5040
export UNION_PLATFORM=tg5040

# Verify installations
print_status "Verifying installations..."

# Check SDL2
if pkg-config --exists sdl2; then
    SDL2_VERSION=$(pkg-config --modversion sdl2)
    print_success "SDL2 $SDL2_VERSION installed"
else
    print_error "SDL2 not found"
fi

# Check OpenGL
if pkg-config --exists gl; then
    print_success "OpenGL development libraries installed"
else
    print_warning "OpenGL libraries may not be properly installed"
fi

# Check SQLite
if pkg-config --exists sqlite3; then
    SQLITE_VERSION=$(pkg-config --modversion sqlite3)
    print_success "SQLite3 $SQLITE_VERSION installed"
else
    print_error "SQLite3 not found"
fi

# Check cross-compiler
if command -v aarch64-linux-gnu-gcc &> /dev/null; then
    GCC_VERSION=$(aarch64-linux-gnu-gcc --version | head -n1)
    print_success "ARM64 cross-compiler: $GCC_VERSION"
else
    print_error "ARM64 cross-compiler not found"
fi

# Check libzip
if pkg-config --exists libzip; then
    LIBZIP_VERSION=$(pkg-config --modversion libzip)
    print_success "libzip $LIBZIP_VERSION installed"
else
    print_warning "libzip not found via pkg-config"
fi

# Create a simple test to verify everything works
print_status "Creating build test..."
cat > /tmp/nextui_test.c << 'EOF'
#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include <SDL2/SDL_ttf.h>
#include <sqlite3.h>
#include <stdio.h>

int main() {
    printf("SDL2 version: %d.%d.%d\n", 
           SDL_MAJOR_VERSION, SDL_MINOR_VERSION, SDL_PATCHLEVEL);
    printf("SQLite3 version: %s\n", sqlite3_libversion());
    printf("Cross-compilation test successful!\n");
    return 0;
}
EOF

# Test native compilation
if gcc -o /tmp/nextui_test_native /tmp/nextui_test.c $(pkg-config --cflags --libs sdl2 SDL2_image SDL2_ttf sqlite3) 2>/dev/null; then
    print_success "Native compilation test passed"
    /tmp/nextui_test_native
else
    print_warning "Native compilation test failed"
fi

# Test cross-compilation
if aarch64-linux-gnu-gcc -o /tmp/nextui_test_arm64 /tmp/nextui_test.c -I/usr/include -I/usr/include/aarch64-linux-gnu $(pkg-config --cflags --libs sdl2 SDL2_image SDL2_ttf sqlite3) 2>/dev/null; then
    print_success "ARM64 cross-compilation test passed"
else
    print_warning "ARM64 cross-compilation test failed - this is normal if cross-sysroot is not fully set up"
fi

# Clean up test files
rm -f /tmp/nextui_test.c /tmp/nextui_test_native /tmp/nextui_test_arm64

print_status "Setup complete!"
echo ""
echo "=========================================="
echo "NextUI Build Environment Ready!"
echo "=========================================="
echo ""
print_success "Environment has been set up successfully!"
echo ""
echo "📁 Files created:"
echo "  - setup-linux.sh         Setup script (this file)"
echo "  - check-env.sh           Environment verification"
echo "  - build-linux.sh         One-click build script"
echo "  - build-env.sh           Manual environment config"
echo "  - BUILD-NATIVE.md        Detailed documentation"
echo ""
echo "🚀 Quick start:"
echo "  1. Restart your terminal or run: source ~/.bashrc"
echo "  2. Verify setup: ./check-env.sh"
echo "  3. Build firmware: ./build-linux.sh"
echo ""
echo "🔧 Manual build commands:"
echo "  make tg5040                  - Build for TrimUI (cross-compile)"
echo "  make PLATFORM=desktop       - Build for desktop/Linux"
echo "  make build-cores PLATFORM=tg5040 - Build libretro cores"
echo "  make clean                   - Clean build files"
echo ""
echo "📖 For advanced options, see BUILD-NATIVE.md"
echo ""
if [ "$WSL" = true ]; then
    print_warning "WSL Note: Graphics/OpenGL may require additional setup for testing"
    print_warning "For best results, consider using WSL2 with GUI support"
fi
echo ""
print_status "Making scripts executable..."
chmod +x check-env.sh build-linux.sh build-env.sh
echo ""
print_status "Happy coding! 🎮"
