# minOS Interrupt Handling

## Overview

minOS firmware operates on Linux-based embedded systems where interrupt handling is primarily managed by the kernel. The firmware interacts with hardware interrupts through device drivers, signal handlers, and hardware abstraction layers.

## Interrupt Architecture

### Kernel-Level Interrupts

The Linux kernel handles all hardware interrupts and exposes them to userspace through various mechanisms:

1. **Signal-based notifications**
2. **File descriptor events (epoll/select)**
3. **Device-specific interfaces**
4. **Memory-mapped register polling**

### User-Space Interrupt Handling

```c
// Signal handler registration
void setup_signal_handlers(void) {
    signal(SIGINT, handle_interrupt);
    signal(SIGTERM, handle_shutdown);
    signal(SIGUSR1, handle_suspend);
    signal(SIGUSR2, handle_resume);
}
```

## Hardware Interrupt Sources

### TrimUI Hardware Interrupts

| IRQ | Source | Priority | Handler | Purpose |
|-----|--------|----------|---------|---------|
| **GPIO** | Button press/release | High | Input daemon | User input |
| **I2C** | Power management | High | Battery monitor | Power events |
| **TIMER** | Periodic wake | Medium | CPU monitor | Performance scaling |
| **AUDIO** | Buffer underrun | Medium | Audio thread | Audio quality |
| **DMA** | Transfer complete | Medium | Video driver | Frame rendering |
| **UART** | Debug console | Low | Logging | Development |

### Power Management Interrupts

```c
// Power button interrupt handling
static void handle_power_interrupt(int sig) {
    static time_t last_press = 0;
    time_t current_time = time(NULL);
    
    if (current_time - last_press < 2) {
        // Double-press: immediate shutdown
        system("poweroff");
    } else {
        // Single press: request shutdown
        power_requested = 1;
    }
    
    last_press = current_time;
}

// Register power button handler
void init_power_handling(void) {
    signal(SIGPWR, handle_power_interrupt);
    
    // Enable power button interrupts
    int power_fd = open("/dev/input/event0", O_RDONLY);
    fcntl(power_fd, F_SETFL, O_NONBLOCK);
}
```

### Input Interrupts

The input system uses a combination of polling and interrupt-driven input:

```c
// Input event structure
struct input_event {
    struct timeval time;
    uint16_t type;
    uint16_t code;
    int32_t value;
};

// Interrupt-driven input handling
void handle_input_event(struct input_event* event) {
    switch (event->type) {
        case EV_KEY:
            handle_key_event(event->code, event->value);
            break;
        case EV_ABS:
            handle_analog_event(event->code, event->value);
            break;
        case EV_SYN:
            process_input_frame();
            break;
    }
}

// Input polling thread
int input_thread(void* data) {
    int input_fd = open("/dev/input/event1", O_RDONLY);
    
    while (running) {
        struct input_event event;
        if (read(input_fd, &event, sizeof(event)) == sizeof(event)) {
            handle_input_event(&event);
        }
    }
    
    close(input_fd);
    return 0;
}
```

## Real-Time Signal Handling

### Audio Interrupts

Audio processing uses real-time signals for low-latency operation:

```c
// Real-time audio signal handler
void audio_signal_handler(int sig, siginfo_t* info, void* context) {
    if (sig == SIGRTMIN + 1) {
        // Audio buffer underrun
        audio_underruns++;
        
        // Fill buffer with silence to prevent artifacts
        memset(audio_current_buffer, 0, audio_buffer_size);
        
        // Signal audio thread to refill
        sem_post(&audio_refill_sem);
    }
}

// Setup real-time audio handling
void init_audio_interrupts(void) {
    struct sigaction sa;
    sa.sa_sigaction = audio_signal_handler;
    sa.sa_flags = SA_SIGINFO | SA_RESTART;
    sigemptyset(&sa.sa_mask);
    
    sigaction(SIGRTMIN + 1, &sa, NULL);
}
```

### Display Refresh Interrupts

Vertical blank interrupts for display synchronization:

```c
// VBlank interrupt handler
void vblank_handler(int sig) {
    frame_ready = 1;
    
    // Update performance counters
    static uint64_t last_vblank = 0;
    uint64_t current_time = get_time_us();
    
    if (last_vblank > 0) {
        frame_time_us = current_time - last_vblank;
        actual_fps = 1000000.0 / frame_time_us;
    }
    
    last_vblank = current_time;
}

// Register VBlank handler
void init_display_sync(void) {
    signal(SIGRTMIN + 2, vblank_handler);
    
    // Enable VBlank interrupts in driver
    int fb_fd = open("/dev/fb0", O_RDWR);
    ioctl(fb_fd, FBIO_WAITFORVSYNC, 0);
}
```

