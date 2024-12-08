#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <signal.h>
#include <time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/sysinfo.h>
#include "../include/ghostc.h"

#define MONITOR_INTERVAL 5  // seconds
#define LOG_FILE "/var/log/ghostc-monitor.log"

static volatile int running = 1;

// Signal handler
static void handle_signal(int sig) {
    running = 0;
}

// Get CPU temperature (Pi Zero W specific)
static float get_cpu_temp(void) {
    FILE *f = fopen("/sys/class/thermal/thermal_zone0/temp", "r");
    if (!f) return -1;
    
    int temp;
    fscanf(f, "%d", &temp);
    fclose(f);
    
    return temp / 1000.0f;  // Convert to Celsius
}

// Get CPU frequency
static int get_cpu_freq(void) {
    FILE *f = fopen("/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq", "r");
    if (!f) return -1;
    
    int freq;
    fscanf(f, "%d", &freq);
    fclose(f);
    
    return freq / 1000;  // Convert to MHz
}

// Get memory usage
static void get_memory_usage(unsigned long *total, unsigned long *used) {
    struct sysinfo si;
    if (sysinfo(&si) < 0) {
        *total = *used = 0;
        return;
    }
    
    *total = si.totalram / (1024*1024);  // Convert to MB
    *used = (si.totalram - si.freeram) / (1024*1024);
}

// Monitor system status
static void monitor_system(void) {
    FILE *log = fopen(LOG_FILE, "a");
    if (!log) {
        fprintf(stderr, "Failed to open log file\n");
        return;
    }
    
    time_t now = time(NULL);
    float temp = get_cpu_temp();
    int freq = get_cpu_freq();
    unsigned long total_mem, used_mem;
    get_memory_usage(&total_mem, &used_mem);
    
    fprintf(log, "[%s] CPU: %.1f°C @ %dMHz, Memory: %luMB/%luMB\n",
            ctime(&now), temp, freq, used_mem, total_mem);
    
    // Check temperature threshold
    if (temp > 80.0f) {
        fprintf(log, "WARNING: High temperature detected!\n");
        system("echo 1 > /sys/class/leds/led0/brightness");  // Blink LED
    }
    
    // Check memory threshold
    if (used_mem > total_mem * 0.9) {
        fprintf(log, "WARNING: High memory usage!\n");
        system("sync && echo 3 > /proc/sys/vm/drop_caches");  // Free caches
    }
    
    fclose(log);
}

int main(void) {
    // Setup signal handlers
    signal(SIGTERM, handle_signal);
    signal(SIGINT, handle_signal);
    
    printf("GhostC System Monitor Started\n");
    
    while (running) {
        monitor_system();
        sleep(MONITOR_INTERVAL);
    }
    
    printf("GhostC System Monitor Stopped\n");
    return 0;
}
