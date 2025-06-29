# minOS Build System Documentation

## Overview

minOS uses a sophisticated build system based on Docker containerization and hierarchical makefiles to support cross-compilation for embedded ARM devices while maintaining a native development environment.

## Build Architecture

### Build System Components

```
minOS Build System
├── makefile                    # Main orchestration makefile
├── makefile.native            # Native desktop builds
├── makefile.toolchain         # Docker cross-compilation
├── docker-compose.yml         # Development environment
├── toolchains/                # Platform-specific toolchains
│   └── tg5040-toolchain/      # TrimUI ARM64 toolchain
├── workspace/                 # Source code and builds
│   ├── all/                   # Cross-platform components
│   │   ├── minos/           # Main UI (~2800 LOC)
│   │   ├── minarch/          # Emulation engine (~7100 LOC)
│   │   ├── settings/         # Configuration system (C++)
│   │   ├── common/           # Shared APIs and libraries
│   │   └── cores/            # Libretro emulator cores
│   ├── desktop/              # Desktop development platform
│   └── tg5040/               # TrimUI hardware platform
├── skeleton/                 # File system templates
├── build/                    # Temporary build artifacts
└── releases/                 # Final release packages (.zip)
```

### Platform Support Matrix

| Platform | Architecture | Status | Toolchain | Purpose |
|----------|-------------|--------|-----------|---------|
| **tg5040** | ARM64 | ✅ Primary | Docker GCC 11 | TrimUI Smart Pro/Brick |
| **desktop** | x86_64 | 🟡 Development | Native GCC/Clang | Testing & Development |

## Quick Start Guide

### Prerequisites

- **Docker**: For cross-compilation
- **Make**: GNU Make 4.0+
- **Git**: For source control
- **Linux/macOS/WSL**: Development environment

### Rapid Build Commands

```bash
# 🚀 One-command full build (recommended)
make full-build PLATFORM=tg5040

# 📦 System-only build (no cores)
make tg5040

# 🎮 Essential cores only
make build-essential-cores PLATFORM=tg5040

# 🔧 Individual core build
make build-core PLATFORM=tg5040 CORE=fceumm

# 🧹 Clean builds
make clean PLATFORM=tg5040

```

### Step-by-Step Build Process

```bash
# 1. Setup build environment
make setup

# 2. Build core system components
make build PLATFORM=tg5040

# 3. Build essential emulator cores
make build-essential-cores PLATFORM=tg5040

# 4. Install system files
make system PLATFORM=tg5040

# 5. Build additional cores (optional)
make cores PLATFORM=tg5040

# 6. Package and finalize
make special && make package && make done
```

## Build Targets Explained

### Core Build Targets

#### `make setup`
Initializes build environment:
- Removes previous build artifacts
- Copies skeleton structure to build directory
- Generates build hash from git commit
- Prepares README templates

#### `make build PLATFORM={platform}`
Compiles core system components:
- **minos.elf** - Main user interface (~2800 LOC)
- **minarch.elf** - Emulation engine (~7100 LOC)
- **settings.elf** - Configuration system
- **libmsettings.so** - Hardware settings library
- System utilities (clock, battery, gametime, etc.)

#### `make system PLATFORM={platform}`
Installs compiled binaries and resources:
- Copies executables to build directory
- Installs shared libraries
- Sets up PAK system structure
- Configures platform-specific files

### Core Management Targets

#### `make build-essential-cores PLATFORM={platform}`
Builds stable, well-tested cores:
- fceumm (Nintendo/Famicom)
- gambatte (Game Boy/Game Boy Color)
- gpsp (Game Boy Advance - ARM optimized)
- mgba (Game Boy Advance - accuracy focused)
- picodrive (Sega Genesis/Master System)
- snes9x (Super Nintendo)
- pcsx_rearmed (PlayStation 1)

#### `make cores PLATFORM={platform}`
Builds all available cores including experimental ones.

#### `make build-core PLATFORM={platform} CORE={core_name}`
Builds a specific libretro core:
```bash
# Examples
make build-core PLATFORM=tg5040 CORE=fceumm
make build-core PLATFORM=tg5040 CORE=gambatte
```

### Packaging Targets

#### `make package`
Creates release packages:
- **minOS-YYYYMMDD-X-base.zip** - Minimal system
- **minOS-YYYYMMDD-X-extras.zip** - Additional emulators
- **minOS-YYYYMMDD-X-all.zip** - Complete package

## Docker Toolchain System

### Toolchain Configuration

```dockerfile
# toolchains/tg5040-toolchain/Dockerfile
FROM ubuntu:20.04

# Install cross-compilation tools
RUN apt-get update && apt-get install -y \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    pkg-config \
    make \
    git \
    python3

# Set up cross-compilation environment
ENV CC=aarch64-linux-gnu-gcc
ENV CXX=aarch64-linux-gnu-g++
ENV AR=aarch64-linux-gnu-ar
ENV STRIP=aarch64-linux-gnu-strip
ENV PKG_CONFIG_PATH=/usr/lib/aarch64-linux-gnu/pkgconfig
```

### Docker Build Process

