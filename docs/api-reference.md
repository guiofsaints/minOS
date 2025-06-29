# NextUI API Reference

## Graphics API

### Core Graphics Functions

#### `SDL_Surface* GFX_init(int mode)`
**Description**: Initialize graphics subsystem and create main surface  
**Parameters**:
- `mode` - Display mode (MODE_MAIN, MODE_MENU, MODE_GAME)  
**Returns**: Main SDL surface or NULL on failure  
**Thread Safety**: Main thread only

#### `void GFX_quit(void)`
**Description**: Shutdown graphics subsystem and cleanup resources  
**Parameters**: None  
**Returns**: None  
**Thread Safety**: Main thread only

#### `void GFX_flip(SDL_Surface* screen, int sync)`
**Description**: Present rendered frame to display  
**Parameters**:
- `screen` - Surface to present
- `sync` - Synchronization mode (0=immediate, 1=vsync)  
**Returns**: None  
**Thread Safety**: Rendering thread only

#### `void GFX_clear(SDL_Surface* screen)`
**Description**: Clear surface to background color  
**Parameters**:
- `screen` - Surface to clear  
**Returns**: None  
**Thread Safety**: Thread owning surface

#### `void GFX_initShaders(void)`
**Description**: Initialize OpenGL ES shader system  
**Parameters**: None  
**Returns**: None  
**Thread Safety**: Main thread only

### Rendering Functions

#### `void GFX_blitButtonGroup(char* labels[], int group, SDL_Surface* screen, int enabled)`
**Description**: Render button hint group  
**Parameters**:
- `labels[]` - Array of button labels (NULL-terminated)
- `group` - Button group identifier (0=left, 1=right)
- `screen` - Target surface
- `enabled` - Enable state for highlighting  
**Returns**: None  
**Thread Safety**: UI thread only

#### `void GFX_blit(SDL_Surface* src, SDL_Rect* src_rect, SDL_Surface* dst, SDL_Rect* dst_rect)`
**Description**: Blit surface with optional scaling and clipping  
**Parameters**:
- `src` - Source surface
- `src_rect` - Source rectangle (NULL for full surface)
- `dst` - Destination surface
- `dst_rect` - Destination rectangle (NULL for full surface)  
**Returns**: None  
**Thread Safety**: Thread owning destination surface

---

## Input API

### Input Initialization

#### `void PAD_init(void)`
**Description**: Initialize input subsystem  
**Parameters**: None  
**Returns**: None  
**Thread Safety**: Main thread only

#### `void PAD_quit(void)`
**Description**: Shutdown input subsystem  
**Parameters**: None  
**Returns**: None  
**Thread Safety**: Main thread only

### Input State Functions

#### `void PAD_poll(void)`
**Description**: Update input state from hardware  
**Parameters**: None  
**Returns**: None  
**Thread Safety**: Main thread only  
**Note**: Must be called once per frame

#### `int PAD_justPressed(int button)`
**Description**: Check if button was just pressed this frame  
**Parameters**:
- `button` - Button code (BTN_A, BTN_B, BTN_UP, etc.)  
**Returns**: Non-zero if button was just pressed  
**Thread Safety**: Any thread after PAD_poll()

#### `int PAD_justReleased(int button)`
**Description**: Check if button was just released this frame  
**Parameters**:
- `button` - Button code  
**Returns**: Non-zero if button was just released  
**Thread Safety**: Any thread after PAD_poll()

#### `int PAD_isPressed(int button)`
**Description**: Check if button is currently held down  
**Parameters**:
- `button` - Button code  
**Returns**: Non-zero if button is currently pressed  
**Thread Safety**: Any thread after PAD_poll()

#### `int PAD_justRepeated(int button)`
**Description**: Check for button repeat events (for menu navigation)  
**Parameters**:
- `button` - Button code  
**Returns**: Non-zero if button repeat triggered  
**Thread Safety**: Any thread after PAD_poll()

### Button Constants
```c
// D-pad
#define BTN_UP     0x001
#define BTN_DOWN   0x002  
#define BTN_LEFT   0x004
#define BTN_RIGHT  0x008

// Face buttons
#define BTN_A      0x010
#define BTN_B      0x020
#define BTN_X      0x040
#define BTN_Y      0x080

// Shoulder buttons
#define BTN_L1     0x100
#define BTN_R1     0x200

// System buttons
#define BTN_SELECT 0x400
#define BTN_START  0x800
#define BTN_MENU   0x1000
#define BTN_POWER  0x2000
```

