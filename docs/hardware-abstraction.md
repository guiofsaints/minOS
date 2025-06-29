# NextUI Hardware Abstraction Layer

## Overview

NextUI implements a comprehensive Hardware Abstraction Layer (HAL) that provides a uniform interface for accessing device-specific features across different platforms. The HAL isolates platform-specific code and enables NextUI to run on multiple hardware configurations while maintaining consistent functionality.

## HAL Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Application Layer                      │
│              (NextUI, MinArch, Settings)                   │
├─────────────────────────────────────────────────────────────┤
│                    Common API Layer                        │
│           (api.h, Graphics, Audio, Input APIs)             │
├─────────────────────────────────────────────────────────────┤
│                Hardware Abstraction Layer                  │
│              (platform.h, platform.c)                      │
├─────────────────────────────────────────────────────────────┤
│                  Platform Implementations                  │
│           (Desktop: SDL2, TrimUI: Linux APIs)              │
├─────────────────────────────────────────────────────────────┤
│                     Hardware Layer                         │
│       (TrimUI SoC, Audio DAC, GPIO, Display Controller)    │
└─────────────────────────────────────────────────────────────┘
```

## Platform Abstraction Interface

### Core Platform Functions

The HAL defines a standard interface that all platforms must implement:

```c
// Platform initialization/cleanup
void PLAT_initInput(void);
void PLAT_quitInput(void);
SDL_Surface* PLAT_initVideo(void);
void PLAT_quitVideo(void);

// Hardware capability detection
typedef struct {
    char device_name[64];
    char platform_name[32];
    struct {
        bool has_wifi;
        bool has_bluetooth;
        bool has_leds;
        bool has_vibration;
        bool has_battery;
        bool has_rtc;
        bool has_hdmi;
    } capabilities;
    struct {
        int min_cpu_freq;
        int max_cpu_freq;
        int screen_width;
        int screen_height;
        int max_brightness;
        int led_count;
    } hardware_specs;
} PLAT_Context;

// Get platform context
PLAT_Context* PLAT_getContext(void);
```

### Platform-Specific Constants

Each platform defines hardware-specific constants:

```c
// TrimUI Platform (platform.h)
#define FIXED_SCALE     (is_brick?3:2)
#define FIXED_WIDTH     (is_brick?1024:1280)
#define FIXED_HEIGHT    (is_brick?768:720)
#define SCREEN_FPS      60.235
#define MAX_LIGHTS      4
#define SDCARD_PATH     "/mnt/SDCARD"

// Desktop Platform (platform.h)
#define FIXED_SCALE     3
#define FIXED_WIDTH     1024
#define FIXED_HEIGHT    768
#define SCREEN_FPS      60.0
#define MAX_LIGHTS      0
#define SDCARD_PATH     "/Library/Developer/Projects/private/MinUI_FAKESD"
```

## Input Abstraction

### Unified Input Interface

The HAL provides a unified interface for input handling across different input devices:

```c
// Input button mapping
typedef enum {
    BTN_UP = 0x001,
    BTN_DOWN = 0x002,
    BTN_LEFT = 0x004,
    BTN_RIGHT = 0x008,
    BTN_A = 0x010,
    BTN_B = 0x020,
    BTN_X = 0x040,
    BTN_Y = 0x080,
    BTN_L1 = 0x100,
    BTN_R1 = 0x200,
    BTN_SELECT = 0x400,
    BTN_START = 0x800,
    BTN_MENU = 0x1000,
    BTN_POWER = 0x2000
} ButtonCode;

// Platform input state
typedef struct {
    uint32_t is_pressed;
    uint32_t just_pressed;
    uint32_t just_released;
    uint32_t repeat_delay;
    uint32_t repeat_rate;
} InputState;
```

### Platform-Specific Input Implementation

#### TrimUI Input (GPIO + SDL Joystick)
```c
// TrimUI input initialization
void PLAT_initInput(void) {
    char *device = getenv("DEVICE");
    is_brick = exactMatch("brick", device);
    
    // Initialize SDL joystick subsystem
    SDL_InitSubSystem(SDL_INIT_JOYSTICK);
    joystick = SDL_JoystickOpen(0);
    
    // Configure GPIO for power button
    system("echo 116 > /sys/class/gpio/export");
    system("echo in > /sys/class/gpio/gpio116/direction");
    
    // Start input monitoring daemon
    trimui_inputd_start();
}

