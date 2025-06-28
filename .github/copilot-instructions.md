# GitHub Copilot Instructions - NextUI Project

## 🎯 Project Overview

NextUI is a high-performance Custom Firmware (CFW) based on MinUI with a completely rebuilt emulation engine for portable retro gaming devices. It primarily targets the **TrimUI family** (Brick/Smart Pro) offering modern user experience with low-level optimizations.

### Key Technologies
- **Languages**: C (90%), C++ (8%), Shell (2%)
- **Graphics**: SDL2, OpenGL ES 2.0/3.0, multi-pass shaders
- **Audio**: libsamplerate for high-quality resampling
- **Threading**: pthreads + SDL threads (6+ worker threads)
- **Platform**: Linux embedded, cross-compilation via Docker
- **Build System**: Hierarchical makefiles + Docker toolchains

## 🏗️ Architecture Guidelines

### Component Structure
```
workspace/
├── all/                    # Cross-platform components
│   ├── nextui/            # UI layer (~2800 LOC)
│   ├── minarch/           # Emulation engine (~7100 LOC)
│   ├── settings/          # Configuration system (C++)
│   ├── common/            # Shared library & APIs
│   └── [utilities]/       # Single-responsibility modules
├── desktop/               # Development platform
└── tg5040/               # Hardware-specific (TrimUI)
```

### Design Patterns to Follow
- **HAL (Hardware Abstraction Layer)**: Use `platform.h` interface
- **Observer Pattern**: For configuration callbacks
- **Factory Pattern**: For resource management
- **Producer-Consumer**: For threading with SDL mutexes/conditions

## 🧵 Threading Architecture

### Main Threads
- `main_ui_thread` - Primary interface
- `bg_load_thread` - Background/thumbnail loading  
- `anim_thread` - Animation worker
- `audio_thread` - Audio processing/resampling
- `cpu_monitor_thread` - Performance monitoring

### Synchronization Patterns
```c
// Always use SDL synchronization primitives
static SDL_mutex* queueMutex = NULL;
static SDL_cond* queueCond = NULL;

// Producer-Consumer pattern
SDL_LockMutex(queueMutex);
// ... queue operations ...
SDL_CondSignal(queueCond);
SDL_UnlockMutex(queueMutex);
```

## 📋 Coding Standards

### Naming Conventions
```c
// Types: PascalCase
typedef struct ComponentName {
    int member_variable;        // snake_case for variables
    void (*callback_fn)(void);  // snake_case for functions
} ComponentName;

// Constants: UPPER_CASE
#define MAX_BUFFER_SIZE 1024
#define SCREEN_WIDTH 640

// Functions: Module prefix + action
int CFG_getValue(const char* key);
void GFX_renderSurface(SDL_Surface* surface);
bool PLAT_isFeatureSupported(feature_t feature);
```

### Error Handling
```c
// Use structured error codes
typedef enum {
    RESULT_SUCCESS = 0,
    RESULT_ERROR_INVALID_ARGUMENT = -1,
    RESULT_ERROR_OUT_OF_MEMORY = -2,
    RESULT_ERROR_FILE_NOT_FOUND = -3,
    // ... more specific errors
} ResultCode;

// Pattern for functions that can fail
ResultCode loadConfiguration(const char* config_path) {
    if (!config_path) {
        LOG_error("Invalid config path provided");
        return RESULT_ERROR_INVALID_ARGUMENT;
    }
    // ... implementation
    return RESULT_SUCCESS;
}
```

### Logging
```c
// Use hierarchical logging levels
#define LOG_trace(fmt, ...) LOG_write(LOG_LEVEL_TRACE, __FILE__, __LINE__, fmt, ##__VA_ARGS__)
#define LOG_debug(fmt, ...) LOG_write(LOG_LEVEL_DEBUG, __FILE__, __LINE__, fmt, ##__VA_ARGS__)
#define LOG_info(fmt, ...)  LOG_write(LOG_LEVEL_INFO, __FILE__, __LINE__, fmt, ##__VA_ARGS__)
#define LOG_warn(fmt, ...)  LOG_write(LOG_LEVEL_WARN, __FILE__, __LINE__, fmt, ##__VA_ARGS__)
#define LOG_error(fmt, ...) LOG_write(LOG_LEVEL_ERROR, __FILE__, __LINE__, fmt, ##__VA_ARGS__)
```

## 🎮 PAK System Development

### PAK Structure
```bash
# Standard PAK directory structure
EMULATOR.pak/
├── launch.sh              # Entry point (required)
├── default.cfg            # Default configuration (optional)
├── core_libretro.so       # Bundled core (optional)
└── assets/               # Additional resources (optional)
```

### launch.sh Template
```bash
#!/bin/sh
EMU_EXE=core_name           # Core name without _libretro.so
EMU_TAG=$(basename "$(dirname "$0")" .pak)
ROM="$1"

# Standard PAK boilerplate
mkdir -p "$BIOS_PATH/$EMU_TAG"
mkdir -p "$SAVES_PATH/$EMU_TAG" 
mkdir -p "$CHEATS_PATH/$EMU_TAG"
HOME="$USERDATA_PATH"
cd "$HOME"

# Launch via minarch
minarch.elf "$CORES_PATH/${EMU_EXE}_libretro.so" "$ROM" &> "$LOGS_PATH/$EMU_TAG.txt"
```

## 🔧 Platform Abstraction

### Hardware Interface
```c
// Always use platform abstraction
void PLAT_initInput(void);
void PLAT_quitInput(void);
SDL_Surface* PLAT_initVideo(void);
void PLAT_quitVideo(void);

// Hardware capability detection
typedef struct PLAT_Context {
    char device_name[64];
    char platform_name[32];
    struct {
        bool has_wifi;
        bool has_bluetooth;
        bool has_leds;
        bool has_vibration;
        bool has_battery;
    } capabilities;
} PLAT_Context;
```

