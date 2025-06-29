# minOS - Quick Build Guide

## 🚀 Quick Build (TL;DR)

```bash
# Complete recommended build
make full-build PLATFORM=tg5040

# Or step by step:
make setup
make build PLATFORM=tg5040
make build-essential-cores PLATFORM=tg5040  # Stable cores
make system PLATFORM=tg5040
make cores PLATFORM=tg5040
make special && make package && make done
```

## 📋 Essential Commands

| Command | Description |
|---------|-------------|
| `make full-build PLATFORM=tg5040` | Complete automated build |
| `make tg5040` | System build without cores |
| `make build-essential-cores PLATFORM=tg5040` | Stable cores only |
| `make build-core PLATFORM=tg5040 CORE=fceumm` | Specific core |
| `make shell PLATFORM=tg5040` | Interactive Docker shell |
| `make clean PLATFORM=tg5040` | Clean build |

## 🎮 Stable Cores

✅ **Working well:**
- `fceumm` (Nintendo/Famicom)
- `gambatte` (Game Boy/GBC)
- `gpsp` (Game Boy Advance)
- `mgba` (Game Boy Advance)
- `picodrive` (Sega Genesis/MD)
- `snes9x` (Super Nintendo)
- `pcsx_rearmed` (PlayStation 1)

## 🔧 Troubleshooting

| Error | Solution |
|-------|---------|
| Git ownership error | Already fixed automatically |
| Core not found | Normal, use conditional checks |

## 📁 Output Structure

```
releases/
├── minOS-YYYYMMDD-X-base.zip    # Minimal system
├── minOS-YYYYMMDD-X-extras.zip  # Extra emulators
└── minOS-YYYYMMDD-X-all.zip     # Complete package
```

## 🐛 Debug

```bash
# View available cores
make cores-json PLATFORM=tg5040

# Status of specific core
cd workspace/tg5040/cores && make status-fceumm

# Verbose build
make PLATFORM=tg5040 MAKEFLAGS=
```