---

## Power Management API

### Power Initialization

#### `void PWR_init(void)`
**Description**: Initialize power management subsystem  
**Parameters**: None  
**Returns**: None  
**Thread Safety**: Main thread only

#### `void PWR_quit(void)`
**Description**: Shutdown power management and cleanup  
**Parameters**: None  
**Returns**: None  
**Thread Safety**: Main thread only

### Power State Management

#### `void PWR_update(int* dirty, int* sleeping, int* poweroff, int* quit)`
**Description**: Update power state and check for power events  
**Parameters**:
- `dirty` - Set to 1 if display needs refresh
- `sleeping` - Set to 1 if sleep requested
- `poweroff` - Set to 1 if shutdown requested  
- `quit` - Set to 1 if application exit requested  
**Returns**: None  
**Thread Safety**: Main thread only

#### `void PWR_powerOff(void)`
**Description**: Initiate system shutdown sequence  
**Parameters**: None  
**Returns**: Does not return  
**Thread Safety**: Any thread

#### `int PWR_enableAutosleep(int enable)`
**Description**: Enable/disable automatic sleep mode  
**Parameters**:
- `enable` - 1 to enable, 0 to disable  
**Returns**: Previous state  
**Thread Safety**: Any thread

### Battery Status

#### `void PWR_getBatteryStatus(int* is_charging, int* charge)`
**Description**: Get current battery status  
**Parameters**:
- `is_charging` - Output: 1 if charging, 0 if not
- `charge` - Output: Charge percentage (0-100)  
**Returns**: None  
**Thread Safety**: Any thread

#### `void PWR_setCPUSpeed(int speed)`
**Description**: Set CPU frequency profile  
**Parameters**:
- `speed` - Speed profile (CPU_SPEED_MENU, CPU_SPEED_NORMAL, CPU_SPEED_PERFORMANCE)  
**Returns**: None  
**Thread Safety**: Any thread

### CPU Speed Constants
```c
#define CPU_SPEED_MENU        0  // Low power for menu
#define CPU_SPEED_POWERSAVE   1  // Power saving mode  
#define CPU_SPEED_NORMAL      2  // Default performance
#define CPU_SPEED_PERFORMANCE 3  // Maximum performance
```

---

## Configuration API

### Configuration Access

#### `int GetInt(const char* key, int default_value)`
**Description**: Get integer configuration value  
**Parameters**:
- `key` - Configuration key name
- `default_value` - Value to return if key not found  
**Returns**: Configuration value or default  
**Thread Safety**: Read-safe from any thread

#### `void SetInt(const char* key, int value)`
**Description**: Set integer configuration value  
**Parameters**:
- `key` - Configuration key name
- `value` - Value to set  
**Returns**: None  
**Thread Safety**: Write from main thread only

#### `char* GetString(const char* key, char* buffer, size_t size, const char* default_value)`
**Description**: Get string configuration value  
**Parameters**:
- `key` - Configuration key name
- `buffer` - Output buffer
- `size` - Buffer size
- `default_value` - Default string if key not found  
**Returns**: Pointer to buffer  
**Thread Safety**: Read-safe from any thread

#### `void SetString(const char* key, const char* value)`
**Description**: Set string configuration value  
**Parameters**:
- `key` - Configuration key name
- `value` - String value to set  
**Returns**: None  
**Thread Safety**: Write from main thread only

### Common Configuration Keys
```c
// Display settings
"brightness"        // Screen brightness (0-10)
"colortemp"         // Color temperature (0-40)

// Audio settings  
"volume"            // Audio volume (0-20)
"audio_quality"     // Resampling quality (0-4)

// System settings
"cpu_speed"         // Default CPU speed (0-3)
"auto_sleep"        // Auto-sleep timeout (minutes)
"haptics"           // Vibration feedback (0/1)

// Network settings
"wifi"              // WiFi enabled (0/1)
"ntp_sync"          // Time synchronization (0/1)
```

---

## Platform Abstraction Layer

### Platform Initialization

#### `void PLAT_initInput(void)`
**Description**: Initialize platform-specific input handling  
**Parameters**: None  
**Returns**: None  
**Thread Safety**: Main thread only

#### `void PLAT_quitInput(void)`
**Description**: Shutdown platform input handling  
**Parameters**: None  
**Returns**: None  
**Thread Safety**: Main thread only

