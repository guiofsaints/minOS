# minOS Documentation

## minOS consists of several core components:

- **minOS** - Main user interface (C + SDL2 + OpenGL, ~2800 LOC)view

minOS is a high-performance custom firmware for portable retro gaming devices, primarily targeting the TrimUI family (Brick/Smart Pro). Built on MinUI foundation with a completely rebuilt emulation engine, minOS delivers modern user experience with low-level optimizations.

This is a fork/evolution of the MinUI project, enhanced with advanced features for better performance and user experience.

## Key Features

- **Ultra-low latency (~20ms)** through advanced threading architecture
- **Dynamic CPU scaling** for optimal power management  
- **Multi-threaded rendering** with OpenGL ES shaders
- **Game time tracking** with SQLite database
- **WiFi integration** with NTP time sync
- **RGB LED control** with customizable patterns
- **PAK system** for modular emulator packages

### Performance Optimizations

- **6+ worker threads** for parallel processing
- **Background loading** of thumbnails and metadata
- **Hardware-accelerated graphics** with multi-pass shaders
- **High-quality audio resampling** with libsamplerate
- **Memory-optimized** resource management
- **Platform-specific optimizations** for each target device

## System Architecture

minOS consists of several core components:

- **minOS** - Main user interface (C + SDL2 + OpenGL, ~2800 LOC)
- **MinArch** - Emulation engine with libretro integration (~7100 LOC)
- **Settings** - Configuration system (C++ with UI components)
- **Common API** - Shared libraries and hardware abstraction
- **Platform Layer** - Hardware-specific implementations

## Technologies Used

- **Languages**: C (90%), C++ (8%), Shell (2%)
- **Graphics**: SDL2, OpenGL ES 2.0/3.0, multi-pass shaders
- **Audio**: libsamplerate for high-quality resampling
- **Threading**: pthreads + SDL threads (6+ worker threads)
- **Database**: SQLite3 for game time and battery tracking
- **Build System**: Docker-based cross-compilation

## Supported Platforms

| Platform | Status | Description | Devices |
|----------|--------|-------------|---------|
| **tg5040** | ✅ Primary | TrimUI Smart Pro/Brick | TrimUI Smart Pro, TrimUI Brick |
| **desktop** | 🟡 Development | Testing and development only | Linux, macOS, Windows (WSL) |

### System Requirements

**For TrimUI Devices:**
- TrimUI Smart Pro or TrimUI Brick
- MicroSD card (Class 10 or better recommended)
- FAT32 file system

**For Development:**
- Docker installed and running
- Git
- Make (GNU Make 4.0+)
- Linux, macOS, or Windows with WSL

### Emulator Core Status

**✅ Stable Cores:**
- `fceumm` (Nintendo/Famicom)
- `gambatte` (Game Boy/Game Boy Color)
- `mgba` / `gpsp` (Game Boy Advance)
- `picodrive` (Sega Genesis/Mega Drive)
- `snes9x` (Super Nintendo)
- `pcsx_rearmed` (PlayStation 1)

**🟡 Additional Cores:** Available in EXTRAS package with varying compatibility

## Documentation

### 📚 **Complete Documentation Suite**

**Core Architecture & Design:**
- [📋 Architecture Overview](docs/architecture.md) - System design, threading model, and component interaction
- [🔧 Module Documentation](docs/modules.md) - Detailed breakdown of all system modules and dependencies
- [🔌 Hardware Abstraction](docs/hardware-abstraction.md) - HAL design and platform abstraction layer
- [🚀 Boot Process](docs/boot-process.md) - Step-by-step system initialization and startup sequence

**Development & Technical Reference:**
- [📖 API Reference](docs/api-reference.md) - Complete public function documentation with examples
- [💾 Memory Map](docs/memory-map.md) - Firmware memory layout and allocation strategies
- [⚡ Interrupts](docs/interrupts.md) - Interrupt handling, signals, and hardware events
- [❌ Error Handling](docs/error-handling.md) - Error codes, logging system, and recovery mechanisms

**Build & Development:**
- [🛠️ Build System Guide](docs/build.md) - Comprehensive build documentation with Docker toolchain
- [⚡ Quick Build Guide](docs/build-quick.md) - Fast build commands and essential cores
- [🎨 Assets & Customization Map](docs/assets-map.md) - Complete guide for rebranding and customization

