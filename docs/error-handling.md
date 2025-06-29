# minOS Error Handling

## Overview

minOS implements a comprehensive error handling strategy designed for embedded systems where robustness and reliability are critical. The firmware uses a multi-layered approach to error detection, reporting, recovery, and prevention.

## Error Handling Philosophy

### Design Principles

1. **Fail Gracefully**: System continues operation with reduced functionality
2. **User Transparency**: Errors are logged but don't disrupt user experience
3. **Automatic Recovery**: Self-healing mechanisms where possible
4. **Defensive Programming**: Input validation and resource protection
5. **Hierarchical Handling**: Different strategies for different error severities

## Error Classification System

### Error Severity Levels

```c
typedef enum {
    ERR_TRACE = 0,    // Debugging information
    ERR_DEBUG = 1,    // Development diagnostics
    ERR_INFO = 2,     // Informational messages
    ERR_WARN = 3,     // Warning conditions
    ERR_ERROR = 4,    // Error conditions
    ERR_CRITICAL = 5, // Critical system errors
    ERR_FATAL = 6     // System cannot continue
} ErrorLevel;
```

### Error Categories

```c
typedef enum {
    ERR_CAT_SYSTEM = 0x1000,     // System-level errors
    ERR_CAT_HARDWARE = 0x2000,   // Hardware-related errors
    ERR_CAT_MEMORY = 0x3000,     // Memory allocation/access errors
    ERR_CAT_IO = 0x4000,         // I/O and file system errors
    ERR_CAT_NETWORK = 0x5000,    // Network and connectivity errors
    ERR_CAT_AUDIO = 0x6000,      // Audio system errors
    ERR_CAT_VIDEO = 0x7000,      // Video/graphics errors
    ERR_CAT_INPUT = 0x8000,      // Input system errors
    ERR_CAT_EMULATION = 0x9000,  // Emulation core errors
    ERR_CAT_CONFIG = 0xA000      // Configuration errors
} ErrorCategory;
```

### Standardized Error Codes

```c
// Common error codes
#define ERR_SUCCESS                0
#define ERR_GENERIC               -1
#define ERR_NULL_POINTER          -2
#define ERR_OUT_OF_MEMORY         -3
#define ERR_INVALID_ARGUMENT      -4
#define ERR_FILE_NOT_FOUND        -5
#define ERR_PERMISSION_DENIED     -6
#define ERR_DEVICE_NOT_FOUND      -7
#define ERR_OPERATION_FAILED      -8
#define ERR_TIMEOUT               -9
#define ERR_INTERRUPTED          -10
#define ERR_NOT_IMPLEMENTED      -11
#define ERR_ALREADY_EXISTS       -12
#define ERR_NOT_INITIALIZED      -13
#define ERR_BUFFER_OVERFLOW      -14
#define ERR_CHECKSUM_FAILED      -15

// Hardware-specific errors
#define ERR_HW_DISPLAY_FAILED    (ERR_CAT_HARDWARE | 0x01)
#define ERR_HW_AUDIO_FAILED      (ERR_CAT_HARDWARE | 0x02)
#define ERR_HW_INPUT_FAILED      (ERR_CAT_HARDWARE | 0x03)
#define ERR_HW_POWER_CRITICAL    (ERR_CAT_HARDWARE | 0x04)
#define ERR_HW_THERMAL_WARNING   (ERR_CAT_HARDWARE | 0x05)
```

## Logging Framework

### Hierarchical Logging System

