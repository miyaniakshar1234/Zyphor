# Platform Internals & Kernel Telemetry

Zyphor interfaces directly with native operating system APIs and kernel interfaces to extract performance metrics with zero intermediary bloat.

---

## 🪟 Windows Subsystem Architecture

On Windows, Zyphor bypasses slow WMI queries and uses direct NT syscalls and Win32 performance interfaces:

### 1. Process & Thread Enumeration (`NtQuerySystemInformation`)
* **API:** `NtQuerySystemInformation(SystemProcessInformation, ...)`
* **Advantage:** Retrieves the complete snapshot of all running processes, thread counts, kernel/user execution times, virtual memory, private working set, and I/O transfer counters in a **single syscall**.
* **Performance:** `< 2ms` for 400+ processes vs `~80ms` for classic `Toolhelp32` + `EnumProcesses`.

### 2. Memory & Pagefile Telemetry
* **API:** `GlobalMemoryStatusEx`
* **Data:** Physical total/available RAM, committed memory, system-wide pagefile limits.

### 3. CPU Core Ticks & Frequency
* **APIs:** `GetSystemTimes`, `CallNtPowerInformation`
* **Data:** Per-core idle/kernel/user tick deltas, nominal vs current core clock frequency.

### 4. Network Adapter Telemetry
* **API:** `GetIfTable2` (IP Helper API)
* **Data:** Per-interface RX/TX bytes, packets, unicast throughput, link speed, physical media type.

---

## 🐧 Linux Subsystem Architecture

On Linux, Zyphor parses the virtual filesystems (`/proc` and `/sys`) with high-speed, zero-copy buffer scanning:

### 1. CPU & Memory
* `/proc/stat`: Batch-reads aggregate and per-cpu user, nice, system, idle, iowait, irq, softirq, steal deltas.
* `/proc/meminfo`: Extracts `MemTotal`, `MemFree`, `MemAvailable`, `Buffers`, `Cached`, `SwapTotal`, `SwapFree`.

### 2. Process Telemetry
* `/proc/[pid]/stat`: Reads utime, stime, priority, nice, num_threads, starttime, vsize, rss.
* `/proc/[pid]/io`: Per-process read_bytes and write_bytes counters.
* `/proc/net/dev`: Interface byte throughput.

### 3. Thermal & Power Sensors
* `/sys/class/thermal/thermal_zone*/temp`
* `/sys/class/hwmon/hwmon*/temp*_input`
* `/sys/class/power_supply/BAT*/capacity`, `/sys/class/power_supply/BAT*/status`

---

## 🍎 macOS Subsystem Architecture

On macOS (Darwin), Zyphor queries Mach kernel traps and BSD sysctl:

### 1. CPU & Topology
* `host_processor_info(PROCESSOR_CPU_LOAD_INFO)` for per-core tick counters.
* `sysctlbyname("hw.cpufrequency")`, `sysctlbyname("hw.logicalcpu")`.

### 2. Process Table
* `proc_listpids(PROC_ALL_PIDS)`
* `proc_pidinfo(PID, PROC_PIDTASKINFO)` for RSS memory, virtual memory, user/system runtime.

### 3. Sensors & Power
* `IOKit` / `IOPMPowerSource` for battery percentage, charging state, wattage, and cycle count.