## Thread-Safe Interrupt Context

### Interrupt-Safe Data Structures

```c
// Atomic flag for interrupt communication
static volatile sig_atomic_t shutdown_requested = 0;
static volatile sig_atomic_t suspend_requested = 0;
static volatile sig_atomic_t battery_low = 0;

// Interrupt-safe queue for events
#define EVENT_QUEUE_SIZE 64
static struct {
    volatile int head;
    volatile int tail;
    volatile int count;
    struct event_data events[EVENT_QUEUE_SIZE];
    SDL_mutex* mutex;
} event_queue;

// Safe event posting from interrupt context
void post_event_from_interrupt(int type, int data) {
    // Atomic check for queue space
    if (event_queue.count >= EVENT_QUEUE_SIZE - 1) {
        return; // Queue full, drop event
    }
    
    // Add event atomically
    event_queue.events[event_queue.head].type = type;
    event_queue.events[event_queue.head].data = data;
    event_queue.events[event_queue.head].timestamp = get_time_us();
    
    // Update head pointer atomically
    event_queue.head = (event_queue.head + 1) % EVENT_QUEUE_SIZE;
    __sync_fetch_and_add(&event_queue.count, 1);
}
```

### Signal Masks for Thread Safety

```c
// Block signals in worker threads
void setup_thread_signal_mask(void) {
    sigset_t set;
    
    // Block all signals except critical ones
    sigfillset(&set);
    sigdelset(&set, SIGSEGV);
    sigdelset(&set, SIGFPE);
    sigdelset(&set, SIGILL);
    
    pthread_sigmask(SIG_BLOCK, &set, NULL);
}

// Main thread handles all signals
void main_thread_signal_setup(void) {
    sigset_t set;
    
    // Allow all signals in main thread
    sigemptyset(&set);
    pthread_sigmask(SIG_SETMASK, &set, NULL);
    
    // Setup signal handlers
    setup_signal_handlers();
}
```

## Hardware-Specific Interrupts

### GPIO Interrupts (TrimUI)

```c
// GPIO interrupt configuration
void setup_gpio_interrupts(void) {
    // Export GPIO pins for interrupt use
    system("echo 116 > /sys/class/gpio/export");  // Power button
    system("echo 243 > /sys/class/gpio/export");  // Volume button
    
    // Configure as input with interrupts
    system("echo in > /sys/class/gpio/gpio116/direction");
    system("echo in > /sys/class/gpio/gpio243/direction");
    system("echo falling > /sys/class/gpio/gpio116/edge");
    system("echo both > /sys/class/gpio/gpio243/edge");
    
    // Setup polling for GPIO events
    setup_gpio_polling();
}

// GPIO event polling
int gpio_poll_thread(void* data) {
    struct pollfd fds[2];
    
    // Power button
    fds[0].fd = open("/sys/class/gpio/gpio116/value", O_RDONLY);
    fds[0].events = POLLPRI;
    
    // Volume button
    fds[1].fd = open("/sys/class/gpio/gpio243/value", O_RDONLY);
    fds[1].events = POLLPRI;
    
    while (running) {
        int ret = poll(fds, 2, 1000);  // 1 second timeout
        
        if (ret > 0) {
            if (fds[0].revents & POLLPRI) {
                handle_power_button();
            }
            if (fds[1].revents & POLLPRI) {
                handle_volume_button();
            }
        }
    }
    
    close(fds[0].fd);
    close(fds[1].fd);
    return 0;
}
```

### I2C Interrupts for Power Management

```c
// I2C interrupt handling for battery monitoring
void setup_battery_interrupts(void) {
    int i2c_fd = open("/dev/i2c-0", O_RDWR);
    
    // Configure battery management IC
    ioctl(i2c_fd, I2C_SLAVE, 0x34);  // AXP2202 address
    
    // Enable battery low interrupt
    uint8_t reg_data = 0x01;
    write(i2c_fd, &reg_data, 1);
    
    // Setup interrupt monitoring
    setup_i2c_polling(i2c_fd);
}

// Battery interrupt handler
void handle_battery_interrupt(void) {
    static int low_battery_count = 0;
    
    int charge = get_battery_charge();
    
    if (charge < 5) {
        low_battery_count++;
        if (low_battery_count > 3) {
            // Emergency shutdown
            LOG_warn("Critical battery level, shutting down");
            system("poweroff");
        }
    } else {
        low_battery_count = 0;
    }
    
    // Update battery status
    battery_charge = charge;
    battery_update_requested = 1;
}
```