```c
// Logging macros with file and line information
#define LOG_trace(fmt, ...) LOG_write(ERR_TRACE, __FILE__, __LINE__, fmt, ##__VA_ARGS__)
#define LOG_debug(fmt, ...) LOG_write(ERR_DEBUG, __FILE__, __LINE__, fmt, ##__VA_ARGS__)
#define LOG_info(fmt, ...)  LOG_write(ERR_INFO, __FILE__, __LINE__, fmt, ##__VA_ARGS__)
#define LOG_warn(fmt, ...)  LOG_write(ERR_WARN, __FILE__, __LINE__, fmt, ##__VA_ARGS__)
#define LOG_error(fmt, ...) LOG_write(ERR_ERROR, __FILE__, __LINE__, fmt, ##__VA_ARGS__)
#define LOG_critical(fmt, ...) LOG_write(ERR_CRITICAL, __FILE__, __LINE__, fmt, ##__VA_ARGS__)
#define LOG_fatal(fmt, ...) LOG_write(ERR_FATAL, __FILE__, __LINE__, fmt, ##__VA_ARGS__)

// Core logging function
void LOG_write(ErrorLevel level, const char* file, int line, const char* fmt, ...) {
    static char buffer[1024];
    static FILE* log_file = NULL;
    
    // Open log file on first use
    if (!log_file) {
        char log_path[256];
        snprintf(log_path, sizeof(log_path), "%s/logs/minos.log", USERDATA_PATH);
        log_file = fopen(log_path, "a");
    }
    
    // Format timestamp
    time_t now = time(NULL);
    struct tm* tm_info = localtime(&now);
    char timestamp[32];
    strftime(timestamp, sizeof(timestamp), "%Y-%m-%d %H:%M:%S", tm_info);
    
    // Format message
    va_list args;
    va_start(args, fmt);
    vsnprintf(buffer, sizeof(buffer), fmt, args);
    va_end(args);
    
    // Log level strings
    const char* level_strings[] = {
        "TRACE", "DEBUG", "INFO", "WARN", "ERROR", "CRITICAL", "FATAL"
    };
    
    // Write to log file
    if (log_file) {
        fprintf(log_file, "[%s] %s %s:%d: %s\n", 
                timestamp, level_strings[level], file, line, buffer);
        fflush(log_file);
    }
    
    // Also write to console for development
    #ifdef DEBUG_BUILD
    fprintf(stderr, "[%s] %s:%d: %s\n", level_strings[level], file, line, buffer);
    #endif
    
    // Critical/fatal errors trigger immediate attention
    if (level >= ERR_CRITICAL) {
        handle_critical_error(level, buffer);
    }
}
```

### Contextual Error Information

```c
// Error context structure
typedef struct {
    ErrorLevel level;
    int error_code;
    char module[32];
    char function[64];
    char message[256];
    time_t timestamp;
    uint32_t thread_id;
    int line_number;
    char file_name[64];
} ErrorContext;

// Enhanced error reporting
void report_error_with_context(ErrorLevel level, int code, const char* module, 
                              const char* function, const char* file, int line,
                              const char* fmt, ...) {
    ErrorContext ctx;
    
    ctx.level = level;
    ctx.error_code = code;
    strncpy(ctx.module, module, sizeof(ctx.module) - 1);
    strncpy(ctx.function, function, sizeof(ctx.function) - 1);
    strncpy(ctx.file_name, file, sizeof(ctx.file_name) - 1);
    ctx.line_number = line;
    ctx.timestamp = time(NULL);
    ctx.thread_id = (uint32_t)pthread_self();
    
    // Format message
    va_list args;
    va_start(args, fmt);
    vsnprintf(ctx.message, sizeof(ctx.message), fmt, args);
    va_end(args);
    
    // Store in error history
    store_error_context(&ctx);
    
    // Log the error
    LOG_write(level, file, line, "[%s::%s] %s", module, function, ctx.message);
}

// Convenient macro for contextual error reporting
#define REPORT_ERROR(level, code, fmt, ...) \
    report_error_with_context(level, code, __MODULE__, __FUNCTION__, \
                             __FILE__, __LINE__, fmt, ##__VA_ARGS__)
```

## Memory Error Handling

### Allocation Failure Handling

```c
// Safe memory allocation with error handling
void* safe_malloc(size_t size, const char* context) {
    void* ptr = malloc(size);
    
    if (!ptr) {
        LOG_error("Memory allocation failed: %zu bytes for %s", size, context);
        
        // Attempt garbage collection
        perform_garbage_collection();
        
        // Retry allocation
        ptr = malloc(size);
        if (!ptr) {
            LOG_critical("Critical memory shortage: %zu bytes for %s", size, context);
            handle_memory_crisis();
            return NULL;
        }
        
        LOG_info("Memory allocation succeeded after GC: %zu bytes", size);
    }
    
    // Track allocation in debug builds
    #ifdef DEBUG_BUILD
    track_allocation(ptr, size, context);
    #endif
    
    return ptr;
}

// Memory crisis handling
void handle_memory_crisis(void) {
    LOG_critical("Entering memory crisis mode");
    
    // Free non-essential caches
    clear_thumbnail_cache();
    clear_shader_cache();
    clear_audio_buffers();
    
    // Reduce quality settings
    set_audio_quality(0);  // Lowest quality
    set_video_quality(0);  // Basic rendering
    
    // Disable background services
    suspend_background_workers();
    
    LOG_warn("Memory crisis mode activated - reduced functionality");
}

// Buffer overflow protection
char* safe_strncpy(char* dest, const char* src, size_t dest_size) {
    if (!dest || !src || dest_size == 0) {
        LOG_error("Invalid parameters to safe_strncpy");
        return dest;
    }
    
    strncpy(dest, src, dest_size - 1);
    dest[dest_size - 1] = '\0';  // Ensure null termination
    
    return dest;
}

// Safe buffer operations
int safe_snprintf(char* buffer, size_t size, const char* fmt, ...) {
    if (!buffer || size == 0) {
        LOG_error("Invalid buffer parameters");
        return -1;
    }
    
    va_list args;
    va_start(args, fmt);
    int result = vsnprintf(buffer, size, fmt, args);
    va_end(args);
    
    if (result >= (int)size) {
        LOG_warn("Buffer truncation occurred: needed %d, had %zu", result, size);
        buffer[size - 1] = '\0';  // Ensure termination
    }
    
    return result;
}
```

