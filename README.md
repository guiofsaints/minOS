# 🎮 NextUI - High-Performance Retro Gaming CFW

<div align="center">

![NextUI Logo](github/logo.png)

**Modern custom firmware for portable retro gaming devices**  
*Built on MinUI foundation with completely rebuilt emulation engine*

[![Build Status](https://img.shields.io/github/actions/workflow/status/NextUI/NextUI/build.yml?branch=main)](https://github.com/NextUI/NextUI/actions)
[![Release](https://img.shields.io/github/v/release/NextUI/NextUI)](https://github.com/NextUI/NextUI/releases)
[![Platform](https://img.shields.io/badge/Platform-TrimUI%20Brick%2FSmart%20Pro-blue)](https://github.com/NextUI/NextUI)
[![License](https://img.shields.io/github/license/NextUI/NextUI)](LICENSE)

[📥 Download](https://github.com/NextUI/NextUI/releases) • [📖 Documentation](DOCS.md) • [💬 Discord](https://discord.gg/nextui) • [🌐 Website](https://nextui.loveretro.games)

</div>

---

## ✨ Features

### 🚀 **Performance**
- **Ultra-low latency** (~20ms) through advanced threading architecture
- **Dynamic CPU scaling** for optimal power management
- **High-quality audio resampling** with libsamplerate
- **Multi-threaded rendering** with OpenGL ES shaders

### 🎨 **Modern Interface**
- **Game Switcher** - Console-style quick game switching
- **Smooth animations** with 60fps UI transitions
- **Custom themes** and color schemes
- **Background art** automatic loading per game/folder
- **Multi-language support** including CJK fonts

### 🔧 **Advanced Features**
- **WiFi integration** with NTP time sync
- **RGB LED control** with customizable patterns
- **Game time tracking** with SQLite database
- **Battery monitoring** with usage statistics
- **Vibration feedback** support
- **Screenshot system** with automatic capture

### 🎮 **Gaming**
- **All libretro cores** supported with enhanced integration
- **Multi-disc support** via M3U playlists
- **Save states** with quicksave/auto-resume
- **Shader support** with multi-pass rendering
- **Per-core configuration** with live preview
- **Cheat code support** organized by system

### 🔌 **Extensibility**
- **PAK system** - Modular emulator packages
- **Community cores** easy installation
- **Custom tools** integration
- **Hardware abstraction** for multi-device support

---

## 🎯 Supported Devices

### ✅ **Active Support**
| Device | Platform | Status | Performance |
|--------|----------|--------|-------------|
| **TrimUI Smart Pro** | `tg5040` | 🟢 Primary | Excellent |
| **TrimUI Brick** | `tg5040` | 🟢 Primary | Excellent |
| **Desktop** | `desktop` | 🟡 Development | Testing only |

---

## 🚀 Quick Start

### Prerequisites
- Supported TrimUI device (Smart Pro or Brick)
- MicroSD card (16GB+ recommended)
- Windows/macOS/Linux computer for setup

### Installation

1. **Download** latest release from [Releases](https://github.com/NextUI/NextUI/releases)
2. **Extract** `NextUI-YYYYMMDD-X-all.zip`
3. **Format** SD card as FAT32
4. **Copy** all contents to SD card root
5. **Insert** SD card and boot device

### First Boot
- Device will auto-detect and configure hardware
- WiFi setup available in Settings menu
- Place ROMs in appropriate `/Roms/{System}/` folders
- Enjoy! 🎮

---

## 🏗️ Development

### Quick Development Setup

```bash
# Clone repository
git clone https://github.com/NextUI/NextUI.git
cd NextUI

# Start development environment
docker-compose up -d

# Build for desktop (testing)
make PLATFORM=desktop

# Build for TrimUI hardware
make PLATFORM=tg5040

# Clean builds
make clean PLATFORM=tg5040
```

### Architecture Overview

```
NextUI/
├── workspace/              # Source code
│   ├── all/               # Cross-platform components
│   │   ├── nextui/       # UI layer (~2800 LOC)
│   │   ├── minarch/      # Emulation engine (~7100 LOC)
│   │   ├── settings/     # Configuration system
│   │   └── common/       # Shared libraries
│   ├── desktop/          # Development platform
│   └── tg5040/           # Hardware-specific code
├── skeleton/             # File system templates
├── toolchains/           # Cross-compilation tools
└── releases/             # Built packages
```

### Key Technologies
- **Languages**: C (90%), C++ (8%), Shell (2%)
- **Graphics**: SDL2, OpenGL ES 2.0/3.0
- **Audio**: libsamplerate, SDL2_mixer
- **Threading**: pthreads + SDL threads
- **Database**: SQLite3 for tracking
- **Build**: Docker + hierarchical makefiles

---

## 📦 PAK System

NextUI uses a modular **PAK system** for emulators and tools:

### PAK Types
1. **Core Reuse** - Uses included libretro cores
2. **Bundled Core** - Includes custom libretro core
3. **Standalone** - External emulator (limited integration)

### Creating a PAK

```bash
# PAK structure
MyEmulator.pak/
├── launch.sh           # Entry point (required)
├── default.cfg         # Default settings (optional)
├── core_libretro.so    # Custom core (optional)
└── assets/             # Additional resources
```

```bash
#!/bin/sh
# launch.sh template
EMU_EXE=my_core
EMU_TAG=$(basename "$(dirname "$0")" .pak)
ROM="$1"

# Standard boilerplate
mkdir -p "$BIOS_PATH/$EMU_TAG"
mkdir -p "$SAVES_PATH/$EMU_TAG"
HOME="$USERDATA_PATH"
cd "$HOME"

# Launch via minarch
minarch.elf "$CORES_PATH/${EMU_EXE}_libretro.so" "$ROM" &> "$LOGS_PATH/$EMU_TAG.txt"
```

See [PAKS.md](PAKS.md) for complete documentation.

---

## 🤝 Contributing

### Ways to Contribute
- 🐛 **Bug reports** via GitHub Issues
- 💡 **Feature requests** and suggestions
- 🔧 **Code contributions** via Pull Requests
- 📦 **PAK development** for new emulators
- 📖 **Documentation** improvements
- 🌍 **Translations** for UI

### Development Guidelines
1. Follow [coding standards](copilot-instructions.md)
2. Test on actual hardware when possible
3. Update documentation for user-facing changes
4. Use descriptive commit messages
5. Ensure backwards compatibility

### Setting up Development Environment
```bash
# Fork and clone your fork
git clone https://github.com/yourusername/NextUI.git
cd NextUI

# Create feature branch
git checkout -b feature/amazing-feature

# Make changes and test
make PLATFORM=desktop

# Commit and push
git commit -m "Add amazing feature"
git push origin feature/amazing-feature

# Create Pull Request on GitHub
```

---

## 📖 Documentation

- **[Build Guide](BUILD.md)** - Complete build process documentation
- **[Quick Build](QUICK_BUILD.md)** - TL;DR build commands
- **[Developer Docs](DOCS.md)** - Technical documentation
- **[PAK System](PAKS.md)** - Emulator package system

---

## 🙏 Acknowledgments

- **MinUI Team** - Foundation and inspiration
- **libretro Team** - Emulation cores ecosystem
- **TrimUI Community** - Hardware support and testing
- **Contributors** - Everyone who makes NextUI better

### Built With
- [SDL2](https://www.libsdl.org/) - Graphics and input
- [libretro](https://www.libretro.com/) - Emulation cores
- [libsamplerate](https://github.com/libsndfile/libsamplerate) - Audio resampling
- [SQLite](https://www.sqlite.org/) - Embedded database
- [OpenGL ES](https://www.khronos.org/opengles/) - Hardware acceleration

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🌟 Star History

[![Star History Chart](https://api.star-history.com/svg?repos=NextUI/NextUI&type=Date)](https://star-history.com/#NextUI/NextUI&Date)

---

<div align="center">

**Made with ❤️ by the NextUI Team**

[⬆️ Back to Top](#-nextui---high-performance-retro-gaming-cfw)

</div>