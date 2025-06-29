# NextUI Boot Process

## Overview

NextUI follows a multi-stage boot process designed for embedded Linux systems, primarily targeting TrimUI devices. The boot sequence is optimized for fast startup times while ensuring proper hardware initialization and system stability.

## Boot Architecture

```
Power On → Hardware Init → Bootloader → Linux Kernel → Init System → NextUI
    ↓           ↓             ↓           ↓             ↓           ↓
   ~0ms      ~500ms        ~2s         ~8s          ~12s       ~15s
```

## Stage 1: Hardware Initialization (0-500ms)

### Power-On Reset
The TrimUI hardware performs basic power-on initialization:

1. **CPU Reset**: ARM Cortex processor starts execution
2. **Clock Setup**: System clocks configured to safe frequencies
3. **Memory Controller**: DDR initialization and testing
4. **Boot Media**: SD card or NAND detection

### Hardware Detection
```c
// Device identification during early boot
char* detect_device_model(void) {
    char* model = getenv("TRIMUI_MODEL");
    if (!model) {
        // Fallback detection via hardware registers
        model = read_device_tree_model();
    }
    
    if (exactMatch("Trimui Brick", model)) {
        is_brick = 1;
        return "brick";
    } else {
        is_brick = 0;
        return "smart_pro";
    }
}
```

## Stage 2: Bootloader (500ms-2s)

### U-Boot Configuration
The bootloader handles:
- Device tree loading
- Kernel parameter setup
- Boot logo display
- Recovery mode detection

### Boot Script Execution
```bash
# Boot script optimization
setenv bootargs "console=ttyS0,115200 root=/dev/mmcblk0p2 rw rootwait"
setenv bootcmd "ext4load mmc 0:1 0x42000000 uImage; bootm 0x42000000"

# Fast boot optimizations
setenv bootdelay 0
setenv silent 1
```

## Stage 3: Linux Kernel Boot (2s-8s)

### Kernel Configuration
NextUI uses a minimal kernel configuration optimized for:
- Fast boot times
- Low memory usage
- Essential hardware support
- Power management

### Device Tree
```dts
// TrimUI device tree excerpt
/dts-v1/;
/ {
    model = "TrimUI Smart Pro";
    compatible = "allwinner,sun50i-h618";
    
    cpus {
        cpu@0 {
            operating-points = <
                /* kHz    uV */
                480000   900000
                720000   950000
                1008000  1000000
                1200000  1050000
                1608000  1100000
                2016000  1200000
            >;
        };
    };
    
    memory {
        reg = <0x40000000 0x80000000>; // 2GB DDR4
    };
};
```

### Kernel Modules
Essential modules loaded during boot:
- GPIO drivers for input/output
- I2C drivers for power management
- Audio drivers (ALSA)
- Framebuffer drivers
- WiFi drivers (if enabled)

## Stage 4: Init System (8s-12s)

### System Services Initialization
The init system starts core services in order:

```bash
#!/bin/sh
# /etc/init.d/nextui-boot

# Mount essential filesystems
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t tmpfs tmpfs /tmp

# Setup device nodes
mknod /dev/fb0 c 29 0
mknod /dev/input/event0 c 13 64
mknod /dev/input/event1 c 13 65

# Configure hardware
echo userspace > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 1608000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_setspeed

# Start essential daemons
/usr/sbin/syslogd -S
/usr/bin/trimui_inputd &

# Mount SD card
mkdir -p /mnt/SDCARD
mount -t vfat /dev/mmcblk0p1 /mnt/SDCARD
```

### Hardware Service Initialization
```c
// Hardware initialization sequence
int init_hardware_services(void) {
    // Initialize GPIO for input monitoring
    if (init_gpio_service() != 0) {
        LOG_error("Failed to initialize GPIO service");
        return -1;
    }
    
    // Setup power management
    if (init_power_management() != 0) {
        LOG_error("Failed to initialize power management");
        return -1;
    }
    
    // Configure display
    if (init_display_service() != 0) {
        LOG_error("Failed to initialize display");
        return -1;
    }
    
    return 0;
}
```

## Stage 5: NextUI Initialization (12s-15s)

### Pre-Launch Setup
Before NextUI starts, the system performs final preparation:

```bash
#!/bin/sh
# MinUI.pak/launch.sh

export PLATFORM="tg5040"
export SDCARD_PATH="/mnt/SDCARD"
export SYSTEM_PATH="$SDCARD_PATH/.system/$PLATFORM"
export USERDATA_PATH="$SDCARD_PATH/.userdata/$PLATFORM"

# Create required directories
mkdir -p "$USERDATA_PATH/logs"
mkdir -p "$USERDATA_PATH/.minui"

# Setup library paths
export LD_LIBRARY_PATH="$SYSTEM_PATH/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"
export PATH="$SYSTEM_PATH/bin:/usr/trimui/bin:$PATH"

# Hardware preparation
echo 0 > /sys/class/led_anim/max_scale  # Turn off LEDs
trimui_inputd &  # Start input daemon
```

### NextUI Application Boot

#### Phase 1: Core System Initialization
```c
int main(int argc, char *argv[]) {
    LOG_info("NextUI starting...");
    
    // Initialize settings system
    InitSettings();
    
    // Set initial CPU speed
    PWR_setCPUSpeed(CPU_SPEED_MENU);
    
    // Initialize graphics
    screen = GFX_init(MODE_MAIN);
    if (!screen) {
        LOG_error("Failed to initialize graphics");
        return EXIT_FAILURE;
    }
    
    // Initialize input system
    PAD_init();
    
    // Initialize power management
    PWR_init();
    
    // Setup signal handlers
    signal(SIGINT, sigHandler);
    signal(SIGTERM, sigHandler);
    
    return nextui_main_loop();
}
```

#### Phase 2: Background Services Startup
```c
void start_background_services(void) {
    // Start background ROM scanner
    pthread_create(&bg_thread, NULL, BGLoadWorker, NULL);
    
    // Start thumbnail loader
    pthread_create(&thumb_thread, NULL, ThumbLoadWorker, NULL);
    
    // Start animation worker
    pthread_create(&anim_thread, NULL, animWorker, NULL);
    
    // Start system monitor
    pthread_create(&monitor_thread, NULL, PLAT_cpu_monitor, NULL);
    
    LOG_info("Background services started");
}
```

#### Phase 3: UI Initialization
```c
void init_user_interface(void) {
    // Load theme and resources
    load_theme_resources();
    
    // Initialize game list
    scan_rom_directories();
    
    // Load recent games
    load_recent_games();
    
    // Setup main menu
    setup_main_menu();
    
    // Show boot logo
    show_boot_logo();
    
    LOG_info("User interface ready");
}
```

## Boot Optimization Strategies

### Fast Boot Configuration

```c
// Boot time optimization settings
#define SKIP_FSCK           1    // Skip filesystem check
#define PARALLEL_INIT       1    // Parallel service startup
#define PRELOAD_CORES       0    // Delay core loading
#define ASYNC_SCAN          1    // Background ROM scanning
#define CACHE_THUMBNAILS    1    // Cache thumbnail loading

// Conditional initialization
void optimized_boot_init(void) {
    if (PARALLEL_INIT) {
        start_services_parallel();
    } else {
        start_services_sequential();
    }
    
    if (ASYNC_SCAN) {
        schedule_background_scan();
    } else {
        scan_roms_immediately();
    }
}
```

### Memory Preallocation
```c
// Pre-allocate critical memory during boot
void preallocate_memory(void) {
    // Pre-allocate main surface
    screen_buffer = malloc(FIXED_WIDTH * FIXED_HEIGHT * FIXED_BPP);
    
    // Pre-allocate thumbnail cache
    thumbnail_cache = malloc(MAX_THUMBNAILS * sizeof(CacheEntry));
    
    // Pre-allocate audio buffers
    audio_buffers = malloc(AUDIO_BUFFER_COUNT * AUDIO_BUFFER_SIZE);
    
    LOG_info("Memory preallocation complete");
}
```

## Boot Modes

### Normal Boot Mode
Standard boot sequence with full initialization:
1. All services started
2. Complete ROM scanning
3. Thumbnail generation
4. Full UI initialization

### Fast Boot Mode
Optimized boot for quick startup:
1. Essential services only
2. Background ROM scanning
3. Lazy thumbnail loading
4. Minimal UI initialization