```bash
# Build toolchain container
docker build -t minos-tg5040-toolchain ./toolchains/tg5040-toolchain/

# Run build in container
docker run --rm -v $(PWD):/workspace minos-tg5040-toolchain \
    make -C /workspace build PLATFORM=tg5040
```

### Container Development Environment

```bash
# Interactive development shell
make shell PLATFORM=tg5040

# Inside container:
cd /workspace
make build PLATFORM=tg5040
```

## Compilation Configuration

### Platform-Specific Compiler Flags

#### TrimUI (tg5040) Configuration
```makefile
# makefile.toolchain
ARCH = -march=armv8-a -mtune=cortex-a55
CFLAGS += $(ARCH) -fomit-frame-pointer -O3
CFLAGS += -DPLATFORM=\"tg5040\" -std=gnu99
CFLAGS += -ffast-math -funroll-loops

# Platform-specific linking
LDFLAGS += -lSDL2 -lSDL2_image -lSDL2_ttf
LDFLAGS += -lGLESv2 -lEGL
LDFLAGS += -lpthread -lm -ldl
```

#### Desktop Configuration
```makefile
# makefile.native
CFLAGS += -DPLATFORM=\"desktop\" -std=gnu99
CFLAGS += -O2 -g -Wall -Wextra

# Desktop libraries
LDFLAGS += -lSDL2 -lSDL2_image -lSDL2_ttf
LDFLAGS += -lGL -lGLU
LDFLAGS += -lpthread -lm -ldl
```

### Optimization Levels

| Build Type | Optimization | Debug Info | Purpose |
|------------|-------------|------------|---------|
| **Release** | -O3 -ffast-math | No | Production builds |
| **Debug** | -O0 -g | Yes | Development |
| **Profile** | -O2 -g -pg | Yes | Performance analysis |

## Core Build System

### Libretro Core Integration

```makefile
# workspace/all/cores/makefile
# Core-specific optimizations
ifeq ($(CORE),gpsp)
    CFLAGS += -DARM_ARCH -O3 -ffast-math
    LDFLAGS += -lz
else ifeq ($(CORE),pcsx_rearmed)
    CFLAGS += -DHAVE_DYNAREC -DNEON_BUILD
    LDFLAGS += -lz -lpthread
else ifeq ($(CORE),snes9x)
    CFLAGS += -DHAVE_STRINGS_H -DHAVE_STDINT_H
endif

# Universal core build
$(CORE)_libretro.so:
	cd $(CORE) && $(MAKE) platform=unix CC=$(CC) CXX=$(CXX)
	cp $(CORE)/$(CORE)_libretro.so ../../../build/$(PLATFORM)/cores/
```

### Core Status Verification

```bash
# Check core build status
make cores-json PLATFORM=tg5040

# Verify specific core
cd workspace/tg5040/cores
make status-fceumm

# Core availability matrix
make core-matrix PLATFORM=tg5040
```

## Essential Cores Documentation

### Stable Cores (Tested & Optimized)

#### Nintendo Systems
- **fceumm** - Nintendo Entertainment System/Famicom
  - Cycle-accurate emulation
  - Excellent compatibility
  - Memory: ~2MB RAM usage

#### Game Boy Family
- **gambatte** - Game Boy/Game Boy Color
  - High accuracy emulation
  - Real-time clock support
  - Memory: ~1MB RAM usage

#### Game Boy Advance
- **gpsp** - ARM Assembly optimized
  - Fastest GBA emulation
  - Dynarec for ARM platforms
  - Memory: ~3MB RAM usage
  
- **mgba** - Accuracy focused
  - Cycle-accurate timing
  - Advanced debugging features
  - Memory: ~4MB RAM usage

#### Sega Systems
- **picodrive** - Genesis/Master System/32X
  - Multi-system support
  - Optimized assembly cores
  - Memory: ~2MB RAM usage

#### 16-bit Nintendo
- **snes9x** - Super Nintendo Entertainment System
  - Excellent game compatibility
  - Special chip support (SuperFX, etc.)
  - Memory: ~4MB RAM usage

#### PlayStation
- **pcsx_rearmed** - PlayStation 1
  - Dynamic recompiler
  - Hardware-accelerated rendering
  - Memory: ~8MB RAM usage

### Experimental Cores

Additional cores available but with varying compatibility:
- mednafen_pce_fast (PC Engine)
- mednafen_wswan (WonderSwan)
- prosystem (Atari 7800)
- stella (Atari 2600)

## Build Commands Reference

| Command | Description |
|---------|-------------|
| `make full-build PLATFORM=tg5040` | Complete automated build |
| `make tg5040` | System build without cores |
| `make build-essential-cores PLATFORM=tg5040` | Stable cores only |
| `make build-core PLATFORM=tg5040 CORE=fceumm` | Specific core |
| `make shell PLATFORM=tg5040` | Interactive Docker shell |
| `make clean PLATFORM=tg5040` | Clean build artifacts |

## Build Optimization

### Parallel Compilation

```bash
# Use all CPU cores for compilation
make -j$(nproc) build PLATFORM=tg5040

# Specific thread count
make -j8 build PLATFORM=tg5040
```