// TrimUI button mapping
int map_joystick_button(int sdl_button) {
    switch (sdl_button) {
        case JOY_A: return BTN_A;
        case JOY_B: return BTN_B;
        case JOY_X: return BTN_X;
        case JOY_Y: return BTN_Y;
        case JOY_L1: return BTN_L1;
        case JOY_R1: return BTN_R1;
        case JOY_SELECT: return BTN_SELECT;
        case JOY_START: return BTN_START;
        case JOY_MENU: return BTN_MENU;
        default: return BTN_NONE;
    }
}
```

#### Desktop Input (SDL2 Keyboard/Gamepad)
```c
// Desktop input initialization
void PLAT_initInput(void) {
    SDL_InitSubSystem(SDL_INIT_JOYSTICK | SDL_INIT_GAMECONTROLLER);
    
    // Initialize gamepad if available
    if (SDL_NumJoysticks() > 0) {
        gamepad = SDL_GameControllerOpen(0);
    }
    
    // Keyboard mapping for development
    setup_keyboard_mapping();
}

// Desktop keyboard mapping
int map_keyboard_key(SDL_Keycode key) {
    switch (key) {
        case SDLK_w: return BTN_UP;
        case SDLK_s: return BTN_DOWN;
        case SDLK_a: return BTN_LEFT;
        case SDLK_d: return BTN_RIGHT;
        case SDLK_j: return BTN_A;
        case SDLK_k: return BTN_B;
        case SDLK_SPACE: return BTN_SELECT;
        case SDLK_RETURN: return BTN_START;
        case SDLK_ESCAPE: return BTN_MENU;
        default: return BTN_NONE;
    }
}
```

## Display Abstraction

### Video Initialization

The HAL provides platform-independent video initialization:

```c
// Common video interface
SDL_Surface* PLAT_initVideo(void) {
    // Platform-specific implementation
    // Returns main rendering surface
}

void PLAT_quitVideo(void) {
    // Platform-specific cleanup
}

void PLAT_flip(SDL_Surface* screen, int sync) {
    // Present frame to display
    // sync: 0=immediate, 1=vsync
}
```

### Graphics Pipeline Abstraction

#### TrimUI Graphics (OpenGL ES + Framebuffer)
```c
// TrimUI video initialization
SDL_Surface* PLAT_initVideo(void) {
    char *device = getenv("DEVICE");
    is_brick = exactMatch("brick", device);
    
    // Initialize SDL video subsystem
    SDL_InitSubSystem(SDL_INIT_VIDEO);
    SDL_ShowCursor(0);
    
    // Create window and OpenGL context
    vid.window = SDL_CreateWindow("NextUI", 
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        is_brick ? 1024 : 1280, is_brick ? 768 : 720,
        SDL_WINDOW_OPENGL | SDL_WINDOW_FULLSCREEN);
    
    vid.gl_context = SDL_GL_CreateContext(vid.window);
    
    // Initialize OpenGL ES
    init_opengl_es();
    
    // Create main surface
    vid.screen = SDL_CreateRGBSurfaceWithFormat(0, 
        vid.width, vid.height, 32, SDL_PIXELFORMAT_RGBA8888);
    
    return vid.screen;
}

// OpenGL ES shader system
void init_opengl_es(void) {
    // Load vertex and fragment shaders
    GLuint vertex = load_shader(GL_VERTEX_SHADER, vertex_shader_source);
    GLuint fragment = load_shader(GL_FRAGMENT_SHADER, fragment_shader_source);
    
    // Link shader program
    shader_program = glCreateProgram();
    glAttachShader(shader_program, vertex);
    glAttachShader(shader_program, fragment);
    glLinkProgram(shader_program);
    
    // Setup vertex arrays
    setup_vertex_arrays();
}
```

#### Desktop Graphics (OpenGL + SDL2)
```c
// Desktop video initialization
SDL_Surface* PLAT_initVideo(void) {
    // Set OpenGL attributes
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
    
    // Initialize SDL video
    SDL_InitSubSystem(SDL_INIT_VIDEO);
    SDL_ShowCursor(0);
    
    // Create window
    vid.window = SDL_CreateWindow("NextUI Development",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        FIXED_WIDTH, FIXED_HEIGHT,
        SDL_WINDOW_OPENGL);
    
    vid.gl_context = SDL_GL_CreateContext(vid.window);
    
    // Initialize modern OpenGL
    init_opengl();
    
    vid.screen = SDL_CreateRGBSurfaceWithFormat(0,
        FIXED_WIDTH, FIXED_HEIGHT, 32, SDL_PIXELFORMAT_RGBA8888);
    
    return vid.screen;
}
```

## Audio Abstraction

### Audio System Interface

```c
// Audio initialization
void PLAT_initAudio(void);
void PLAT_quitAudio(void);

