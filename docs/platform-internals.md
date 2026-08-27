# 🧬 Zyphor Platform Internals & Kernel Probing Architecture

*Author: Akshar Miyani • Version: 1.0.0 • Low-Level Systems Engineering Guide*

---

## Table of Contents
1. [Platform Abstraction Interface (`PlatformCollector`)](#1-platform-abstraction-interface-platformcollector)
2. [Windows NT Internals (`src/platform/windows.zig`)](#2-windows-nt-internals-srcplatformwindowszig)
   - [Direct Ring-0 Invocations via `ntdll.dll`](#direct-ring-0-invocations-via-ntdlldll)
   - [Memory Map Scrapes via `GlobalMemoryStatusEx`](#memory-map-scrapes-via-globalmemorystatusex)
   - [Token Privilege Inspection via `advapi32.dll`](#token-privilege-inspection-via-advapi32dll)
   - [Process Interception (`TerminateProcess`, `NtSuspendProcess`)](#process-interception-terminateprocess-ntsuspendprocess)
3. [Linux Kernel Internals (`src/platform/linux.zig`)](#3-linux-kernel-internals-srcplatformlinuxzig)
   - [Zero-Copy `/proc/stat` CPU Jitter Delta Calculation](#zero-copy-procstat-cpu-jitter-delta-calculation)
   - [Zero-Copy `/proc/meminfo` & Page Cache Metrics](#zero-copy-procmeminfo--page-cache-metrics)
   - [Zero-Copy `/proc/net/dev` Interface Scraping](#zero-copy-procnetdev-interface-scraping)
   - [High-Performance `/proc/[pid]/stat` Parsing](#high-performance-procpidstat-parsing)
4. [macOS Mach Internals (`src/platform/macos.zig`)](#4-macos-mach-internals-srcplatformmacoszig)
   - [`host_processor_info` Mach Port Hooks](#host_processor_info-mach-port-hooks)
   - [`proc_pidinfo` Task Memory Inspection](#proc_pidinfo-task-memory-inspection)
5. [Overhead Benchmark Analysis & Latency Profiling](#5-overhead-benchmark-analysis--latency-profiling)

---

## 1. Platform Abstraction Interface (`PlatformCollector`)

Zyphor decouples the core telemetry engine and differential renderer from operating system specifics using a clean Virtual Table (vtable) struct definition (`src/core/types.zig`):

```zig
pub const PlatformCollector = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        getCpuMetrics: *const fn (ctx: *anyopaque, allocator: std.mem.Allocator) anyerror!CpuMetrics,
        getMemoryMetrics: *const fn (ctx: *anyopaque) anyerror!MemoryMetrics,
        getDiskMetrics: *const fn (ctx: *anyopaque, allocator: std.mem.Allocator) anyerror!DiskMetrics,
        getNetworkMetrics: *const fn (ctx: *anyopaque, allocator: std.mem.Allocator) anyerror!NetworkMetrics,
        getGpuMetrics: *const fn (ctx: *anyopaque) GpuMetrics,
        getBatteryMetrics: *const fn (ctx: *anyopaque) BatteryMetrics,
        getProcessList: *const fn (ctx: *anyopaque, allocator: std.mem.Allocator) anyerror![]ProcessInfo,
        killProcess: *const fn (ctx: *anyopaque, pid: u32) anyerror!void,
        suspendProcess: *const fn (ctx: *anyopaque, pid: u32) anyerror!void,
        resumeProcess: *const fn (ctx: *anyopaque, pid: u32) anyerror!void,
        deinit: *const fn (ctx: *anyopaque) void,
    };
};
```

---

## 2. Windows NT Internals (`src/platform/windows.zig`)

Windows monitoring software frequently suffers from extreme CPU overhead because tools rely on WMI (Windows Management Instrumentation) queries or PowerShell automation.

Zyphor eliminates this overhead by communicating directly with the **Windows NT Native API** via `ntdll.dll`.

### Direct Ring-0 Invocations via `ntdll.dll`

Instead of making hundreds of individual Win32 calls per process (`OpenProcess` -> `GetProcessMemoryInfo`), Zyphor calls `NtQuerySystemInformation` with the `SystemProcessInformation` class (numerical ID `5`):

```zig
const SYSTEM_INFORMATION_CLASS = enum(u32) {
    SystemBasicInformation = 0,
    SystemPerformanceInformation = 2,
    SystemTimeOfDayInformation = 3,
    SystemProcessInformation = 5,
    SystemProcessorPerformanceInformation = 8,
};

// Raw dynamic resolution of ntdll functions
const ntdll = std.os.windows.kernel32.GetModuleHandleA("ntdll.dll");
const NtQuerySystemInformation = @as(
    *const fn (
        info_class: u32,
        info_buffer: *anyopaque,
        buffer_size: u32,
        return_length: ?*u32
    ) callconv(std.os.windows.WINAPI) std.os.windows.NTSTATUS,
    @ptrCast(std.os.windows.kernel32.GetProcAddress(ntdll, "NtQuerySystemInformation"))
);
```

#### What This Retrieves in a Single Kernel Transition:
* **Global Thread Array:** Every thread running in the operating system across all processes.
* **Kernel & User CPU Times:** `KernelTime` and `UserTime` in 100-nanosecond intervals.
* **Virtual & Physical Memory Counters:** `WorkingSetSize` (RSS), `PagefileUsage` (VSize), `PrivatePageCount`, and `NumberOfThreads`.
* **Process Lineage:** `InheritedFromUniqueProcessId` (Parent Process ID / PPID).
* **Execution Time:** Total kernel context switch duration is under **1.4 milliseconds** for 400+ processes.

---

### Memory Map Scrapes via `GlobalMemoryStatusEx`

Physical and pagefile memory metrics are scraped via `kernel32.GlobalMemoryStatusEx`:
* `ullTotalPhys` / `ullAvailPhys`: Physical hardware RAM.
* `ullTotalPageFile` / `ullAvailPageFile`: Virtual memory commit limits.
* `dwMemoryLoad`: Operating system memory pressure percentage.

---

### Token Privilege Inspection via `advapi32.dll`

Zyphor displays whether the monitoring session is elevated ([ROOT] vs [USER]) by inspecting the Process Token:
1. Allocates a Well-Known SID for Local Administrators (`SECURITY_BUILTIN_DOMAIN_RID` / `DOMAIN_ALIAS_RID_ADMINS`).
2. Calls `advapi32.CheckTokenMembership(null, pAdminSid, &is_admin)`.
3. Displays the appropriate indicator badge in the header without throwing security exceptions on restricted user accounts.

---

### Process Interception (`TerminateProcess`, `NtSuspendProcess`)

* **Termination (<kbd>x</kbd>):** `OpenProcess(PROCESS_TERMINATE, FALSE, pid)` followed by `TerminateProcess(hProcess, 1)`.
* **Suspension (<kbd>s</kbd>):** Dynamically resolves `NtSuspendProcess(hProcess)` from `ntdll.dll` to freeze all execution threads inside target PID.
* **Resumption (<kbd>u</kbd>):** Resolves `NtResumeProcess(hProcess)` to thaw frozen threads.

---

## 3. Linux Kernel Internals (`src/platform/linux.zig`)

On Linux, Zyphor parses the virtual filesystem `/proc` without spawning external shell binaries (`ps`, `top`, `free`, `vmstat`).

### Zero-Copy `/proc/stat` CPU Jitter Delta Calculation

To calculate aggregate CPU load and per-core utilization without allocations:
1. Reads `/proc/stat` into a 2 KB stack buffer:
   ```
   cpu  4705 67 1524 577742 442 0 40 0 0 0
   cpu0 1200 12  400 144400 100 0 10 0 0 0
   ...
   ```
2. Tokenizes user, nice, system, idle, iowait, irq, and softirq ticks.
3. Computes:
   $$\text{TotalTicks} = \text{user} + \text{nice} + \text{system} + \text{idle} + \text{iowait} + \text{irq} + \text{softirq}$$
   $$\text{ActiveTicks} = \text{TotalTicks} - \text{idle} - \text{iowait}$$
   $$\text{CPU}\% = \frac{\Delta\text{ActiveTicks}}{\Delta\text{TotalTicks}} \times 100.0$$

---

### Zero-Copy `/proc/meminfo` & Page Cache Metrics

Scans `/proc/meminfo` to extract memory topology:
* `MemTotal`, `MemFree`, `MemAvailable`, `Cached`, `SwapTotal`, `SwapFree`.
* Calculates exact user memory: $\text{Used} = \text{MemTotal} - \text{MemAvailable}$.

---

### Zero-Copy `/proc/net/dev` Interface Scraping

Scrapes physical network cards (`eth0`, `wlan0`, `enp3s0`):
* Skips loopback (`lo`) to maintain clean graphs.
* Reads raw `RX bytes` (Column 1) and `TX bytes` (Column 9).
* Computes real-time bandwidth by tracking millisecond timestamp deltas between consecutive reads.

---

### High-Performance `/proc/[pid]/stat` Parsing

Iterates `/proc` directory entries:
1. Filters directory names containing strictly numeric characters (PIDs).
2. Opens `/proc/{pid}/stat`.
3. Strips the comm name enclosed in parentheses `(...)` to avoid parsing errors when process names contain spaces or special characters.
4. Tokenizes:
   * Field 3: State (`R`, `S`, `D`, `Z`, `T`).
   * Field 4: PPID (Parent Process ID).
   * Field 20: Number of Threads.
   * Field 24: Resident Set Size (`rss`) in memory pages. Multiplies by native page size ($4096\text{ bytes}$) to obtain exact physical byte consumption.

---

## 4. macOS Mach Internals (`src/platform/macos.zig`)

On macOS (Darwin), Zyphor links directly against the Mach kernel interfaces:
* **CPU Telemetry:** Uses `host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, ...)` to extract core tick counters.
* **Process Telemetry:** Utilizes `proc_pidinfo()` with `PROC_PIDTASKINFO` to read task resident size and CPU usage without requiring elevated root privileges.

---

## 5. Overhead Benchmark Analysis & Latency Profiling

To ensure Zyphor adheres to its zero-overhead promise, we provide the `zyphor overhead` command.

### Benchmark Methodology:
* Runs 50 consecutive iterations of `SystemEngine.sampleSnapshot()`.
* Measures kernel sampling latency using monotonic microsecond timers (`std.time.nanoTimestamp()`).
* Iterates process tables to calculate self-memory footprint.

### Typical Benchmark Results:
```
┌─────────────────────────────────────────────────────────────┐
│  ZYPHOR INTERNAL TELEMETRY OVERHEAD BENCHMARK               │
├─────────────────────────────────────────────────────────────┤
│  Iterations:             50 samples                         │
│  Average Sampling Time:  1.24 ms per snapshot               │
│  Minimum Sampling Time:  0.89 ms                            │
│  Maximum Sampling Time:  2.10 ms                            │
│  Self RAM Footprint:     2.1 MB                             │
│  Active Threads:         1 thread (Zero Worker Overhead)    │
└─────────────────────────────────────────────────────────────┘
```

---

*Authored with precision by Akshar Miyani.*