## Timer Interrupts

### System Timer for Performance Monitoring

```c
// Timer interrupt for CPU monitoring
void setup_performance_timer(void) {
    struct itimerval timer;
    
    // Setup periodic timer (every 100ms)
    timer.it_value.tv_sec = 0;
    timer.it_value.tv_usec = 100000;
    timer.it_interval.tv_sec = 0;
    timer.it_interval.tv_usec = 100000;
    
    signal(SIGALRM, performance_timer_handler);
    setitimer(ITIMER_REAL, &timer, NULL);
}

// Performance monitoring timer handler
void performance_timer_handler(int sig) {
    static uint64_t last_cpu_time = 0;
    static uint64_t last_real_time = 0;
    
    uint64_t current_cpu = get_process_cpu_time();
    uint64_t current_real = get_real_time();
    
    if (last_real_time > 0) {
        uint64_t cpu_delta = current_cpu - last_cpu_time;
        uint64_t real_delta = current_real - last_real_time;
        
        current_cpu_usage = (double)cpu_delta / real_delta * 100.0;
        
        // Trigger CPU scaling if needed
        if (current_cpu_usage > 90.0) {
            request_cpu_boost();
        } else if (current_cpu_usage < 30.0) {
            request_cpu_lower();
        }
    }
    
    last_cpu_time = current_cpu;
    last_real_time = current_real;
}
```

## Interrupt Latency Optimization

### Priority and Affinity Settings

```c
// Set high priority for critical threads
void set_thread_priority(pthread_t thread, int priority) {
    struct sched_param param;
    param.sched_priority = priority;
    
    pthread_setschedparam(thread, SCHED_FIFO, &param);
}

// Set CPU affinity for interrupt handling
void set_interrupt_affinity(void) {
    cpu_set_t cpuset;
    
    // Bind interrupt handling to CPU 0
    CPU_ZERO(&cpuset);
    CPU_SET(0, &cpuset);
    
    sched_setaffinity(0, sizeof(cpuset), &cpuset);
}
```

### Interrupt Coalescing

```c
// Coalesce rapid input events
void coalesce_input_events(void) {
    static uint64_t last_event_time = 0;
    static int pending_events = 0;
    
    uint64_t current_time = get_time_us();
    
    // If events are coming too rapidly, batch them
    if (current_time - last_event_time < 1000) {  // 1ms
        pending_events++;
        return;
    }
    
    // Process batched events
    if (pending_events > 0) {
        process_input_batch(pending_events);
        pending_events = 0;
    }
    
    last_event_time = current_time;
}
```

## Error Handling in Interrupt Context

### Safe Error Reporting

```c
// Interrupt-safe error logging
void interrupt_safe_log(int level, const char* message) {
    // Use atomic write to avoid corruption
    static char log_buffer[256];
    
    int len = snprintf(log_buffer, sizeof(log_buffer), 
                      "[IRQ] %s\n", message);
    
    // Atomic write to stderr
    write(STDERR_FILENO, log_buffer, len);
}

// Error recovery in interrupt context
void interrupt_error_recovery(int error_code) {
    switch (error_code) {
        case IRQ_BUFFER_OVERFLOW:
            // Reset buffers
            reset_interrupt_buffers();
            break;
            
        case IRQ_HARDWARE_FAULT:
            // Request system reset
            shutdown_requested = 1;
            break;
            
        case IRQ_TIMING_VIOLATION:
            // Adjust timing parameters
            adjust_interrupt_timing();
            break;
    }
}
```

## Performance Monitoring

### Interrupt Statistics

```c
// Interrupt performance tracking
struct interrupt_stats {
    uint64_t total_interrupts;
    uint64_t missed_interrupts;
    uint64_t max_latency_us;
    uint64_t avg_latency_us;
    uint64_t last_timestamp;
} irq_stats;

// Update interrupt statistics
void update_interrupt_stats(uint64_t latency_us) {
    irq_stats.total_interrupts++;
    
    if (latency_us > irq_stats.max_latency_us) {
        irq_stats.max_latency_us = latency_us;
    }
    
    // Moving average
    irq_stats.avg_latency_us = 
        (irq_stats.avg_latency_us * 0.9) + (latency_us * 0.1);
}
```
