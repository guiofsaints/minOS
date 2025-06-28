#!/bin/bash

# NextUI One-Line Setup Script
# curl -sSL https://raw.githubusercontent.com/NextUI/NextUI/main/install-linux.sh | bash

echo "🎮 NextUI Linux Setup & Build"
echo "=============================="

# Check if we're in the NextUI directory
if [ ! -f "setup-linux.sh" ]; then
    echo "❌ Not in NextUI directory. Please run this from the NextUI root directory."
    echo ""
    echo "To get started:"
    echo "  git clone https://github.com/NextUI/NextUI.git"
    echo "  cd NextUI"
    echo "  ./setup-linux.sh"
    exit 1
fi

# Run setup
echo "🔧 Setting up build environment..."
chmod +x setup-linux.sh check-env.sh
./setup-linux.sh

echo ""
echo "✅ Checking environment..."
if ./check-env.sh; then
    echo ""
    echo "🚀 Starting build..."
    
    # Ask user what to build
    echo "What would you like to build?"
    echo "  1) TrimUI firmware (tg5040) - Full build"
    echo "  2) Desktop version - For testing"
    echo "  3) Quick build - Fast, no packaging"
    echo "  4) Just cores - Libretro emulator cores only"
    echo ""
    read -p "Choose [1-4] (default: 1): " choice
    
    case $choice in
        2)
            echo "🖥️ Building for desktop..."
            make PLATFORM=desktop
            ;;
        3)
            echo "⚡ Quick build..."
            make -f makefile.native-build quick
            ;;
        4)
            echo "🎮 Building cores..."
            make build-cores PLATFORM=tg5040
            ;;
        *)
            echo "📱 Building TrimUI firmware..."
            make tg5040
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "🎉 Build completed successfully!"
        echo ""
        echo "📁 Build output is in: ./build/"
        echo "📦 Release files are in: ./releases/"
        echo ""
        echo "To build again:"
        echo "  make tg5040          # Full TrimUI build"
        echo "  make PLATFORM=desktop # Desktop build"
        echo "  make clean           # Clean build files"
    else
        echo ""
        echo "❌ Build failed. Check the error messages above."
        echo ""
        echo "To troubleshoot:"
        echo "  ./check-env.sh       # Verify environment"
        echo "  ./setup-linux.sh     # Re-run setup"
    fi
else
    echo ""
    echo "❌ Environment check failed. Please fix the errors and try again."
    echo ""
    echo "To fix:"
    echo "  ./setup-linux.sh     # Re-run setup"
    echo "  source ~/.bashrc     # Reload environment"
    echo "  ./check-env.sh       # Check again"
fi
