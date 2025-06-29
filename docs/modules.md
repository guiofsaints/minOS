# NextUI Module Documentation

## Core Modules

### NextUI (Main UI Module)
**Location**: `workspace/all/nextui/`  
**Language**: C  
**LOC**: ~2800  
**Purpose**: Primary user interface and menu system

#### Key Responsibilities
- Menu navigation and game selection
- File browser and ROM management
- Settings interface integration
- Theme and visual customization
- Input handling and shortcuts
- Game switcher functionality

#### Key Files
- `nextui.c` - Main UI logic and event loop
- `nextui.h` - UI structures and definitions

#### Threading
- Runs on main UI thread
- Coordinates with background workers for ROM loading
- Handles input events and display updates

---

### MinArch (Emulation Engine)
**Location**: `workspace/all/minarch/`  
**Language**: C  
**LOC**: ~7100  
**Purpose**: Core emulation engine with libretro integration

#### Key Responsibilities
- Libretro core management and loading
- Audio/video processing and output
- Save state management
- Input mapping and processing
- Shader system integration
- Performance monitoring and scaling

#### Key Files
- `minarch.c` - Main emulation loop and core management
- `minarch.h` - Core structures and API definitions

#### Threading
- Dedicated emulation thread
- Audio processing thread
- Background screenshot thread
- CPU monitoring thread

#### Core Integration
```c
// Libretro core loading
int Core_open(char* path, char* name) {
    handle = dlopen(path, RTLD_LAZY);
    retro_init = dlsym(handle, "retro_init");
    retro_run = dlsym(handle, "retro_run");
    // ... load all required symbols
    return 0;
}
```

---

### Settings System
**Location**: `workspace/all/settings/`  
**Language**: C++  
**LOC**: ~800  
**Purpose**: Configuration management and settings UI

#### Key Responsibilities
- Hardware settings (brightness, volume, CPU speed)
- Emulator configuration per core
- WiFi and network settings
- LED and visual effects configuration
- Input and control mapping
- System maintenance tools

#### Key Files
- `settings.cpp` - Main settings application
- `settings.h` - Settings structures

#### Configuration Categories
1. **System Settings**
   - Display brightness and color temperature
   - Audio volume and quality
   - Power management options

2. **Hardware Settings**
   - CPU frequency profiles
   - LED control and patterns
   - Vibration feedback settings

3. **Network Settings**
   - WiFi configuration
   - Time synchronization
   - Remote services

---

### Common API Library
**Location**: `workspace/all/common/`  
**Language**: C  
**LOC**: ~3200  
**Purpose**: Shared functionality and hardware abstraction

#### Key Files
- `api.h` - Main API definitions and constants
- `api.c` - Core API implementations
- `defines.h` - System-wide constants and macros
- `config.h` - Configuration structures
- `utils.h` - Utility functions
- `scaler.h` - Graphics scaling functions
- `sdl.h` - SDL wrapper and extensions

#### Core APIs
```c
// Graphics API
SDL_Surface* GFX_init(int mode);
void GFX_flip(SDL_Surface* screen, int sync);
void GFX_clear(SDL_Surface* screen);

// Input API
void PAD_init(void);
void PAD_poll(void);
int PAD_justPressed(int button);

// Power Management API
void PWR_init(void);
void PWR_update(int* dirty, int* sleeping, int* poweroff, int* quit);
void PWR_powerOff(void);
```

---

### Platform Abstraction Layer
**Location**: `workspace/{platform}/platform/`  
**Language**: C  
**LOC**: ~3400 per platform  
**Purpose**: Hardware-specific implementations

#### Platform Implementations

##### Desktop Platform (`workspace/desktop/platform/`)
- Development and testing environment
- SDL2-based graphics and input
- File system simulation
- Cross-platform compatibility layer

##### TrimUI Platform (`workspace/tg5040/platform/`)
- Hardware-specific GPIO control
- LED management (RGB and PWM)
- Power management integration
- WiFi stack integration
- Input daemon coordination

#### Key Platform Functions
```c
// Hardware abstraction interface
void PLAT_initInput(void);
void PLAT_quitInput(void);
SDL_Surface* PLAT_initVideo(void);
void PLAT_quitVideo(void);

// Power management
void PLAT_setCPUSpeed(int speed);
void PLAT_getBatteryStatus(int* is_charging, int* charge);
void PLAT_powerOff(void);

// Hardware features
void PLAT_setRumble(int strength);
void PLAT_setLED(int led, int color, int brightness);
```

