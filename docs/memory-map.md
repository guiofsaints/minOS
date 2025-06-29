# minOS Memory Map

## Overview

minOS firmware operates in a multi-process Linux environment with virtual memory management. This document describes the memory layout, allocation strategies, and reserved regions used by the firmware components.

## Virtual Memory Layout

### Process Memory Map

```
Virtual Address Space (per process)
┌─────────────────────────────────────────┐ 0xFFFFFFFF
│           Kernel Space                  │
│         (Not accessible)                │
├─────────────────────────────────────────┤ 0xC0000000
│            Stack Region                 │
│         (Thread stacks)                 │
├─────────────────────────────────────────┤ 0xBF000000
│            Memory Mapped                │
│         (Device registers)              │
├─────────────────────────────────────────┤ 0xB0000000
│           Shared Memory                 │
│      (IPC and caches)                   │
├─────────────────────────────────────────┤ 0xA0000000
│            Heap Region                  │
│        (Dynamic allocation)             │
├─────────────────────────────────────────┤ 0x40000000
│            Shared Libraries             │
│    (SDL2, OpenGL ES, libc)              │
├─────────────────────────────────────────┤ 0x10000000
│            Code Segment                 │
│       (Firmware executables)            │
├─────────────────────────────────────────┤ 0x08000000
│            Data Segment                 │
│      (Global/static variables)          │
└─────────────────────────────────────────┘ 0x00000000
```

## Firmware Component Memory Usage

### minOS Main Process

| Component | Base Address | Size | Description |
|-----------|--------------|------|-------------|
| **Code Segment** | 0x08000000 | ~8MB | minOS executable code |
| **Data Segment** | 0x08800000 | ~2MB | Global variables and constants |
| **Heap** | 0x40000000+ | Dynamic | Runtime allocations |
| **SDL Surfaces** | Heap | ~50MB | Display buffers and textures |
| **Thread Stacks** | 0xBF000000+ | 8MB each | Per-thread execution stacks |

#### Critical Data Structures
```c
// Main UI context (global)
static struct UI_Context {
    SDL_Surface* screen;           // Main display surface
    SDL_Surface* layers[5];        // Multi-layer rendering
    char current_path[MAX_PATH];   // Current directory
    int selected_game;             // Selected game index
    // ... additional state
} ui_context;  // ~4KB

// Game list cache (heap allocated)
static struct GameEntry {
    char* path;                    // ROM file path
    char* display_name;            // Display name
    SDL_Surface* thumbnail;        // Thumbnail image
    time_t last_played;            // Last access time
} *game_list;  // ~100KB for 1000 games
```

### MinArch Emulation Process

| Component | Base Address | Size | Description |
|-----------|--------------|------|-------------|
| **Code Segment** | 0x08000000 | ~12MB | MinArch + libretro core |
| **Core Memory** | 0x20000000 | Variable | Emulated system memory |
| **Audio Buffers** | Heap | ~4MB | Multi-frame audio buffering |
| **Video Buffers** | Heap | ~16MB | Frame buffers and textures |
| **Save States** | Heap | Variable | Compressed save state data |

#### Emulation Memory Layout
```c
// Core-specific memory allocation
static struct EmulationContext {
    void* core_handle;             // libretro core library
    void* system_memory;           // Emulated system RAM
    size_t system_memory_size;     // Size varies by system
    
    // Audio processing
    int16_t* audio_buffer;         // Ring buffer for audio
    size_t audio_buffer_size;      // Typically 4096 frames
    
    // Video processing
    uint16_t* video_buffer;        // Current frame buffer
    uint32_t* scaled_buffer;       // Scaled frame for display
    
    // Save state management
    void* save_state_buffer;       // Compressed save data
    size_t save_state_size;        // Varies by system
} emu_context;
```

## Hardware Memory-Mapped Regions

### TrimUI Hardware Registers

| Address Range | Size | Description | Access |
|---------------|------|-------------|---------|
| **0xB0000000-0xB0001000** | 4KB | GPIO Controller | R/W |
| **0xB0010000-0xB0011000** | 4KB | I2C Controllers | R/W |
| **0xB0020000-0xB0021000** | 4KB | PWM Controller | R/W |
| **0xB0030000-0xB0031000** | 4KB | Audio DAC | R/W |
| **0xB0040000-0xB0041000** | 4KB | Display Controller | R/W |

#### GPIO Memory Layout
```c
// GPIO register mapping
struct GPIO_Registers {
    volatile uint32_t DATA;        // 0x00: Data register
    volatile uint32_t DIR;         // 0x04: Direction register
    volatile uint32_t PULL;        // 0x08: Pull-up/down register
    volatile uint32_t DRIVE;       // 0x0C: Drive strength
    volatile uint32_t INT_EN;      // 0x10: Interrupt enable
    volatile uint32_t INT_STATUS;  // 0x14: Interrupt status
    // ... additional registers
};

// Memory-mapped access
#define GPIO_BASE 0xB0000000
static volatile struct GPIO_Registers* gpio = 
    (struct GPIO_Registers*)GPIO_BASE;
```

## Memory Pool Management

### Graphics Memory Pool

```c
// Texture cache management
#define MAX_TEXTURES 256
#define TEXTURE_POOL_SIZE (64 * 1024 * 1024)  // 64MB

static struct TexturePool {
    GLuint textures[MAX_TEXTURES];
    size_t texture_sizes[MAX_TEXTURES];
    void* texture_pool;
    size_t pool_used;
    size_t pool_total;
} texture_pool;

// Pool allocation
void* texture_alloc(size_t size) {
    if (texture_pool.pool_used + size > texture_pool.pool_total) {
        // Garbage collect unused textures
        texture_pool_gc();
    }
    
    void* ptr = (char*)texture_pool.texture_pool + texture_pool.pool_used;
    texture_pool.pool_used += ALIGN_UP(size, 64);
    return ptr;
}
```