### Memory Leak Detection

```c
#ifdef DEBUG_BUILD
// Memory allocation tracking
typedef struct AllocRecord {
    void* ptr;
    size_t size;
    char context[64];
    time_t timestamp;
    struct AllocRecord* next;
} AllocRecord;

static AllocRecord* alloc_list = NULL;
static pthread_mutex_t alloc_mutex = PTHREAD_MUTEX_INITIALIZER;
static size_t total_allocated = 0;
static int allocation_count = 0;

void track_allocation(void* ptr, size_t size, const char* context) {
    pthread_mutex_lock(&alloc_mutex);
    
    AllocRecord* record = malloc(sizeof(AllocRecord));
    if (record) {
        record->ptr = ptr;
        record->size = size;
        strncpy(record->context, context, sizeof(record->context) - 1);
        record->context[sizeof(record->context) - 1] = '\0';
        record->timestamp = time(NULL);
        record->next = alloc_list;
        alloc_list = record;
        
        total_allocated += size;
        allocation_count++;
    }
    
    pthread_mutex_unlock(&alloc_mutex);
}

void track_deallocation(void* ptr) {
    pthread_mutex_lock(&alloc_mutex);
    
    AllocRecord** current = &alloc_list;
    while (*current) {
        if ((*current)->ptr == ptr) {
            AllocRecord* to_remove = *current;
            *current = (*current)->next;
            
            total_allocated -= to_remove->size;
            allocation_count--;
            
            free(to_remove);
            break;
        }
        current = &(*current)->next;
    }
    
    pthread_mutex_unlock(&alloc_mutex);
}

void check_memory_leaks(void) {
    pthread_mutex_lock(&alloc_mutex);
    
    if (alloc_list) {
        LOG_warn("Memory leaks detected:");
        AllocRecord* current = alloc_list;
        while (current) {
            LOG_warn("  Leak: %p (%zu bytes) - %s", 
                    current->ptr, current->size, current->context);
            current = current->next;
        }
        LOG_warn("Total leaked: %zu bytes in %d allocations", 
                total_allocated, allocation_count);
    } else {
        LOG_info("No memory leaks detected");
    }
    
    pthread_mutex_unlock(&alloc_mutex);
}
#endif
```

## Hardware Error Handling

### Display System Errors

```c
// Display initialization with fallback
SDL_Surface* init_display_with_fallback(void) {
    SDL_Surface* screen = NULL;
    
    // Try primary display mode
    screen = PLAT_initVideo();
    if (screen) {
        LOG_info("Primary display initialized successfully");
        return screen;
    }
    
    LOG_warn("Primary display failed, trying fallback modes");
    
    // Try reduced resolution
    screen = init_fallback_display(640, 480);
    if (screen) {
        LOG_warn("Using fallback display resolution: 640x480");
        return screen;
    }
    
    // Try framebuffer direct access
    screen = init_framebuffer_direct();
    if (screen) {
        LOG_warn("Using direct framebuffer access");
        return screen;
    }
    
    LOG_critical("All display initialization methods failed");
    return NULL;
}

// Graphics error recovery
void handle_graphics_error(int error_code) {
    switch (error_code) {
        case ERR_HW_DISPLAY_FAILED:
            LOG_error("Display hardware failure detected");
            // Attempt display reset
            reset_display_hardware();
            break;
            
        case GL_OUT_OF_MEMORY:
            LOG_error("GPU memory exhausted");
            // Clear GPU caches
            clear_texture_cache();
            break;
            
        case GL_INVALID_OPERATION:
            LOG_error("Invalid OpenGL operation");
            // Reset graphics state
            reset_opengl_state();
            break;
            
        default:
            LOG_error("Unknown graphics error: %d", error_code);
            // Generic graphics reset
            reinit_graphics_subsystem();
            break;
    }
}
```

