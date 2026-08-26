# Platform Internals & Kernel Telemetry

Zyphor interfaces directly with native operating system APIs and kernel interfaces to extract performance metrics with zero intermediary bloat or daemon dependencies.

---

## 🪟 Windows NT Kernel Probes

On Windows, Zyphor utilizes direct Win32/NT APIs rather than slow WMI (Windows Management Instrumentation) or PowerShell wrappers:

### 1. CPU Telemetry & System Times
* **API:** `GetSystemTimes(&idle_time, &kernel_time, &user_time)`
* **Algorithm:** Takes differential time deltas between successive sampling ticks.
  $$\text{Total Load} = 1.0 - \frac{\Delta \text{Idle}}{\Delta \text{Kernel} + \Delta \text{User}}$$
* **Topology:** Dispatches `GetSystemInfo` to determine logical and physical core topologies.

### 2. Memory & Virtual Address Space
* **API:** `GlobalMemoryStatusEx(&MEMORYSTATUSEX)`
* Extracts `ullTotalPhys`, `ullAvailPhys`, `ullTotalPageFile`, `ullAvailPageFile`, and `dwMemoryLoad`.
* Memory pressure is computed by comparing available physical pages against commit charge limits.

### 3. Process Table Snapshotting
* **API:** `CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)` with `Process32FirstW` / `Process32NextW`.
* For each active process:
  * Memory footprint: `GetProcessMemoryInfo(hProcess, &PROCESS_MEMORY_COUNTERS_EX)` to obtain Resident Working Set (`WorkingSetSize`) and Private Commit (`PrivateUsage`).
  * Process Times: `GetProcessTimes(hProcess, &creation, &exit, &kernel, &user)` to calculate exact per-process CPU percentage across ticks.

### 4. Storage & Filesystem Metrics
* **API:** `GetLogicalDriveStringsW` to iterate through drive letters (`C:\`, `D:\`).
* **API:** `GetDiskFreeSpaceExW` to retrieve total byte capacities, caller-available bytes, and free bytes.
* **API:** `GetVolumeInformationW` to extract filesystem volume formats (NTFS, ReFS, FAT32).

### 5. Network Interface Probes
* **API:** `GetIfTable2` / `GetIfEntry2` via `iphlpapi.dll` for high-resolution interface octet counters (`InOctets`, `OutOctets`, `OperStatus`).

---

## 🐧 Linux Kernel Telemetry

On Linux systems, Zyphor bypasses external commands (`ps`, `netstat`) and reads directly from pseudo-filesystems (`/proc` and `/sys`) using fixed stack buffers:

### 1. CPU Metrics (`/proc/stat`)
* Reads line `cpu` and per-core lines `cpu0`, `cpu1`, etc.
* Parses `user`, `nice`, `system`, `idle`, `iowait`, `irq`, `softirq`, `steal`.
* Computes active vs total jiffies deltas.

### 2. Memory Breakdown (`/proc/meminfo`)
* Parses `MemTotal`, `MemFree`, `MemAvailable`, `Buffers`, `Cached`, `SwapTotal`, `SwapFree`.
* Accurately distinguishes between free unallocated memory and reclaimable page cache.

### 3. Storage I/O Statistics (`/proc/diskstats`)
* Tracks sectors read and written per block device.
* Computes live read/write bandwidth (MB/s) and I/O request queue depths.

### 4. Network Throughput (`/proc/net/dev` & `netlink`)
* High-speed parsing of interface RX/TX byte and packet counters.
* Directly handles bonding, bridge, and virtual interfaces (Docker/Podman `veth`).

---

## 🍎 macOS (Darwin / Mach) Telemetry

On macOS, Zyphor interfaces with the Mach microkernel and BSD `sysctl` subsystems:

### 1. Mach Host Statistics
* **API:** `host_processor_info(mach_host, PROCESSOR_CPU_LOAD_INFO, ...)` for per-core tick metrics.
* **API:** `host_statistics64(mach_host, HOST_VM_INFO64, ...)` for page states (active, inactive, wired, compressed).

### 2. Process Inspection
* **API:** `proc_pidinfo` with `PROC_PIDTASKINFO` to read task resident size, virtual size, and CPU user/system runtime.

### 3. Thermal & Apple Silicon GPU
* Interfaces with `IOReport` and `IOKit` accelerators to monitor Apple M-series SoC efficiency/performance core clusters.