### Incremental Builds

```bash
# Build only changed components
make incremental PLATFORM=tg5040

# Force rebuild specific module
make rebuild-minos PLATFORM=tg5040
```

## Troubleshooting

### Common Build Issues

| Error | Solution |
|-------|---------|
| Git ownership error | Automatically handled by build system |
| Core not found | Normal, use conditional checks |
| Missing dependencies | Update toolchain or install packages |
| Memory issues | Reduce parallelization or increase swap |

### Debug Build Options

```bash
# Verbose build output
make PLATFORM=tg5040 MAKEFLAGS= V=1

# Debug symbols enabled
make debug-build PLATFORM=tg5040

# Address sanitizer build
make asan-build PLATFORM=tg5040
```

## Output Structure

```
releases/
├── minOS-YYYYMMDD-X-base.zip    # Minimal system
├── minOS-YYYYMMDD-X-extras.zip  # Additional emulators
└── minOS-YYYYMMDD-X-all.zip     # Complete package
```

## Debug Commands

```bash
# View available cores
make cores-json PLATFORM=tg5040

# Check specific core status
cd workspace/tg5040/cores && make status-fceumm

# Verbose build output
make PLATFORM=tg5040 MAKEFLAGS=

## Complete Build (Recommended)
```bash
# Complete build with essential cores
make full-build PLATFORM=tg5040

# Or step by step:
make setup
make build-all-safe PLATFORM=tg5040
make special
make package
make done
```

### System-Only Build (Without Cores)
```bash
make tg5040
```

### Specific Core Build
```bash
# All cores (may fail on some)
make build-cores PLATFORM=tg5040

# Only stable cores
make build-essential-cores PLATFORM=tg5040

# Individual core
make build-core PLATFORM=tg5040 CORE=fceumm
```

### Development Build
```bash
# Interactive shell in Docker container
make shell PLATFORM=tg5040

# Native build for development
make desktop
```

## Build Configuration

### Environment Variables
```makefile
BUILD_HASH    = $(git rev-parse --short HEAD)
BUILD_BRANCH  = $(git rev-parse --abbrev-ref HEAD)
RELEASE_TIME  = $(date +%Y%m%d)
PLATFORM      = tg5040 | desktop
COMPILE_CORES = true | false
```

### Compilation Flags (tg5040)
```bash
CFLAGS = -march=armv8-a+simd -mtune=cortex-a53 -flto -O3 -Ofast
CFLAGS += -fomit-frame-pointer -ffast-math -funroll-loops
CFLAGS += -finline-functions -fno-strict-aliasing
CFLAGS += -DUSE_SDL2 -DUSE_GLES -DGL_GLEXT_PROTOTYPES
```

## Troubleshooting

### Common Errors

#### 1. Git ownership in Docker
```
fatal: detected dubious ownership in repository
```
**Solution**: Automatically resolved with `git config --global --add safe.directory`

#### 2. Cores not found
```
Warning: fceumm_libretro.so not found, skipping
```
**Solution**: Normal if cores were not compiled. Use conditional checks.

### Debug and Logs

```bash
# Verbose build
make PLATFORM=tg5040 MAKEFLAGS=

# Check available cores
make cores-json PLATFORM=tg5040

# Status of specific core
cd workspace/tg5040/cores && make status-fceumm
```

## Threading and Performance

### Multi-thread Architecture
- `main_ui_thread`: Main interface
- `bg_load_thread`: Background loading
- `anim_thread`: Animation worker
- `audio_thread`: Audio processing
- `cpu_monitor_thread`: Performance monitoring

### Optimizations
- **LTO (Link Time Optimization)**: `-flto`
- **CPU specific**: `-march=armv8-a+simd -mtune=cortex-a53`
- **Optimized math**: `-ffast-math -funroll-loops`
- **Threading**: pthreads + SDL threads (6+ workers)

## Final Structure

### BASE/ (Essential system)
```
BASE/
├── Bios/          # System BIOS files
├── Roms/          # ROMs organized by system
├── Saves/         # Save games
├── Shaders/       # Video shaders
├── trimui/        # TrimUI specific installer
├── em_ui.sh       # Initialization script
├── minOS.zip      # Main payload
└── README.txt     # Instructions
```

### EXTRAS/ (Additional emulators and tools)
```
EXTRAS/
├── Emus/          # Extra cores by system
├── Tools/         # Utility tools
├── Overlays/      # Graphic overlays
└── README.txt     # Instructions
```

## Dependencies

### Host System
- Docker (for cross-compilation)
- Git
- Make
- zip/zipmerge

### Docker Container
- GCC aarch64 cross-compiler
- SDL2, SDL2_image, SDL2_ttf
- OpenGL ES 2.0/3.0
- pkg-config
- libretro development headers

## Releases

### Versioning
```
minOS-YYYYMMDD[-branch]-increment
Example: minOS-20250628-main-1
```

### Release Types
- **base.zip**: Main system (minimal functional)
- **extras.zip**: Extra emulators and tools
- **all.zip**: Complete package (base + extras)
