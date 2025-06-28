#!/bin/bash

# NextUI Environment Check Script
# Verifica se o ambiente está configurado corretamente para build

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[CHECK]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "========================================"
echo "NextUI Environment Check"
echo "========================================"

ERRORS=0
WARNINGS=0

# Check essential build tools
print_status "Checking essential build tools..."
for tool in gcc g++ make cmake git pkg-config; do
    if command -v $tool &> /dev/null; then
        VERSION=$($tool --version 2>/dev/null | head -n1 | cut -d' ' -f1-3)
        print_success "$tool: $VERSION"
    else
        print_error "$tool not found"
        ((ERRORS++))
    fi
done

# Check cross-compiler
print_status "Checking ARM64 cross-compiler..."
if command -v aarch64-linux-gnu-gcc &> /dev/null; then
    VERSION=$(aarch64-linux-gnu-gcc --version | head -n1)
    print_success "ARM64 cross-compiler: $VERSION"
else
    print_error "aarch64-linux-gnu-gcc not found"
    ((ERRORS++))
fi

# Check SDL2
print_status "Checking SDL2 libraries..."
for lib in sdl2 SDL2_image SDL2_ttf; do
    if pkg-config --exists $lib; then
        VERSION=$(pkg-config --modversion $lib)
        print_success "$lib: $VERSION"
    else
        print_error "$lib not found"
        ((ERRORS++))
    fi
done

# Check OpenGL
print_status "Checking OpenGL libraries..."
if pkg-config --exists gl; then
    print_success "OpenGL development libraries found"
else
    print_warning "OpenGL libraries not found via pkg-config"
    ((WARNINGS++))
fi

if pkg-config --exists glesv2; then
    print_success "OpenGL ES 2.0 libraries found"
else
    print_warning "OpenGL ES 2.0 libraries not found"
    ((WARNINGS++))
fi

# Check compression libraries
print_status "Checking compression libraries..."
for lib in libzip sqlite3 zlib; do
    if pkg-config --exists $lib; then
        VERSION=$(pkg-config --modversion $lib)
        print_success "$lib: $VERSION"
    else
        print_error "$lib not found"
        ((ERRORS++))
    fi
done

# Check audio libraries
print_status "Checking audio libraries..."
if pkg-config --exists samplerate; then
    VERSION=$(pkg-config --modversion samplerate)
    print_success "libsamplerate: $VERSION"
else
    print_error "libsamplerate not found"
    ((ERRORS++))
fi

# Check environment variables
print_status "Checking environment variables..."
if [ -n "$CROSS_COMPILE" ]; then
    print_success "CROSS_COMPILE: $CROSS_COMPILE"
else
    print_warning "CROSS_COMPILE not set"
    ((WARNINGS++))
fi

if [ -n "$PREFIX_LOCAL" ]; then
    print_success "PREFIX_LOCAL: $PREFIX_LOCAL"
else
    print_warning "PREFIX_LOCAL not set"
    ((WARNINGS++))
fi

if [ -n "$PLATFORM" ]; then
    print_success "PLATFORM: $PLATFORM"
else
    print_warning "PLATFORM not set (will use default)"
    ((WARNINGS++))
fi

# Check if directories exist
print_status "Checking local directories..."
for dir in "$HOME/.local/bin" "$HOME/.local/lib" "$HOME/.local/include"; do
    if [ -d "$dir" ]; then
        print_success "Directory exists: $dir"
    else
        print_warning "Directory missing: $dir"
        mkdir -p "$dir"
        print_success "Created: $dir"
    fi
done

# Try a simple compile test
print_status "Testing compilation..."
cat > /tmp/nextui_env_test.c << 'EOF'
#include <stdio.h>
#include <SDL2/SDL.h>
#include <sqlite3.h>

int main() {
    printf("Compilation test successful!\n");
    printf("SDL2 version: %d.%d.%d\n", 
           SDL_MAJOR_VERSION, SDL_MINOR_VERSION, SDL_PATCHLEVEL);
    printf("SQLite3 version: %s\n", sqlite3_libversion());
    return 0;
}
EOF

# Test native compilation
if gcc -o /tmp/nextui_env_test_native /tmp/nextui_env_test.c $(pkg-config --cflags --libs sdl2 sqlite3) 2>/dev/null; then
    print_success "Native compilation test passed"
    OUTPUT=$(/tmp/nextui_env_test_native)
    echo "    $OUTPUT"
else
    print_error "Native compilation test failed"
    ((ERRORS++))
fi

# Test cross-compilation (basic)
if aarch64-linux-gnu-gcc -c /tmp/nextui_env_test.c -o /tmp/nextui_env_test_arm64.o 2>/dev/null; then
    print_success "ARM64 cross-compilation test passed"
else
    print_warning "ARM64 cross-compilation test failed (may need sysroot setup)"
    ((WARNINGS++))
fi

# Clean up
rm -f /tmp/nextui_env_test.c /tmp/nextui_env_test_native /tmp/nextui_env_test_arm64.o

echo ""
echo "========================================"
echo "Environment Check Summary"
echo "========================================"

if [ $ERRORS -eq 0 ]; then
    print_success "All essential checks passed!"
    if [ $WARNINGS -eq 0 ]; then
        print_success "Environment is perfectly configured!"
        echo ""
        echo "You can now build NextUI:"
        echo "  make tg5040          - Build for TrimUI"
        echo "  make PLATFORM=desktop - Build for desktop"
    else
        print_warning "Found $WARNINGS warnings, but environment should work"
        echo ""
        echo "You can build NextUI, but some features may not work optimally:"
        echo "  make tg5040          - Build for TrimUI"
        echo "  make PLATFORM=desktop - Build for desktop"
    fi
else
    print_error "Found $ERRORS critical errors!"
    echo ""
    echo "Please fix the errors before building:"
    echo "  1. Run: ./setup-linux.sh"
    echo "  2. Restart your terminal or run: source ~/.bashrc"
    echo "  3. Run this check again: ./check-env.sh"
fi

echo ""
if [ $ERRORS -eq 0 ]; then
    exit 0
else
    exit 1
fi
