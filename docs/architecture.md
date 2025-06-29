# NextUI System Architecture

## Overview

NextUI implements a modern, multi-threaded firmware architecture designed for high-performance retro gaming on embedded devices. The system follows a layered approach with clear separation between hardware abstraction, core services, and user interface components.

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        NextUI System                           │
├─────────────────────────────────────────────────────────────────┤
│  User Interface Layer                                          │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐  │
│  │    NextUI       │ │    Settings     │ │   Game Time     │  │
│  │   (Main UI)     │ │    System       │ │   Tracking      │  │
│  │   ~2800 LOC     │ │                 │ │                 │  │
│  └─────────────────┘ └─────────────────┘ └─────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│  Core Services Layer                                           │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐  │
│  │    MinArch      │ │  Battery Mon    │ │  Audio Engine   │  │
│  │ (Emulation)     │ │                 │ │                 │  │
│  │   ~7100 LOC     │ │                 │ │ (libsamplerate) │  │
│  └─────────────────┘ └─────────────────┘ └─────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│  Common API Layer                                              │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐  │
│  │  Graphics API   │ │  Threading API  │ │  Storage API    │  │
│  │   (SDL2/GL)     │ │   (pthreads)    │ │   (SQLite)      │  │
│  └─────────────────┘ └─────────────────┘ └─────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│  Hardware Abstraction Layer (HAL)                              │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐  │
│  │  Platform API   │ │   Input Layer   │ │  Device Drivers │  │
│  │                 │ │                 │ │  (GPIO/I2C)     │  │
│  └─────────────────┘ └─────────────────┘ └─────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│  Hardware Layer                                                │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐  │
│  │   TrimUI SoC    │ │   Audio DAC     │ │   LED/GPIO      │  │
│  │  (ARM Cortex)   │ │                 │ │   Controllers   │  │
│  └─────────────────┘ └─────────────────┘ └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Threading Model

NextUI employs a sophisticated multi-threading architecture to achieve low latency and responsive user experience:

### Main Threads

1. **Main UI Thread** (`main_ui_thread`)
   - Primary interface rendering and event handling
   - Menu navigation and user interaction
   - Non-blocking operations only

2. **Background Load Thread** (`bg_load_thread`)
   - ROM scanning and thumbnail generation
   - Asynchronous file operations
   - Producer-consumer pattern with main UI

3. **Animation Thread** (`anim_thread`)
   - UI animations and transitions
   - Frame interpolation
   - Synchronized with display refresh

4. **Audio Thread** (`audio_thread`)
   - High-priority audio processing
   - Real-time resampling with libsamplerate
   - <20ms latency buffer management

5. **CPU Monitor Thread** (`cpu_monitor_thread`)
   - System performance monitoring
   - Dynamic CPU frequency scaling
   - Temperature monitoring

6. **System Service Threads**
   - Battery monitoring daemon
   - WiFi state management
   - LED control and effects

### Synchronization Primitives

```c
// SDL-based synchronization
static SDL_mutex* queueMutex = NULL;
static SDL_cond* queueCond = NULL;

// Thread-safe queue operations
SDL_LockMutex(queueMutex);
// ... critical section ...
SDL_CondSignal(queueCond);
SDL_UnlockMutex(queueMutex);
```

## Initialization Flow

### Boot Sequence

1. **Hardware Detection**
   ```c
   char *device = getenv("DEVICE");
   is_brick = exactMatch("brick", device);
   ```

2. **Platform Initialization**
   ```c
   PLAT_initInput();
   PLAT_initVideo();
   PLAT_initAudio();
   ```

3. **Core Services Startup**
   ```c
   PWR_init();      // Power management
   PAD_init();      // Input handling
   GFX_init();      // Graphics subsystem
   MSG_init();      // Message system
   ```

4. **Threading Initialization**
   ```c
   pthread_create(&bg_thread, NULL, BGLoadWorker, NULL);
   pthread_create(&anim_thread, NULL, animWorker, NULL);
   pthread_create(&cpu_thread, NULL, PLAT_cpu_monitor, NULL);
   ```