```c
// Boot mode detection
enum BootMode {
    BOOT_NORMAL,
    BOOT_FAST,
    BOOT_RECOVERY,
    BOOT_MAINTENANCE
};

enum BootMode detect_boot_mode(void) {
    // Check for fast boot request
    if (exists("/tmp/fastboot")) {
        return BOOT_FAST;
    }
    
    // Check for recovery mode
    if (gpio_read(RECOVERY_BUTTON) == 0) {
        return BOOT_RECOVERY;
    }
    
    // Check for maintenance mode
    if (exists(USERDATA_PATH "/maintenance")) {
        return BOOT_MAINTENANCE;
    }
    
    return BOOT_NORMAL;
}
```

### Recovery Boot Mode
Safe mode for system recovery:
1. Minimal hardware initialization
2. Basic display and input
3. Recovery tools access
4. System repair utilities

## Hardware-Specific Boot Procedures

### TrimUI Brick Boot
```c
void brick_specific_boot(void) {
    // Configure Brick-specific hardware
    is_brick = 1;
    
    // Setup LED controllers
    init_brick_leds();
    
    // Configure higher resolution display
    setup_brick_display(1024, 768);
    
    // Enable additional GPIO
    enable_brick_gpio();
}
```

### TrimUI Smart Pro Boot
```c
void smart_pro_specific_boot(void) {
    // Configure Smart Pro hardware
    is_brick = 0;
    
    // Setup simpler LED system
    init_smart_pro_leds();
    
    // Configure standard display
    setup_smart_pro_display(1280, 720);
    
    // WiFi initialization
    if (CFG_getWifi()) {
        init_wifi_hardware();
    }
}
```

## Boot Error Handling

### Hardware Detection Failures
```c
int handle_hardware_failure(int error_code) {
    switch (error_code) {
        case HW_DISPLAY_FAILED:
            LOG_error("Display initialization failed");
            // Attempt framebuffer fallback
            return init_framebuffer_fallback();
            
        case HW_INPUT_FAILED:
            LOG_error("Input system failed");
            // Continue with limited input
            return init_emergency_input();
            
        case HW_AUDIO_FAILED:
            LOG_warn("Audio initialization failed");
            // Disable audio, continue
            disable_audio_system();
            return 0;
            
        default:
            LOG_error("Unknown hardware failure: %d", error_code);
            return -1;
    }
}
```

### Recovery Mechanisms
```c
void boot_recovery_mode(void) {
    LOG_info("Entering recovery mode");
    
    // Minimal initialization
    init_emergency_display();
    init_emergency_input();
    
    // Show recovery menu
    show_recovery_menu();
    
    // Recovery options:
    // 1. Safe mode boot
    // 2. Factory reset
    // 3. System repair
    // 4. File system check
}
```

## Boot Performance Monitoring

### Boot Time Measurement
```c
struct boot_timer {
    uint64_t start_time;
    uint64_t hardware_init;
    uint64_t kernel_ready;
    uint64_t services_ready;
    uint64_t ui_ready;
} boot_times;

void log_boot_performance(void) {
    uint64_t total_time = boot_times.ui_ready - boot_times.start_time;
    
    LOG_info("Boot performance:");
    LOG_info("  Hardware: %llu ms", 
             boot_times.hardware_init - boot_times.start_time);
    LOG_info("  Services: %llu ms", 
             boot_times.services_ready - boot_times.kernel_ready);
    LOG_info("  UI: %llu ms", 
             boot_times.ui_ready - boot_times.services_ready);
    LOG_info("  Total: %llu ms", total_time);
}
```

### Boot Optimization Metrics
- Target boot time: <15 seconds
- Hardware init: <500ms
- Kernel boot: <6 seconds
- Service init: <4 seconds
- UI ready: <3 seconds

## Post-Boot Initialization

### Deferred Initialization
```c
// Tasks performed after UI is shown
void post_boot_tasks(void) {
    // Background ROM scanning
    schedule_rom_scan();
    
    // Thumbnail generation
    schedule_thumbnail_generation();
    
    // System health check
    schedule_system_check();
    
    // Update check (if WiFi enabled)
    if (PLAT_isOnline()) {
        schedule_update_check();
    }
}
```

### Lazy Loading
- ROM metadata loaded on demand
- Thumbnails generated in background
- Cores loaded when first used
- Settings validated on access