#### `SDL_Surface* PLAT_initVideo(void)`
**Description**: Initialize platform video system  
**Parameters**: None  
**Returns**: Platform-specific SDL surface  
**Thread Safety**: Main thread only

#### `void PLAT_quitVideo(void)`
**Description**: Shutdown platform video system  
**Parameters**: None  
**Returns**: None  
**Thread Safety**: Main thread only

### Hardware Control

#### `void PLAT_setCPUSpeed(int speed)`
**Description**: Set hardware CPU frequency  
**Parameters**:
- `speed` - CPU speed profile  
**Returns**: None  
**Thread Safety**: Any thread

#### `void PLAT_setRumble(int strength)`
**Description**: Control vibration motor  
**Parameters**:
- `strength` - Vibration strength (0-65535)  
**Returns**: None  
**Thread Safety**: Any thread

#### `void PLAT_setLED(int led, int color, int brightness)`
**Description**: Control RGB LED  
**Parameters**:
- `led` - LED index (0-3)
- `color` - RGB color value (0xRRGGBB)
- `brightness` - Brightness level (0-100)  
**Returns**: None  
**Thread Safety**: Any thread

### WiFi Functions

#### `void PLAT_wifiInit(void)`
**Description**: Initialize WiFi subsystem  
**Parameters**: None  
**Returns**: None  
**Thread Safety**: Main thread only

#### `bool PLAT_wifiEnabled(void)`
**Description**: Check if WiFi is enabled  
**Parameters**: None  
**Returns**: true if WiFi enabled  
**Thread Safety**: Any thread

#### `void PLAT_wifiEnable(bool on)`
**Description**: Enable/disable WiFi  
**Parameters**:
- `on` - true to enable, false to disable  
**Returns**: None  
**Thread Safety**: Any thread

#### `int PLAT_wifiScan(struct WIFI_network *networks, int max)`
**Description**: Scan for available WiFi networks  
**Parameters**:
- `networks` - Array to store scan results
- `max` - Maximum number of networks to return  
**Returns**: Number of networks found  
**Thread Safety**: Any thread

#### `void PLAT_wifiConnect(const char *ssid, const char *password)`
**Description**: Connect to WiFi network  
**Parameters**:
- `ssid` - Network name
- `password` - Network password (NULL for open networks)  
**Returns**: None  
**Thread Safety**: Any thread

---

## Audio API

### Audio System

#### `void SND_init(void)`
**Description**: Initialize audio subsystem  
**Parameters**: None  
**Returns**: None  
**Thread Safety**: Main thread only

#### `void SND_quit(void)`
**Description**: Shutdown audio subsystem  
**Parameters**: None  
**Returns**: None  
**Thread Safety**: Main thread only

#### `void SND_mix(int16_t* samples, int frames)`
**Description**: Mix audio samples for output  
**Parameters**:
- `samples` - Audio sample buffer
- `frames` - Number of frames to mix  
**Returns**: None  
**Thread Safety**: Audio thread only

---

## Message System API

### Message Handling

#### `void MSG_init(void)`
**Description**: Initialize message system  
**Parameters**: None  
**Returns**: None  
**Thread Safety**: Main thread only

#### `void MSG_quit(void)`
**Description**: Shutdown message system  
**Parameters**: None  
**Returns**: None  
**Thread Safety**: Main thread only

#### `void Show_message(char* message)`
**Description**: Display system message to user  
**Parameters**:
- `message` - Text message to display  
**Returns**: None  
**Thread Safety**: UI thread only

---

## Error Codes

### Common Return Values
```c
#define RESULT_SUCCESS              0
#define RESULT_ERROR_GENERIC       -1
#define RESULT_ERROR_NULL_POINTER  -2
#define RESULT_ERROR_OUT_OF_MEMORY -3
#define RESULT_ERROR_FILE_NOT_FOUND -4
#define RESULT_ERROR_PERMISSION_DENIED -5
#define RESULT_ERROR_INVALID_ARGUMENT -6
#define RESULT_ERROR_NOT_INITIALIZED -7
#define RESULT_ERROR_ALREADY_INITIALIZED -8
```

### Error Handling Best Practices
1. Always check return values from API calls
2. Use appropriate error codes for different failure types
3. Log errors with sufficient context
4. Provide graceful fallback behavior when possible
5. Clean up resources on error paths