**PAK System:**
- [📦 PAK Documentation](docs/PAKS.md) - Emulator PAK system, creation, and integration guide

### 🎯 **Quick Navigation**

| Topic | Documentation | Description |
|-------|---------------|-------------|
| **Getting Started** | [build-quick.md](docs/build-quick.md) | Fast build and essential commands |
| **System Design** | [architecture.md](docs/architecture.md) | Threading, HAL, component design |
| **Development** | [api-reference.md](docs/api-reference.md) | Function reference and examples |
| **Customization** | [assets-map.md](docs/assets-map.md) | Branding and rebranding guide |
| **Hardware** | [hardware-abstraction.md](docs/hardware-abstraction.md) | Platform abstraction layer |
| **Troubleshooting** | [error-handling.md](docs/error-handling.md) | Error codes and debugging |

## Build Instructions

### Prerequisites
- Docker (for cross-compilation)
- Make
- Git

### Quick Build
```bash
# Clone repository
git clone git@github.com:guiofsaints/minOS.git
cd minOS

# Build for desktop (testing)
make build PLATFORM=desktop

# Build for TrimUI hardware
make build PLATFORM=tg5040

# Build with cores
make build-cores PLATFORM=tg5040
```

### Advanced Build Options

```bash
# Interactive Docker shell for development
make shell PLATFORM=tg5040

# Build specific core
make build-core PLATFORM=tg5040 CORE=fceumm

# Complete system build
make system PLATFORM=tg5040

# Build all platforms
make all

# Clean build
make clean PLATFORM=tg5040
```

For complete build documentation, see [Build Guide](docs/build.md) and [Quick Build Guide](docs/build-quick.md).

### Common Build Issues

| Issue | Solution |
|-------|----------|
| Docker permission errors | Ensure Docker is running and user has permissions |
| Core build failures | Some cores may not be available, this is normal |
| Git ownership errors | Fixed automatically in current build system |
| Missing dependencies | Use Docker environment which includes all dependencies |

### Platform-Specific Notes

- **tg5040**: Primary target platform (TrimUI Smart Pro/Brick)
- **desktop**: Development and testing only, not for actual device use

## Installation

### From Releases

1. Download latest release from [GitHub Releases](https://github.com/guiofsaints/minOS/releases)
   - `minOS-YYYYMMDD-X-base.zip` - Core system files
   - `minOS-YYYYMMDD-X-extras.zip` - Additional tools and emulators 
   - `minOS-YYYYMMDD-X-all.zip` - Complete package (base + extras)

2. Format SD card as FAT32
3. Extract release archive to SD card root
4. Insert SD card and power on device

### From Source

After building (see Build Instructions above), the release files will be created in the `releases/` directory.

### File Structure

```
SD Card Root/
├── .system/           # minOS system files (hidden)
├── Bios/             # BIOS files for emulators
├── Cheats/           # Cheat files
├── Emus/             # Emulator PAK files
├── Roms/             # ROM files organized by system
├── Saves/            # Save files and save states
├── Shaders/          # Graphics shaders
└── Tools/            # Utility PAK files
```

## Contributing

See our contributing guidelines and technical documentation for development setup and coding standards. 

For development, use the provided Docker environment and follow the coding standards outlined in the documentation files.

### Development Workflow

1. **Setup Development Environment:**
   ```bash
   git clone git@github.com:guiofsaints/minOS.git
   cd minOS
   make shell PLATFORM=tg5040  # Enter Docker development shell
   ```

2. **Build and Test:**
   ```bash
   make build PLATFORM=desktop    # Test on desktop first
   make build PLATFORM=tg5040     # Build for target device
   ```

3. **Code Structure:**
   - `workspace/all/` - Cross-platform components
   - `workspace/tg5040/` - TrimUI-specific code
   - `workspace/desktop/` - Development platform
   - `docs/` - Comprehensive documentation

### Key Development Files

- **minOS Main UI:** `workspace/all/minos/minos.c` (~2800 LOC)
- **MinArch Engine:** `workspace/all/minarch/minarch.c` (~7100 LOC)  
- **Settings System:** `workspace/all/settings/settings.cpp`
- **Platform Abstraction:** `workspace/tg5040/platform/platform.c`
- **Common APIs:** `workspace/all/common/`

## Repository

This project is hosted at: https://github.com/guiofsaints/minOS

## License

minOS is released under the MIT License. See LICENSE file for details.