### Audio System Errors

```c
// Audio error handling with graceful degradation
void handle_audio_error(int error_code) {
    static int audio_error_count = 0;
    
    audio_error_count++;
    
    switch (error_code) {
        case ERR_AUDIO_DEVICE_LOST:
            LOG_warn("Audio device lost, attempting reconnection");
            if (reinit_audio_device() == 0) {
                audio_error_count = 0;
                LOG_info("Audio device reconnected successfully");
            }
            break;
            
        case ERR_AUDIO_BUFFER_UNDERRUN:
            LOG_debug("Audio buffer underrun detected");
            // Increase buffer size to prevent future underruns
            increase_audio_buffer_size();
            break;
            
        case ERR_AUDIO_SAMPLE_RATE_UNSUPPORTED:
            LOG_warn("Unsupported sample rate, using fallback");
            set_fallback_sample_rate();
            break;
            
        default:
            LOG_error("Unknown audio error: %d", error_code);
            break;
    }
    
    // If too many audio errors, disable audio
    if (audio_error_count > 10) {
        LOG_warn("Too many audio errors, disabling audio system");
        disable_audio_system();
        show_user_message("Audio disabled due to hardware issues");
    }
}

// Audio fallback implementation
void set_fallback_sample_rate(void) {
    const int fallback_rates[] = {48000, 44100, 22050, 11025, 8000};
    const int num_rates = sizeof(fallback_rates) / sizeof(fallback_rates[0]);
    
    for (int i = 0; i < num_rates; i++) {
        if (try_audio_sample_rate(fallback_rates[i]) == 0) {
            LOG_info("Using fallback audio rate: %d Hz", fallback_rates[i]);
            return;
        }
    }
    
    LOG_error("No supported audio sample rate found");
    disable_audio_system();
}
```

### Power Management Errors

```c
// Battery monitoring with critical alerts
void monitor_battery_status(void) {
    static int low_battery_warnings = 0;
    static time_t last_warning = 0;
    
    int is_charging, charge;
    PLAT_getBatteryStatus(&is_charging, &charge);
    
    if (charge < 5 && !is_charging) {
        // Critical battery level
        LOG_critical("Critical battery level: %d%%", charge);
        
        time_t now = time(NULL);
        if (now - last_warning > 30) {  // Warn every 30 seconds
            show_critical_battery_warning();
            last_warning = now;
        }
        
        low_battery_warnings++;
        if (low_battery_warnings > 5) {
            LOG_critical("Initiating emergency shutdown");
            emergency_shutdown();
        }
    } else if (charge < 15 && !is_charging) {
        // Low battery warning
        if (low_battery_warnings < 3) {
            show_low_battery_warning();
            low_battery_warnings++;
        }
    } else {
        // Reset warning counter when battery is okay
        low_battery_warnings = 0;
    }
}

// Emergency shutdown procedure
void emergency_shutdown(void) {
    LOG_critical("Emergency shutdown initiated");
    
    // Save critical state immediately
    save_emergency_state();
    
    // Quick cleanup
    sync_filesystems();
    
    // Force power off
    PLAT_powerOff();
}
```

## File System Error Handling

### File Operation Error Handling