### Audio Buffer Pool

```c
// Audio sample management
#define AUDIO_BUFFER_COUNT 8
#define AUDIO_BUFFER_SIZE 4096

static struct AudioPool {
    int16_t buffers[AUDIO_BUFFER_COUNT][AUDIO_BUFFER_SIZE];
    int buffer_head;
    int buffer_tail;
    SDL_mutex* buffer_mutex;
} audio_pool;

// Ring buffer management
int16_t* audio_get_buffer(void) {
    SDL_LockMutex(audio_pool.buffer_mutex);
    int16_t* buffer = audio_pool.buffers[audio_pool.buffer_head];
    audio_pool.buffer_head = (audio_pool.buffer_head + 1) % AUDIO_BUFFER_COUNT;
    SDL_UnlockMutex(audio_pool.buffer_mutex);
    return buffer;
}
```

## Memory Allocation Strategies

### Stack Allocation Strategy

Each thread gets a dedicated stack with guard pages:

```c
// Thread stack configuration
#define THREAD_STACK_SIZE (8 * 1024 * 1024)  // 8MB
#define THREAD_GUARD_SIZE (4 * 1024)         // 4KB guard

pthread_attr_t create_thread_attr(void) {
    pthread_attr_t attr;
    pthread_attr_init(&attr);
    
    // Set stack size
    pthread_attr_setstacksize(&attr, THREAD_STACK_SIZE);
    
    // Enable guard page
    pthread_attr_setguardsize(&attr, THREAD_GUARD_SIZE);
    
    return attr;
}
```

### Heap Allocation Strategy

The firmware uses multiple heap allocation strategies based on object lifecycle:

1. **Permanent Allocations**: Configuration, system state
2. **Cache Allocations**: Thumbnails, recently used data
3. **Temporary Allocations**: Frame processing, I/O buffers
4. **Pool Allocations**: Audio buffers, texture data

```c
// Memory category tracking
enum MemoryCategory {
    MEM_PERMANENT,   // Never freed
    MEM_CACHE,       // LRU eviction
    MEM_TEMPORARY,   // Short-lived
    MEM_POOL         // Pool managed
};

void* mem_alloc(size_t size, enum MemoryCategory category) {
    switch (category) {
        case MEM_PERMANENT:
            return malloc(size);
        case MEM_CACHE:
            return cache_alloc(size);
        case MEM_TEMPORARY:
            return temp_alloc(size);
        case MEM_POOL:
            return pool_alloc(size);
    }
}
```

## Reserved Memory Regions

### System Reserved Areas

| Region | Size | Purpose | Protection |
|--------|------|---------|------------|
| **Kernel Space** | 1GB | Linux kernel | No access |
| **Hardware Registers** | 256MB | Device I/O | Privileged |
| **DMA Buffers** | 64MB | Hardware DMA | Coherent |
| **Frame Buffer** | 16MB | Display output | Write-through |

### Firmware Reserved Areas

| Region | Size | Purpose | Access |
|--------|------|---------|--------|
| **Configuration** | 1MB | Persistent settings | Read/Write |
| **Save States** | Variable | Emulation saves | Read/Write |
| **Thumbnails** | 50MB | Game thumbnails | Cached |
| **Audio Buffers** | 4MB | Audio processing | Ring buffer |

## Memory Protection

### Stack Protection
- Guard pages prevent stack overflow
- Each thread has isolated stack space
- Stack canaries detect corruption

### Heap Protection
- Allocation tracking prevents leaks
- Debug builds include allocation guards
- Pool allocation prevents fragmentation

### Hardware Protection
- Memory-mapped I/O uses volatile access
- DMA buffers are cache-coherent
- Critical registers are access-protected

## Memory Performance Optimization

### Cache Optimization
```c
// Cache-friendly data layout
struct GameEntry {
    char name[64];              // Frequently accessed
    uint32_t crc32;            // For quick comparison
    time_t last_played;        // Sorting key
    
    // Less frequently accessed data
    char* full_path;           // Pointer to heap
    SDL_Surface* thumbnail;    // Cached separately
} __attribute__((packed));
```

### Memory Prefetching
```c
// Prefetch next game thumbnails
void prefetch_thumbnails(int current_index) {
    for (int i = 1; i <= 3; i++) {
        int next_index = current_index + i;
        if (next_index < game_count) {
            __builtin_prefetch(game_list[next_index].thumbnail, 0, 1);
        }
    }
}
```

### Memory Alignment
- All structures use natural alignment
- DMA buffers aligned to cache line boundaries
- Texture data aligned for GPU efficiency

## Memory Debugging

### Debug Build Features
- Memory allocation tracking
- Leak detection at shutdown
- Buffer overflow protection
- Usage statistics logging

### Memory Monitoring
```c
// Runtime memory statistics
struct MemoryStats {
    size_t total_allocated;
    size_t peak_usage;
    size_t current_usage;
    int allocation_count;
    int free_count;
} memory_stats;

void log_memory_stats(void) {
    LOG_info("Memory: %zuMB used, %zuMB peak, %d allocs, %d frees",
             memory_stats.current_usage / (1024*1024),
             memory_stats.peak_usage / (1024*1024),
             memory_stats.allocation_count,
             memory_stats.free_count);
}
```