// Audio configuration
void PLAT_setAudioVolume(int volume);
int PLAT_getAudioVolume(void);
void PLAT_muteAudio(int mute);

// Audio quality settings
int PLAT_pickSampleRate(int requested, int max);
void PLAT_setAudioQuality(int quality);
```

### Platform-Specific Audio Implementation

#### TrimUI Audio (ALSA)
```c
// TrimUI audio initialization
void PLAT_initAudio(void) {
    // Configure ALSA device
    snd_pcm_t* pcm_handle;
    snd_pcm_hw_params_t* hw_params;
    
    int err = snd_pcm_open(&pcm_handle, "default", 
                          SND_PCM_STREAM_PLAYBACK, 0);
    if (err < 0) {
        LOG_error("Failed to open audio device: %s", snd_strerror(err));
        return;
    }
    
    // Configure hardware parameters
    snd_pcm_hw_params_alloca(&hw_params);
    snd_pcm_hw_params_any(pcm_handle, hw_params);
    snd_pcm_hw_params_set_access(pcm_handle, hw_params, 
                                SND_PCM_ACCESS_RW_INTERLEAVED);
    snd_pcm_hw_params_set_format(pcm_handle, hw_params, 
                                SND_PCM_FORMAT_S16_LE);
    snd_pcm_hw_params_set_channels(pcm_handle, hw_params, 2);
    
    unsigned int sample_rate = 48000;
    snd_pcm_hw_params_set_rate_near(pcm_handle, hw_params, 
                                   &sample_rate, 0);
    
    snd_pcm_hw_params(pcm_handle, hw_params);
}

// TrimUI volume control via sysfs
void PLAT_setAudioVolume(int volume) {
    int raw_volume = (volume * 255) / VOLUME_MAX;
    putInt("/sys/class/codec/volume", raw_volume);
}
```

#### Desktop Audio (SDL2)
```c
// Desktop audio initialization
void PLAT_initAudio(void) {
    SDL_AudioSpec want, have;
    SDL_zero(want);
    
    want.freq = 48000;
    want.format = AUDIO_S16LSB;
    want.channels = 2;
    want.samples = 1024;
    want.callback = audio_callback;
    
    audio_device = SDL_OpenAudioDevice(NULL, 0, &want, &have, 
                                      SDL_AUDIO_ALLOW_FREQUENCY_CHANGE);
    
    if (audio_device == 0) {
        LOG_error("Failed to open audio device: %s", SDL_GetError());
        return;
    }
    
    SDL_PauseAudioDevice(audio_device, 0);
}

// Desktop volume control
void PLAT_setAudioVolume(int volume) {
    // SDL2 doesn't have direct volume control
    // Volume is handled in the audio callback
    audio_volume = (float)volume / VOLUME_MAX;
}
```

## Power Management Abstraction

### Power Management Interface

```c
// CPU frequency control
void PLAT_setCPUSpeed(int speed);
int PLAT_getCPUSpeed(void);

// Power states
int PLAT_supportsDeepSleep(void);
int PLAT_deepSleep(void);
void PLAT_powerOff(void);

// Battery monitoring
void PLAT_getBatteryStatus(int* is_charging, int* charge);
void PLAT_getBatteryStatusFine(int* is_charging, int* charge);

// Display power
void PLAT_enableBacklight(int enable);
void PLAT_setBrightness(int brightness);
```

### Platform-Specific Power Implementation

#### TrimUI Power Management
```c
// TrimUI CPU frequency control
void PLAT_setCPUSpeed(int speed) {
    int freq = 0;
    switch (speed) {
        case CPU_SPEED_MENU:
            freq = 600000;
            break;
        case CPU_SPEED_NORMAL:
            freq = 1608000;
            break;
        case CPU_SPEED_PERFORMANCE:
            freq = 2000000;
            break;
    }
    
    // Set governor to userspace mode
    putFile("/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor", 
           "userspace");
    
    // Set frequency
    putInt("/sys/devices/system/cpu/cpu0/cpufreq/scaling_setspeed", freq);
}

// TrimUI battery monitoring via AXP2202 PMIC
void PLAT_getBatteryStatusFine(int* is_charging, int* charge) {
    *is_charging = getInt("/sys/class/power_supply/axp2202-usb/online");
    *charge = getInt("/sys/class/power_supply/axp2202-battery/capacity");
    
    // Additional voltage/current monitoring
    int voltage = getInt("/sys/class/power_supply/axp2202-battery/voltage_now");
    int current = getInt("/sys/class/power_supply/axp2202-battery/current_now");
    
    // Log detailed battery info
    LOG_debug("Battery: %d%%, %dmV, %dmA, charging=%d", 
              *charge, voltage/1000, current/1000, *is_charging);
}