```c
// Safe file operations with error recovery
FILE* safe_fopen(const char* path, const char* mode) {
    FILE* file = fopen(path, mode);
    
    if (!file) {
        int err = errno;
        LOG_error("Failed to open file '%s' in mode '%s': %s", 
                 path, mode, strerror(err));
        
        switch (err) {
            case ENOENT:
                // File doesn't exist, try to create directory
                if (strchr(mode, 'w') || strchr(mode, 'a')) {
                    create_directory_for_file(path);
                    file = fopen(path, mode);
                    if (file) {
                        LOG_info("Created missing directory and opened file: %s", path);
                    }
                }
                break;
                
            case EACCES:
                LOG_error("Permission denied for file: %s", path);
                break;
                
            case ENOSPC:
                LOG_critical("No space left on device for file: %s", path);
                handle_disk_full();
                break;
                
            case EMFILE:
                LOG_error("Too many open files");
                close_unused_files();
                file = fopen(path, mode);
                break;
        }
    }
    
    return file;
}

// Disk space monitoring
void handle_disk_full(void) {
    LOG_critical("Disk full detected, initiating cleanup");
    
    // Clean up temporary files
    cleanup_temp_files();
    
    // Clear old log files
    cleanup_old_logs();
    
    // Clear thumbnail cache
    clear_thumbnail_cache();
    
    // Notify user
    show_user_message("Disk space low - some files were cleaned up");
}

// Configuration file error handling
int load_config_with_recovery(const char* config_path) {
    FILE* file = safe_fopen(config_path, "r");
    if (!file) {
        LOG_warn("Config file not found, creating default: %s", config_path);
        return create_default_config(config_path);
    }
    
    // Verify config file integrity
    if (!verify_config_integrity(file)) {
        LOG_error("Config file corrupted, restoring backup: %s", config_path);
        fclose(file);
        
        if (restore_config_backup(config_path) == 0) {
            file = safe_fopen(config_path, "r");
            if (file && verify_config_integrity(file)) {
                LOG_info("Config restored from backup successfully");
            } else {
                LOG_warn("Backup also corrupted, creating default config");
                if (file) fclose(file);
                return create_default_config(config_path);
            }
        } else {
            LOG_warn("No valid backup found, creating default config");
            return create_default_config(config_path);
        }
    }
    
    int result = parse_config_file(file);
    fclose(file);
    
    return result;
}
```

## Network Error Handling

### WiFi Connection Error Handling

```c
// WiFi connection with retry logic
int connect_wifi_with_retry(const char* ssid, const char* password) {
    const int max_retries = 3;
    const int retry_delay = 5; // seconds
    
    for (int attempt = 1; attempt <= max_retries; attempt++) {
        LOG_info("WiFi connection attempt %d/%d for SSID: %s", 
                attempt, max_retries, ssid);
        
        int result = PLAT_wifiConnect(ssid, password);
        if (result == 0) {
            LOG_info("WiFi connected successfully");
            return 0;
        }
        
        LOG_warn("WiFi connection attempt %d failed: %d", attempt, result);
        
        if (attempt < max_retries) {
            LOG_info("Retrying WiFi connection in %d seconds", retry_delay);
            sleep(retry_delay);
        }
    }
    
    LOG_error("WiFi connection failed after %d attempts", max_retries);
    handle_wifi_connection_failure(ssid);
    return -1;
}

// Network connectivity monitoring
void monitor_network_connectivity(void) {
    static bool was_online = false;
    static int offline_count = 0;
    
    bool is_online = PLAT_isOnline();
    
    if (was_online && !is_online) {
        // Connection lost
        offline_count++;
        LOG_warn("Network connectivity lost (count: %d)", offline_count);
        
        if (offline_count > 3) {
            // Multiple connection losses, attempt WiFi reset
            LOG_info("Attempting WiFi reset due to repeated disconnections");
            reset_wifi_connection();
            offline_count = 0;
        }
    } else if (!was_online && is_online) {
        // Connection restored
        LOG_info("Network connectivity restored");
        offline_count = 0;
    }
    
    was_online = is_online;
}
```

## Error Recovery Strategies

### Automatic Recovery Mechanisms

```c
// System health monitoring and recovery
void system_health_monitor(void) {
    static time_t last_check = 0;
    time_t now = time(NULL);
    
    // Run health check every 30 seconds
    if (now - last_check < 30) {
        return;
    }
    last_check = now;
    
    // Check memory usage
    check_memory_health();
    
    // Check CPU temperature
    check_thermal_health();
    
    // Check storage health
    check_storage_health();
    
    // Check process health
    check_process_health();
}

void check_memory_health(void) {
    size_t free_memory = get_free_memory();
    size_t total_memory = get_total_memory();
    int usage_percent = (int)((total_memory - free_memory) * 100 / total_memory);
    
    if (usage_percent > 90) {
        LOG_warn("High memory usage: %d%%", usage_percent);
        trigger_garbage_collection();
    } else if (usage_percent > 95) {
        LOG_critical("Critical memory usage: %d%%", usage_percent);
        handle_memory_crisis();
    }
}

void check_thermal_health(void) {
    int cpu_temp = get_cpu_temperature();
    
    if (cpu_temp > 80) {
        LOG_warn("High CPU temperature: %d°C", cpu_temp);
        reduce_cpu_frequency();
    } else if (cpu_temp > 90) {
        LOG_critical("Critical CPU temperature: %d°C", cpu_temp);
        emergency_thermal_shutdown();
    }
}
```

### Graceful Degradation