## 📊 Database Integration

### SQLite Usage Patterns
```c
// GameTime tracking
typedef struct PlayActivity {
    ROM *rom;
    int play_count;
    int play_time_total;
    int play_time_average;
    char *first_played_at;
    char *last_played_at;
} PlayActivity;

// Configuration system
int GetInt(const char* key, int default_value);
void SetInt(const char* key, int value);
char* GetString(const char* key, char* buffer, size_t size, const char* default_value);
```

## 🎨 Graphics Programming

### SDL2 + OpenGL ES Pattern
```c
// Multi-layer rendering (5 layers)
static SDL_Surface* layers[5];
static GLuint layer_textures[5];

// Shader system
typedef struct Shader {
    GLuint shader_p;           // Shader program
    GLint u_FrameCount;        // Uniforms
    GLint u_OutputSize;
    GLint u_TextureSize;
    int scale;                 // Scaling factor
} Shader;

// Multi-pass rendering
void renderWithShaders(SDL_Surface* source) {
    GLuint currentTexture = sourceTexture;
    for (int pass = 0; pass < nrofshaders; pass++) {
        Shader* shader = shaders[pass];
        glUseProgram(shader->shader_p);
        // Set uniforms and render
        currentTexture = shader->texture;
    }
}
```

## 🔧 Build System

### Makefile Patterns
```makefile
# Platform detection
ifeq ($(PLATFORM),desktop)
    include makefile.native
else ifeq ($(PLATFORM),tg5040)
    include makefile.toolchain
endif

# Compiler flags
CFLAGS += $(ARCH) -fomit-frame-pointer
CFLAGS += $(INCDIR) -DPLATFORM=\"$(PLATFORM)\" -std=gnu99

# Platform-specific linking
ifeq ($(PLATFORM),desktop)
    LDFLAGS += -lSDL2 -lSDL2_image -lSDL2_ttf
else
    LDFLAGS += -lSDL2 -lSDL2_image -lSDL2_ttf -lGLESv2
endif
```

## 🚫 What NOT to Do

### Avoid These Patterns
- ❌ **Direct hardware access** without platform abstraction
- ❌ **Blocking operations** in main UI thread
- ❌ **Memory leaks** - always pair malloc/free
- ❌ **Hard-coded paths** - use defines from `defines.h`
- ❌ **Platform-specific code** outside platform layer
- ❌ **Synchronous file I/O** in UI thread
- ❌ **Magic numbers** - use named constants

### Legacy Code to Avoid
- ❌ SDL 1.2 patterns (use SDL2 exclusively for new code)
- ❌ Unmaintained platform code (check `_unmaintained/` folder)
- ❌ Direct OpenGL calls without shader abstraction

## 🧪 Testing Patterns

### Unit Testing
```c
// Test framework pattern
#define TEST_ASSERT(condition, message) \
    do { \
        if (!(condition)) { \
            fprintf(stderr, "TEST FAILED: %s\n", message); \
            return -1; \
        } \
    } while(0)

int test_config_system(void) {
    InitSettings();
    SetInt("test_key", 42);
    TEST_ASSERT(GetInt("test_key", 0) == 42, "Config set/get failed");
    return 0;
}
```

### Profiling
```c
// Performance measurement
#define PROFILE_BEGIN(name) \
    struct timespec prof_start_##name; \
    clock_gettime(CLOCK_MONOTONIC, &prof_start_##name)

#define PROFILE_END(name) \
    do { \
        struct timespec prof_end_##name; \
        clock_gettime(CLOCK_MONOTONIC, &prof_end_##name); \
        double elapsed = (prof_end_##name.tv_sec - prof_start_##name.tv_sec) + \
                        (prof_end_##name.tv_nsec - prof_start_##name.tv_nsec) / 1e9; \
        LOG_debug("PROFILE[%s]: %.6f seconds", #name, elapsed); \
    } while(0)
```

## 🔍 Common File Locations

### Key Headers
- `workspace/all/common/api.h` - Core API definitions
- `workspace/all/common/defines.h` - System constants
- `workspace/all/common/config.h` - Configuration structures
- `workspace/{platform}/platform/platform.h` - Platform interface

### Important Sources
- `workspace/all/nextui/nextui.c` - Main UI (~2800 LOC)
- `workspace/all/minarch/minarch.c` - Emulation engine (~7100 LOC)
- `workspace/all/settings/settings.cpp` - Settings UI
- `workspace/{platform}/platform/platform.c` - Hardware abstraction

### Configuration Files
- `makefile` - Main build orchestration
- `docker-compose.yml` - Development environment
- `workspace/makefile` - Component compilation
- `ANÁLISE_DETALHADA_PROJETO.md` - Complete technical documentation

## 💡 Development Tips

### Performance Considerations
- Use background threads for I/O operations
- Implement object pooling for frequently allocated structures
- Profile critical paths regularly
- Minimize memory allocations in tight loops
- Use appropriate compiler optimizations per platform

### Debugging
- Use LOG_debug() liberally during development
- Implement memory leak detection in debug builds
- Profile thread synchronization bottlenecks
- Test on actual hardware early and often

### Code Organization
- Keep functions under 100 lines when possible
- Use clear, descriptive function and variable names
- Document complex algorithms and threading logic
- Separate platform-specific code clearly

---

*This file should be used as a reference for GitHub Copilot to understand NextUI project structure, coding standards, and best practices. Update as the project evolves.*
