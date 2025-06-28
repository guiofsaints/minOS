# NextUI Build Configuration
# Source this file to set up the build environment manually

# Platform configuration
export PLATFORM=${PLATFORM:-tg5040}
export UNION_PLATFORM=${PLATFORM}

# Cross-compilation setup for ARM64 (TrimUI)
export CROSS_COMPILE=${CROSS_COMPILE:-aarch64-linux-gnu-}
export CC=${CROSS_COMPILE}gcc
export CXX=${CROSS_COMPILE}g++
export AR=${CROSS_COMPILE}ar
export STRIP=${CROSS_COMPILE}strip
export RANLIB=${CROSS_COMPILE}ranlib

# Architecture settings
export BUILD_ARCH=aarch64-linux-gnu
export TARGET_ARCH=aarch64

# Build paths
export PREFIX=${PREFIX:-/usr}
export PREFIX_LOCAL=${PREFIX_LOCAL:-$HOME/.local}

# Library paths
export PKG_CONFIG_PATH="$PREFIX_LOCAL/lib/pkgconfig:${PKG_CONFIG_PATH}"
export LD_LIBRARY_PATH="$PREFIX_LOCAL/lib:${LD_LIBRARY_PATH}"
export C_INCLUDE_PATH="$PREFIX_LOCAL/include:${C_INCLUDE_PATH}"
export CPLUS_INCLUDE_PATH="$PREFIX_LOCAL/include:${CPLUS_INCLUDE_PATH}"

# Make configuration
export MAKEFLAGS="${MAKEFLAGS:--j$(nproc)}"

# Color output
export CLICOLOR=1
export FORCE_COLOR=1

# Build type (can be: release, debug, development)
export BUILD_TYPE=${BUILD_TYPE:-release}

# Optional features
export COMPILE_CORES=${COMPILE_CORES:-false}
export ENABLE_OPTIMIZATIONS=${ENABLE_OPTIMIZATIONS:-true}
export ENABLE_DEBUG=${ENABLE_DEBUG:-false}

# Development shortcuts
alias make-tg5040='make tg5040'
alias make-desktop='make PLATFORM=desktop'
alias make-quick='make -f makefile.native-build quick'
alias make-cores='make build-cores PLATFORM=tg5040'
alias make-check='./check-env.sh'
alias make-setup='./setup-linux.sh'

# Helper functions
nextui-build() {
    local platform=${1:-tg5040}
    echo "🚀 Building NextUI for $platform..."
    make $platform
}

nextui-clean() {
    echo "🧹 Cleaning build files..."
    make clean
    rm -rf build/ releases/
}

nextui-status() {
    echo "NextUI Build Environment Status:"
    echo "================================"
    echo "Platform: $PLATFORM"
    echo "Cross-compiler: $CROSS_COMPILE"
    echo "Prefix: $PREFIX_LOCAL"
    echo "Build type: $BUILD_TYPE"
    echo "Cores enabled: $COMPILE_CORES"
    echo ""
    if command -v $CC &> /dev/null; then
        echo "Compiler: $($CC --version | head -n1)"
    else
        echo "❌ Compiler not found: $CC"
    fi
    echo ""
    echo "Available commands:"
    echo "  nextui-build [platform]  - Build for platform (default: tg5040)"
    echo "  nextui-clean             - Clean all build files"
    echo "  nextui-status            - Show this status"
    echo "  make-check               - Check build environment"
}

# Print status when sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    echo "NextUI build environment loaded!"
    echo "Run 'nextui-status' for details or 'nextui-build' to start building."
fi