5. **Application Launch**
   ```c
   // NextUI main loop
   nextui_main();
   
   // Or MinArch for direct emulation
   minarch_main(core_path, rom_path);
   ```

## Data Flow Architecture

### ROM Loading Pipeline

```
User Selection → Background Scanner → Thumbnail Loader → UI Update
                      ↓                    ↓              ↓
                 File System          Image Cache    Main Thread
                 (Worker Thread)    (Worker Thread)  (UI Thread)
```

### Audio Pipeline

```
Libretro Core → libsamplerate → SDL Audio → Hardware DAC
    ↓              ↓              ↓           ↓
 Game Audio    Resampling     OS Buffer   Audio Out
(Emulation)   (Quality++)   (Low Latency) (Hardware)
```

### Graphics Pipeline

```
Game Frame → Shader Pipeline → Compositor → Display
    ↓            ↓               ↓           ↓
Libretro     OpenGL ES      Multi-layer   Framebuffer
 Output      Processing     Rendering     (Hardware)
```

## Memory Architecture

### Memory Regions

| Region | Size | Purpose | Access |
|--------|------|---------|--------|
| Code | ~50MB | Firmware executables | Read-only |
| Heap | Dynamic | Runtime allocation | Read-write |
| Stack | 8MB/thread | Thread stacks | Read-write |
| Shared | ~10MB | IPC and caches | Shared |
| Hardware | Mapped | GPIO/registers | Direct |

### Memory Management

```c
// Structured allocation patterns
typedef struct {
    SDL_Surface *thumbnail;
    char *path;
    time_t mtime;
} CacheEntry;

// Pool allocation for frequently used objects
static CacheEntry cache_pool[MAX_CACHE_ENTRIES];
static int cache_count = 0;
```

## Configuration System

### Hierarchical Configuration

1. **Global Settings** (`/sdcard/.userdata/shared/`)
   - System-wide preferences
   - WiFi configuration
   - Theme settings

2. **Platform Settings** (`/sdcard/.userdata/{platform}/`)
   - Hardware-specific options
   - Performance profiles
   - Input mappings

3. **Per-core Settings** (`/sdcard/.userdata/{platform}/{core}/`)
   - Emulator-specific options
   - Shader configurations
   - Control schemes

### Configuration API

```c
// Type-safe configuration access
int GetInt(const char* key, int default_value);
void SetInt(const char* key, int value);
char* GetString(const char* key, char* buffer, size_t size, const char* default_value);
void SetString(const char* key, const char* value);
```

## Error Handling Strategy

### Layered Error Handling

1. **Hardware Level**: Hardware detection and fallback
2. **System Level**: Service recovery and restart
3. **Application Level**: Graceful degradation
4. **User Level**: Informative error messages

### Logging Framework

```c
// Hierarchical logging
#define LOG_trace(fmt, ...) LOG_write(LOG_LEVEL_TRACE, __FILE__, __LINE__, fmt, ##__VA_ARGS__)
#define LOG_debug(fmt, ...) LOG_write(LOG_LEVEL_DEBUG, __FILE__, __LINE__, fmt, ##__VA_ARGS__)
#define LOG_info(fmt, ...)  LOG_write(LOG_LEVEL_INFO, __FILE__, __LINE__, fmt, ##__VA_ARGS__)
#define LOG_warn(fmt, ...)  LOG_write(LOG_LEVEL_WARN, __FILE__, __LINE__, fmt, ##__VA_ARGS__)
#define LOG_error(fmt, ...) LOG_write(LOG_LEVEL_ERROR, __FILE__, __LINE__, fmt, ##__VA_ARGS__)
```

## Performance Optimizations

### CPU Scaling
- Dynamic frequency adjustment based on workload
- Performance profiles for menu vs gaming
- Temperature-based throttling

### Memory Optimizations
- Object pooling for frequent allocations
- Lazy loading of thumbnails and metadata
- Efficient texture caching

### I/O Optimizations
- Asynchronous file operations
- Background ROM scanning
- Intelligent caching strategies
