# NextUI Documentation

## Overview

NextUI is a high-performance custom firmware for portable retro gaming devices, primarily targeting the TrimUI family (Brick/Smart Pro). Built on MinUI foundation with a completely rebuilt emulation engine, NextUI delivers modern user experience with low-level optimizations.

## Key Features

- **Ultra-low latency (~20ms)** through advanced threading architecture
- **Dynamic CPU scaling** for optimal power management  
- **Multi-threaded rendering** with OpenGL ES shaders
- **Game time tracking** with SQLite database
- **WiFi integration** with NTP time sync
- **RGB LED control** with customizable patterns
- **PAK system** for modular emulator packages

## System Architecture

NextUI consists of several core components:

- **NextUI** - Main user interface (C + SDL2 + OpenGL, ~2800 LOC)
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

| Platform | Status | Description |
|----------|--------|-------------|
| **tg5040** | ✅ Primary | TrimUI Smart Pro/Brick |
| **desktop** | 🟡 Development | Testing and development only |

## Quick Links

- [Architecture Overview](architecture.md) - System design and component interaction
- [Module Documentation](modules.md) - Detailed module descriptions
- [API Reference](api-reference.md) - Public function documentation
- [Memory Map](memory-map.md) - Firmware memory layout
- [Interrupts](interrupts.md) - Interrupt handling
- [Boot Process](boot-process.md) - System initialization
- [Hardware Abstraction](hardware-abstraction.md) - HAL description
- [Error Handling](error-handling.md) - Error management strategies

## Build Instructions

### Prerequisites
- Docker (for cross-compilation)
- Make
- Git

### Quick Build
```bash
# Clone repository
git clone https://github.com/NextUI/NextUI.git
cd NextUI

# Build for desktop (testing)
make PLATFORM=desktop

# Build for TrimUI hardware
make PLATFORM=tg5040

# Build with cores
make PLATFORM=tg5040 CORES=essential
```

## Installation

1. Download latest release from [GitHub Releases](https://github.com/NextUI/NextUI/releases)
2. Format SD card as FAT32
3. Extract release archive to SD card root
4. Insert SD card and power on device

## Contributing

See our contributing guidelines and technical documentation for development setup and coding standards.

## License

NextUI is released under the MIT License. See LICENSE file for details.