// TrimUI power off sequence
void PLAT_powerOff(void) {
    // Haptic feedback if enabled
    if (CFG_getHaptics()) {
        VIB_singlePulse(VIB_bootStrength, VIB_bootDuration_ms);
    }
    
    // Clean shutdown sequence
    system("rm -f /tmp/nextui_exec && sync");
    sleep(2);
    
    // Mute audio and turn off display
    SetRawVolume(MUTE_VOLUME_RAW);
    PLAT_enableBacklight(0);
    
    // Cleanup resources
    SND_quit();
    VIB_quit();
    PWR_quit();
    GFX_quit();
    
    // Clear framebuffer and signal shutdown
    system("cat /dev/zero > /dev/fb0 2>/dev/null");
    touch("/tmp/poweroff");
    sync();
    exit(0);
}
```

#### Desktop Power Management (Simulation)
```c
// Desktop power management (simulated)
void PLAT_setCPUSpeed(int speed) {
    // No-op on desktop
    LOG_debug("CPU speed set to level %d (simulated)", speed);
}

void PLAT_getBatteryStatusFine(int* is_charging, int* charge) {
    // Simulate battery status
    *is_charging = 1;
    *charge = 100;
}

void PLAT_powerOff(void) {
    // Graceful exit on desktop
    SND_quit();
    VIB_quit();
    PWR_quit();
    GFX_quit();
    exit(0);
}
```

## Hardware Feature Abstraction

### LED Control Interface

```c
// LED control for devices with RGB LEDs
typedef struct {
    char name[64];
    char device[16];
    int max_brightness;
    uint32_t default_color;
    uint32_t current_color;
    int current_brightness;
} LightSettings;

void PLAT_initLeds(void);
void PLAT_setLED(int led, uint32_t color, int brightness);
void PLAT_setLEDEffect(int led, int effect, int duration);
```

#### TrimUI LED Implementation
```c
// TrimUI LED control via PWM
void PLAT_setLED(int led, uint32_t color, int brightness) {
    if (led >= MAX_LIGHTS) return;
    
    char path[256];
    int r = (color >> 16) & 0xFF;
    int g = (color >> 8) & 0xFF;
    int b = color & 0xFF;
    
    // Apply brightness scaling
    r = (r * brightness) / 100;
    g = (g * brightness) / 100;
    b = (b * brightness) / 100;
    
    // Write to PWM controllers
    snprintf(path, sizeof(path), "/sys/class/led_anim/led%d_r", led);
    putInt(path, r);
    snprintf(path, sizeof(path), "/sys/class/led_anim/led%d_g", led);
    putInt(path, g);
    snprintf(path, sizeof(path), "/sys/class/led_anim/led%d_b", led);
    putInt(path, b);
}
```

### Vibration Control Interface

```c
// Haptic feedback control
void PLAT_setRumble(int strength);
void PLAT_rumblePattern(int* pattern, int length);
```

#### TrimUI Vibration Implementation
```c
// TrimUI vibration control
void PLAT_setRumble(int strength) {
    #define MIN_VOLTAGE 500000
    #define MAX_VOLTAGE 3300000
    #define RUMBLE_GPIO_PATH "/sys/class/gpio/gpio227/value"
    #define RUMBLE_VOLTAGE_PATH "/sys/class/motor/voltage"
    
    int voltage = MAX_VOLTAGE;
    
    if (strength > 0 && strength < 0xFFFF) {
        voltage = MIN_VOLTAGE + 
                 (int)(strength * ((long long)(MAX_VOLTAGE - MIN_VOLTAGE) / 0xFFFF));
        putInt(RUMBLE_VOLTAGE_PATH, voltage);
    } else {
        putInt(RUMBLE_VOLTAGE_PATH, MAX_VOLTAGE);
    }
    
    // Enable/disable rumble motor
    putInt(RUMBLE_GPIO_PATH, (strength > 0) ? 1 : 0);
}
```

## Network Abstraction

### WiFi Interface

```c
// WiFi management interface
void PLAT_wifiInit(void);
bool PLAT_hasWifi(void);
bool PLAT_wifiEnabled(void);
void PLAT_wifiEnable(bool on);
int PLAT_wifiScan(struct WIFI_network* networks, int max);
void PLAT_wifiConnect(const char* ssid, const char* password);
void PLAT_wifiDisconnect(void);
bool PLAT_isOnline(void);
```

#### TrimUI WiFi Implementation
```c
// TrimUI WiFi via wpa_supplicant
void PLAT_wifiEnable(bool on) {
    if (on) {
        // Enable WiFi hardware
        system("rfkill unblock wifi");
        system("ifconfig wlan0 up");
        system("/etc/init.d/wpa_supplicant enable");
        system("/etc/init.d/wpa_supplicant start&");
        
        // Initialize WiFi interface
        wifi.interface = aw_wifi_on(wifi_state_handle, event_label);
        if (wifi.interface != NULL) {
            wifi.enabled = true;
        }
    } else {
        // Disable WiFi
        system("rfkill block wifi");
        system("/etc/init.d/wpa_supplicant stop&");
        
        if (wifi.interface) {
            aw_wifi_off(wifi.interface);
            wifi.interface = NULL;
        }
        wifi.enabled = false;
    }
}