```c
// Feature degradation based on system health
void degrade_system_performance(int level) {
    switch (level) {
        case 1: // Light degradation
            LOG_info("Enabling light performance degradation");
            set_audio_quality(2);  // Reduce audio quality
            disable_background_scanning();
            break;
            
        case 2: // Moderate degradation
            LOG_warn("Enabling moderate performance degradation");
            set_audio_quality(1);
            disable_animations();
            reduce_shader_quality();
            break;
            
        case 3: // Heavy degradation
            LOG_warn("Enabling heavy performance degradation");
            set_audio_quality(0);
            disable_thumbnails();
            disable_shaders();
            force_garbage_collection();
            break;
            
        case 4: // Emergency mode
            LOG_critical("Entering emergency performance mode");
            disable_audio();
            disable_all_effects();
            minimal_ui_mode();
            break;
    }
}
```

## User-Facing Error Messages

### Error Message Display System

```c
// User-friendly error messages
typedef struct {
    int error_code;
    const char* user_message;
    const char* technical_message;
    bool show_to_user;
} ErrorMessage;

static const ErrorMessage error_messages[] = {
    {ERR_OUT_OF_MEMORY, "System memory is low", "Memory allocation failed", true},
    {ERR_FILE_NOT_FOUND, "Game file not found", "ROM file missing", true},
    {ERR_HW_AUDIO_FAILED, "Audio system unavailable", "Audio hardware initialization failed", true},
    {ERR_HW_DISPLAY_FAILED, "Display system error", "Video initialization failed", false},
    {ERR_NETWORK_TIMEOUT, "Network connection timeout", "WiFi connection timed out", true},
    // ... more error messages
};

void show_error_to_user(int error_code, const char* context) {
    const ErrorMessage* msg = find_error_message(error_code);
    
    if (msg && msg->show_to_user) {
        char display_message[256];
        snprintf(display_message, sizeof(display_message), 
                "%s\n\nContext: %s", msg->user_message, context);
        
        // Show message dialog
        show_message_dialog("Error", display_message, MSG_TYPE_ERROR);
        
        // Log technical details
        LOG_error("%s (Code: %d, Context: %s)", 
                 msg->technical_message, error_code, context);
    } else {
        // Generic error message
        show_message_dialog("System Error", 
                           "An unexpected error occurred. Please try again.", 
                           MSG_TYPE_ERROR);
        
        LOG_error("Unhandled error: %d in context: %s", error_code, context);
    }
}
```

## Error Statistics and Monitoring

### Error Tracking and Analysis

```c
// Error statistics collection
typedef struct {
    int error_code;
    int occurrence_count;
    time_t first_occurrence;
    time_t last_occurrence;
    char context[64];
} ErrorStatistic;

static ErrorStatistic error_stats[256];
static int error_stats_count = 0;
static pthread_mutex_t stats_mutex = PTHREAD_MUTEX_INITIALIZER;

void track_error_occurrence(int error_code, const char* context) {
    pthread_mutex_lock(&stats_mutex);
    
    // Find existing statistic
    ErrorStatistic* stat = NULL;
    for (int i = 0; i < error_stats_count; i++) {
        if (error_stats[i].error_code == error_code) {
            stat = &error_stats[i];
            break;
        }
    }
    
    // Create new statistic if not found
    if (!stat && error_stats_count < 256) {
        stat = &error_stats[error_stats_count++];
        stat->error_code = error_code;
        stat->occurrence_count = 0;
        stat->first_occurrence = time(NULL);
        strncpy(stat->context, context, sizeof(stat->context) - 1);
    }
    
    if (stat) {
        stat->occurrence_count++;
        stat->last_occurrence = time(NULL);
    }
    
    pthread_mutex_unlock(&stats_mutex);
}

void generate_error_report(void) {
    pthread_mutex_lock(&stats_mutex);
    
    LOG_info("Error Report Summary:");
    LOG_info("Total unique errors: %d", error_stats_count);
    
    for (int i = 0; i < error_stats_count; i++) {
        ErrorStatistic* stat = &error_stats[i];
        LOG_info("  Error %d: %d occurrences, first: %s, last: %s, context: %s",
                stat->error_code, stat->occurrence_count,
                format_time(stat->first_occurrence),
                format_time(stat->last_occurrence),
                stat->context);
    }
    
    pthread_mutex_unlock(&stats_mutex);
}
```

This comprehensive error handling system ensures minOS can gracefully handle various failure scenarios while maintaining system stability and providing meaningful feedback to both users and developers.