---

## System Utilities

### Game Time Tracking
**Location**: `workspace/all/gametime/`, `workspace/all/libgametimedb/`  
**Purpose**: Track and analyze gaming sessions

#### Components
- `libgametimedb.so` - SQLite database interface
- `gametimectl.elf` - Command-line control utility
- Database schema for session tracking

#### Features
- Automatic session detection
- Per-game time tracking
- Historical analysis
- Export capabilities

---

### Battery Monitoring
**Location**: `workspace/all/battery/`, `workspace/all/libbatmondb/`  
**Purpose**: Battery health monitoring and statistics

#### Components
- `libbatmondb.so` - Battery database interface
- `batmon.elf` - Background monitoring daemon
- `battery.elf` - Battery status display

#### Monitoring
- Real-time voltage/current tracking
- Charging cycle analysis
- Health assessment
- Usage pattern analysis

---

### Clock System
**Location**: `workspace/all/clock/`  
**Purpose**: System time and timezone management

#### Features
- Real-time clock display
- Timezone configuration
- NTP synchronization support
- Stopwatch functionality

---

### LED Control System
**Location**: `workspace/all/ledcontrol/`  
**Purpose**: RGB LED management for TrimUI devices

#### Features
- RGB color control
- Brightness adjustment
- Pattern programming
- Event-based lighting

#### LED Configuration
```c
typedef struct {
    char name[64];
    char device[16];
    int max_brightness;
    int color_temp;
    uint32_t default_color;
    // ... additional fields
} LightSettings;
```

---

## System Services

### Input Monitor
**Location**: `workspace/tg5040/keymon/`  
**Purpose**: Global input monitoring and hotkey handling

#### Features
- System-wide hotkey detection
- Input event logging
- Power button handling
- Emergency shutdown sequences

---

### WiFi Manager
**Location**: `workspace/tg5040/wifimanager/`  
**Purpose**: WiFi connectivity management

#### Components
- WiFi interface abstraction
- WPA supplicant integration
- Network scanning and connection
- Status monitoring

#### WiFi API
```c
// WiFi management functions
void PLAT_wifiInit(void);
bool PLAT_wifiEnabled(void);
void PLAT_wifiEnable(bool on);
int PLAT_wifiScan(struct WIFI_network *networks, int max);
void PLAT_wifiConnect(const char *ssid, const char *password);
```

---

## Build System Modules

### Core Build System
**Location**: `workspace/all/cores/`  
**Purpose**: Libretro core compilation and integration

#### Supported Cores
- **fceumm** - Nintendo Entertainment System
- **gambatte** - Game Boy/Game Boy Color
- **gpsp** - Game Boy Advance (ARM assembly optimized)
- **mgba** - Game Boy Advance (accuracy focused)
- **picodrive** - Sega Genesis/Master System
- **snes9x** - Super Nintendo Entertainment System
- **pcsx_rearmed** - PlayStation 1

#### Build Configuration
```makefile
# Core-specific optimization
ifeq ($(CORE),gpsp)
    CFLAGS += -DARM_ARCH -O3 -ffast-math
else ifeq ($(CORE),pcsx_rearmed)
    CFLAGS += -DHAVE_DYNAREC -DNEON_BUILD
endif
```

---

## Inter-Module Communication

### Message System
- Event-driven architecture
- Thread-safe message queues
- Standardized message formats
- Error propagation

### Shared Memory
- Configuration sharing
- Cache coordination
- Performance data exchange
- Hardware state synchronization

### Database Integration
- SQLite for persistent data
- Transaction-based updates
- Cross-module data sharing
- Backup and recovery mechanisms

## Module Dependencies

```
NextUI
├── depends on: Common API, Platform Layer
├── communicates with: Settings, GameTime
└── coordinates: Background workers

MinArch  
├── depends on: Common API, Platform Layer, Cores
├── communicates with: Settings, Battery Monitor
└── manages: Audio/Video threads

Settings
├── depends on: Common API, Platform Layer
├── communicates with: NextUI, MinArch
└── modifies: System configuration

Platform Layer
├── depends on: Hardware drivers, Linux APIs
├── provides: Hardware abstraction
└── isolates: Hardware differences
```