int PLAT_wifiScan(struct WIFI_network* networks, int max) {
    if (!wifi.interface) return 0;
    
    // Trigger scan
    wifi.interface->start_scan();
    
    // Wait for results
    sleep(2);
    
    // Get scan results
    return wifi.interface->get_scan_results(networks, max);
}
```

## Platform Detection and Runtime Adaptation

### Device Detection

```c
// Runtime device detection
typedef enum {
    DEVICE_UNKNOWN,
    DEVICE_TRIMUI_SMART_PRO,
    DEVICE_TRIMUI_BRICK,
    DEVICE_DESKTOP
} DeviceType;

DeviceType detect_device_type(void) {
    // Check environment variables
    char* device = getenv("DEVICE");
    if (device) {
        if (exactMatch("brick", device)) {
            return DEVICE_TRIMUI_BRICK;
        }
    }
    
    // Check device tree
    char model[256];
    if (getFile("/proc/device-tree/model", model, sizeof(model)) > 0) {
        if (strstr(model, "TrimUI")) {
            return is_brick ? DEVICE_TRIMUI_BRICK : DEVICE_TRIMUI_SMART_PRO;
        }
    }
    
    // Check for desktop environment
    if (getenv("DISPLAY") || getenv("WAYLAND_DISPLAY")) {
        return DEVICE_DESKTOP;
    }
    
    return DEVICE_UNKNOWN;
}
```

### Runtime Configuration Adaptation

```c
// Adapt configuration based on detected hardware
void adapt_to_hardware(DeviceType device) {
    switch (device) {
        case DEVICE_TRIMUI_BRICK:
            is_brick = 1;
            device_width = 1024;
            device_height = 768;
            device_scale = 3;
            enable_leds = true;
            enable_wifi = true;
            break;
            
        case DEVICE_TRIMUI_SMART_PRO:
            is_brick = 0;
            device_width = 1280;
            device_height = 720;
            device_scale = 2;
            enable_leds = true;
            enable_wifi = true;
            break;
            
        case DEVICE_DESKTOP:
            is_brick = 0;
            device_width = 1024;
            device_height = 768;
            device_scale = 3;
            enable_leds = false;
            enable_wifi = false;
            break;
    }
}
```

## HAL Testing and Validation

### Platform Capability Testing

```c
// Test hardware capabilities at startup
int test_platform_capabilities(void) {
    int errors = 0;
    
    // Test display
    if (!PLAT_initVideo()) {
        LOG_error("Display test failed");
        errors++;
    }
    
    // Test input
    PLAT_initInput();
    if (!test_input_response()) {
        LOG_warn("Input test failed");
    }
    
    // Test audio
    PLAT_initAudio();
    if (!test_audio_output()) {
        LOG_warn("Audio test failed");
    }
    
    // Test platform-specific features
    if (enable_leds && !test_led_control()) {
        LOG_warn("LED test failed");
    }
    
    if (enable_wifi && !test_wifi_hardware()) {
        LOG_warn("WiFi test failed");
    }
    
    return errors;
}
```

## Fallback Implementations

The HAL provides fallback implementations for optional features:

```c
// Weak symbol fallbacks for optional features
FALLBACK_IMPLEMENTATION void PLAT_setRumble(int strength) {
    // No-op if platform doesn't support vibration
}

FALLBACK_IMPLEMENTATION void PLAT_setLED(int led, uint32_t color, int brightness) {
    // No-op if platform doesn't support LEDs
}

FALLBACK_IMPLEMENTATION int PLAT_supportsDeepSleep(void) {
    return 0; // Default: no deep sleep support
}
```

This comprehensive HAL design allows NextUI to maintain consistent functionality across different hardware platforms while efficiently utilizing platform-specific features where available.
