# 🪟 Zyphor Windows Internals & Native Win32 API Architecture

*Author: Akshar Miyani ([@miyaniakshar1234](https://github.com/miyaniakshar1234)) • Repository: [Zyphor](https://github.com/miyaniakshar1234/Zyphor)*

---

## Overview

Zyphor is designed from first principles for high-performance, deterministic systems telemetry. Unlike traditional monitoring utilities on Windows that rely on heavy WMI (Windows Management Instrumentation) queries, slow COM object instantiations, or auxiliary PowerShell sub-processes, Zyphor interfaces directly with native **Win32 APIs** and **NT Native System Calls**.

This document outlines the real Windows APIs utilized across Zyphor's telemetry subsystems (`src/platform/windows.zig`), detailing currently active production implementations, upcoming API integrations ("being added"), and fundamental platform limitations under user-mode execution.

---

## 1. System Telemetry Probes & Windows APIs

### 1.1 Total CPU Metrics: `GetSystemTimes` (`kernel32.dll`)
* **Status:** Current Implementation
* **Header / Import:** `kernel32.lib`, `<windows.h>`
* **Signature:**
  ```c
  BOOL GetSystemTimes(
      LPFILETIME lpIdleTime,
      LPFILETIME lpKernelTime,
      LPFILETIME lpUserTime
  );
  ```
* **How Zyphor Uses It:**
  - `GetSystemTimes` retrieves system-wide timing values in `FILETIME` structures (100-nanosecond slices since January 1, 1601 UTC).
  - Both kernel time and idle time are returned separately, with `lpKernelTime` including idle time.
  - Zyphor captures previous and current snapshot timestamps to calculate elapsed deltas:
    $$\Delta \text{Kernel} = \text{Kernel}_{\text{now}} - \text{Kernel}_{\text{prev}}$$
    $$\Delta \text{User} = \text{User}_{\text{now}} - \text{User}_{\text{prev}}$$
    $$\Delta \text{Idle} = \text{Idle}_{\text{now}} - \text{Idle}_{\text{prev}}$$
    $$\Delta \text{Total} = \Delta \text{Kernel} + \Delta \text{User}$$
    $$\Delta \text{System} = \Delta \text{Kernel} - \Delta \text{Idle}$$
  - CPU usage percentages are computed deterministically without floating-point overflow:
    $$\text{Usage}_{\text{total}} = \frac{\Delta \text{System} + \Delta \text{User}}{\Delta \text{Total}} \times 100.0$$

---

### 1.2 Per-Core CPU Telemetry: `NtQuerySystemInformation` Class 8
* **Status:** Being Added
* **Source:** `ntdll.dll`
* **Information Class:** `SystemProcessorPerformanceInformation` (Class `8`)
* **Struct Definition:**
  ```c
  typedef struct _SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION {
      LARGE_INTEGER IdleTime;
      LARGE_INTEGER KernelTime;
      LARGE_INTEGER UserTime;
      LARGE_INTEGER DpcTime;
      LARGE_INTEGER InterruptTime;
      ULONG InterruptCount;
  } SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION;
  ```
* **How Zyphor Uses It:**
  - Standard Win32 functions do not expose per-core CPU breakdown without WMI or PDH overhead.
  - Invoking `NtQuerySystemInformation(8, buffer, buffer_size, &return_length)` returns an array of `SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION` records—one entry per logical CPU core.
  - For each core $i$, delta calculations ($(\text{Kernel}_i - \text{Idle}_i + \text{User}_i) / (\text{Kernel}_i + \text{User}_i)$) provide real hardware utilization per core, replacing synthetic core approximations with true hardware scheduler load.

---

### 1.3 CPU Hardware Identity & Nominal Frequency: Registry
* **Status:** Being Added
* **Source:** `advapi32.dll` / `ntdll.dll` (Registry APIs)
* **Key Path:** `HKEY_LOCAL_MACHINE\HARDWARE\DESCRIPTION\System\CentralProcessor\0`
* **Values Queried:**
  - `ProcessorNameString` (`REG_SZ`): Full human-readable brand string (e.g., `13th Gen Intel(R) Core(TM) i7-13700H` or `AMD Ryzen 9 7950X 16-Core Processor`).
  - `~MHz` (`REG_DWORD`): Nominal base clock frequency in megahertz.
* **How Zyphor Uses It:**
  - Read once during initialization to populate `CpuMetrics.model_name` and `CpuMetrics.frequency_mhz`.
  - Avoids spawning `wmic cpu get name` or executing heavy COM queries.

---

### 1.4 Physical & Virtual Memory: `GlobalMemoryStatusEx` (`kernel32.dll`)
* **Status:** Current Implementation
* **Header / Import:** `kernel32.lib`, `<windows.h>`
* **Signature:**
  ```c
  BOOL GlobalMemoryStatusEx(
      LPMEMORYSTATUSEX lpBuffer
  );
  ```
* **Struct Inspected:**
  - `ullTotalPhys`: Total installed physical RAM in bytes.
  - `ullAvailPhys`: Physical memory currently available to processes without paging.
  - `ullTotalPageFile`: Current committed memory limit (Physical RAM + current pagefile capacity).
  - `ullAvailPageFile`: Maximum amount of memory the current process or system can commit without extending paging files.
  - `dwMemoryLoad`: Approximate percentage (0–100) of physical memory in active use.
* **How Zyphor Uses It:**
  - Computes exact physical memory usage ($\text{Used} = \text{TotalPhys} - \text{AvailPhys}$) and commit charge/swap pagefile usage ($\text{SwapUsed} = \text{TotalPageFile} - \text{AvailPageFile}$).
  - Drives memory pressure heuristic ratings (`low`, `medium`, `high`, `critical`) based on physical saturation thresholds.

---

### 1.5 Storage Volumes & Free Space: `GetDiskFreeSpaceExW` (`kernel32.dll`)
* **Status:** Current Implementation
* **Header / Import:** `kernel32.lib`, `<windows.h>`
* **Signature:**
  ```c
  BOOL GetDiskFreeSpaceExW(
      LPCWSTR lpDirectoryName,
      PULARGE_INTEGER lpFreeBytesAvailableToCaller,
      PULARGE_INTEGER lpTotalNumberOfBytes,
      PULARGE_INTEGER lpTotalNumberOfFreeBytes
  );
  ```
* **Drive Discovery Auxiliary APIs:**
  - `GetLogicalDriveStringsW`: Enumerates active drive root paths (`C:\`, `D:\`, etc.).
  - `GetDriveTypeW`: Filters volumes by drive type (`DRIVE_FIXED`, `DRIVE_REMOVABLE`, `DRIVE_REMOTE`).
* **How Zyphor Uses It:**
  - Iterates over valid drive paths and pulls total capacity, free bytes, and caller quota limits.
  - Computes partition usage percentages and formats partition mounts for the Storage viewport.

---

### 1.6 Process Table & Resource Accounting
* **Status:** Current Implementation
* **APIs Used:**
  1. `CreateToolhelp32Snapshot` (`kernel32.dll`) with `TH32CS_SNAPPROCESS`:
     - Creates a snapshot of all system processes.
  2. `Process32FirstW` / `Process32NextW` (`kernel32.dll`):
     - Iterates through the process list extracting PID, PPID (lineage parent), thread counts, and executable filenames (`szExeFile`).
  3. `OpenProcess` with `PROCESS_QUERY_LIMITED_INFORMATION`:
     - Obtains a low-privilege handle to retrieve process metrics without triggering access violations or requiring elevation for non-protected processes.
  4. `GetProcessTimes` (`kernel32.dll`):
     - Extracts process `KernelTime` and `UserTime` FILETIMEs.
     - Diffs process time against system-wide delta over the refresh tick to produce individual process `% CPU`.
  5. `GetProcessMemoryInfo` (`psapi.dll`):
     - Populates `PROCESS_MEMORY_COUNTERS_EX`.
     - Extracts `WorkingSetSize` (Resident Set Size / Physical RAM) and `PagefileUsage` (Virtual Memory / Private Commit Charge).
  6. Process Control Actions:
     - `TerminateProcess` (`kernel32.dll`) via `PROCESS_TERMINATE`.
     - `NtSuspendProcess` / `NtResumeProcess` (`ntdll.dll`) via `PROCESS_SUSPEND_RESUME`.

---

### 1.7 Battery & Power Management: `GetSystemPowerStatus` (`kernel32.dll`)
* **Status:** Current Implementation
* **Header / Import:** `kernel32.lib`, `<windows.h>`
* **Signature:**
  ```c
  BOOL GetSystemPowerStatus(
      LPSYSTEM_POWER_STATUS lpSystemPowerStatus
  );
  ```
* **Struct Fields:**
  - `ACLineStatus`: `0` (Offline/Battery), `1` (Online/Plugged in), `255` (Unknown).
  - `BatteryFlag`: Bitmask indicating charge level (high, low, critical, charging, no system battery).
  - `BatteryLifePercent`: Remaining capacity percentage (0–100, or 255 if unknown).
  - `BatteryLifeTime`: Remaining operational seconds when discharging.
* **How Zyphor Uses It:**
  - Detects if host is desktop or portable laptop.
  - Dynamically updates HUD battery indicator and charging status.

---

### 1.8 Network Interface Metrics: `GetIfTable2` + `GetAdaptersAddresses` (`iphlpapi.dll`)
* **Status:** Being Added
* **Header / Import:** `iphlpapi.lib`, `<netioapi.h>`, `<iptypes.h>`
* **Signatures:**
  ```c
  DWORD GetIfTable2(
      PMIB_IF_TABLE2 *Table
  );
  
  ULONG GetAdaptersAddresses(
      ULONG Family,
      ULONG Flags,
      PVOID Reserved,
      PIP_ADAPTER_ADDRESSES AdapterAddresses,
      PULONG SizePointer
  );
  ```
* **How Zyphor Uses It:**
  - `GetIfTable2`: Allocates and populates an array of `MIB_IF_ROW2` structures containing 64-bit monotonic octet counters (`InOctets`, `OutOctets`), packet drop counts, operational status (`IfOperStatusUp`), and interface speeds (`ReceiveLinkSpeed`, `TransmitLinkSpeed`).
  - `GetAdaptersAddresses`: Resolves friendly display names (e.g. "Wi-Fi", "Ethernet"), unicast IPv4/IPv6 address lists, gateway addresses, and MAC addresses.
  - Combined, these replace static network mocks with live, high-precision bandwidth delta measurements.

---

### 1.9 Socket Connection Tracking: `GetExtendedTcpTable` / `GetExtendedUdpTable` (`iphlpapi.dll`)
* **Status:** Being Added
* **Header / Import:** `iphlpapi.lib`, `<tcpmib.h>`, `<udpmib.h>`
* **Signatures:**
  ```c
  DWORD GetExtendedTcpTable(
      PVOID pTcpTable,
      PDWORD pdwSize,
      BOOL bOrder,
      ULONG ulAf,
      TCP_TABLE_CLASS TableClass,
      ULONG TableClass
  );
  
  DWORD GetExtendedUdpTable(
      PVOID pUdpTable,
      PDWORD pdwSize,
      BOOL bOrder,
      ULONG ulAf,
      UDP_TABLE_CLASS TableClass,
      ULONG TableClass
  );
  ```
* **How Zyphor Uses It:**
  - Invoked with `TCP_TABLE_OWNER_PID_ALL` and `UDP_TABLE_OWNER_PID`.
  - Maps every open listening port and active network connection directly to its owning Process ID (`dwOwningPid`), local endpoint (`dwLocalAddr:dwLocalPort`), remote peer (`dwRemoteAddr:dwRemotePort`), and connection state (`MIB_TCP_STATE_ESTAB`, `MIB_TCP_STATE_LISTEN`, etc.).
  - Enables the Network viewport's real-time connection inspector with PID-to-process attribution.

---

### 1.10 Windows Services Telemetry: `EnumServicesStatusExW` (`advapi32.dll`)
* **Status:** Being Added
* **Header / Import:** `advapi32.lib`, `<winsvc.h>`
* **Signatures:**
  ```c
  SC_HANDLE OpenSCManagerW(
      LPCWSTR lpMachineName,
      LPCWSTR lpDatabaseName,
      DWORD dwDesiredAccess
  );
  
  BOOL EnumServicesStatusExW(
      SC_HANDLE hSCManager,
      SC_ENUM_TYPE InfoLevel,
      DWORD dwServiceType,
      DWORD dwServiceState,
      LPBYTE lpServices,
      DWORD cbBufSize,
      LPDWORD pcbBytesNeeded,
      LPDWORD lpServicesReturned,
      LPDWORD lpResumeHandle,
      LPCWSTR pszGroupName
  );
  ```
* **How Zyphor Uses It:**
  - Connects to the Service Control Manager with `SC_MANAGER_ENUMERATE_SERVICE`.
  - Queries `ENUM_SERVICE_STATUS_PROCESSW` structures for all Win32 services (`SERVICE_WIN32`, `SERVICE_STATE_ALL`).
  - Returns service name, display name, current status (`SERVICE_RUNNING`, `SERVICE_STOPPED`), and active Process ID (`dwProcessId`), enabling deep service diagnostics in Zyphor.

---

### 1.11 GPU Hardware Identification: `EnumDisplayDevicesW` (`user32.dll`)
* **Status:** Being Added
* **Header / Import:** `user32.lib`, `<winuser.h>`
* **Signature:**
  ```c
  BOOL EnumDisplayDevicesW(
      LPCWSTR lpDevice,
      DWORD iDevNum,
      PDISPLAY_DEVICEW lpDisplayDevice,
      DWORD dwFlags
  );
  ```
* **How Zyphor Uses It:**
  - Iterates display adapters using index `iDevNum` until exhaustion.
  - Detects active display adapters matching `DISPLAY_DEVICE_PRIMARY_DEVICE` or attached display hardware.
  - Extracts `DeviceString` (e.g., `"NVIDIA GeForce RTX 4080 Laptop GPU"`, `"AMD Radeon RX 7900 XTX"`, or `"Intel(R) Arc(TM) A770 Graphics"`) for display in the Hardware & GPU viewport and bottom HUD banner.

---

## 2. Limitations & Real-World Operating System Constraints

To maintain absolute honesty and technical integrity, the following data points cannot be extracted via standard user-mode Win32 APIs without elevated privileges, external vendor SDKs, or proprietary kernel drivers:

### 2.1 CPU Temperature
* **Limitation:** Standard Win32 user-mode APIs provide **no CPU core temperature metrics**.
* **Reason:** Hardware thermal sensors are exposed via MSRs (Model-Specific Registers, e.g., `IA32_THERM_STATUS`) or vendor ACPI methods (`\_TZ.THM0`). Reading MSRs requires Ring 0 execution (kernel-mode driver, e.g., `WinRing0`, `InpOut32`, or `Pawn`).
* **Zyphor Behavior:** CPU temperature displays as **`N/A`** unless a signed driver or WMI ThermalZone provider is present and responsive.

### 2.2 Discrete GPU Utilization & Dedicated VRAM
* **Limitation:** Detailed GPU engine utilization percentages and dynamic VRAM usage cannot be queried using standard Win32 / GDI APIs.
* **Reason:** Accurate GPU engine telemetry requires either:
  1. Vendor-specific userspace SDKs (such as NVIDIA NVML via `nvml.dll` or AMD ADLX/AGS).
  2. Direct interaction with Windows Display Driver Model (WDDM) kernel telemetry via undocumented or complex D3DKMT APIs (`D3DKMTQueryStatistics` / `GdiEntry` dispatch tables).
* **Zyphor Behavior:** GPU adapter names are detected natively via `EnumDisplayDevicesW`. Full real-time utilization graphs and VRAM tracking require external vendor integrations and are slated for future releases.

### 2.3 Docker Container Telemetry
* **Limitation:** Windows processes spawned inside Docker Desktop or WSL2 Linux containers are isolated from the host Windows process snapshot tree.
* **Reason:** Containerized processes run inside an isolated Hyper-V lightweight utility VM (WSL2) or distinct Windows Server container silos. They do not appear in `CreateToolhelp32Snapshot`.
* **Zyphor Behavior:** Docker telemetry requires direct communication with the local Docker daemon engine named pipe (`\\.\pipe\docker_engine`) or Unix domain socket, planned for a dedicated container plugin module.

### 2.4 Real-Time Disk I/O Throughput
* **Limitation:** Querying physical disk read/write bandwidth and IOPS via `DeviceIoControl` with `IOCTL_DISK_PERFORMANCE` requires **elevated Administrator privileges**.
* **Reason:** Disk performance counter filters are privileged device objects in Windows. Non-elevated standard user accounts receive `ERROR_ACCESS_DENIED` (`5`).
* **Zyphor Behavior:** When executed without administrative elevation (`isUserAdmin() == false`), live disk I/O throughput rates report **`0 B/s`** (or 0) without admin.

---

## 3. Summary of Windows API Mapping

| Subsystem | Target Metric | Win32 / NT API | DLL | Privilege Level | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **CPU (Global)** | Total, Kernel, User, Idle usage | `GetSystemTimes` | `kernel32.dll` | Standard User | **Active** |
| **CPU (Per-Core)** | Per-core hardware load | `NtQuerySystemInformation` (Class 8) | `ntdll.dll` | Standard User | **Being Added** |
| **CPU (Hardware)** | Processor brand string & MHz | Registry (`CentralProcessor\0`) | `advapi32.dll` | Standard User | **Being Added** |
| **Memory** | Physical RAM & Commit/Pagefile | `GlobalMemoryStatusEx` | `kernel32.dll` | Standard User | **Active** |
| **Disk (Storage)** | Volume capacities & free space | `GetDiskFreeSpaceExW`, `GetLogicalDriveStringsW` | `kernel32.dll` | Standard User | **Active** |
| **Disk (I/O)** | Real-time disk read/write & IOPS | `IOCTL_DISK_PERFORMANCE` | `kernel32.dll` | **Admin Required** | **Limited** (Shows 0 without Admin) |
| **Processes** | PIDs, PPIDs, threads, names | `CreateToolhelp32Snapshot`, `Process32NextW` | `kernel32.dll` | Standard User | **Active** |
| **Process CPU** | Process kernel/user time deltas | `GetProcessTimes` | `kernel32.dll` | Standard User | **Active** |
| **Process RAM** | WorkingSet (RSS), Pagefile (Commit) | `GetProcessMemoryInfo` | `psapi.dll` | Standard User | **Active** |
| **Process Control**| Terminate, Suspend, Resume | `TerminateProcess`, `NtSuspendProcess`, `NtResumeProcess` | `kernel32.dll` / `ntdll.dll` | Process Owner | **Active** |
| **Battery / Power**| AC line status, %, remaining runtime | `GetSystemPowerStatus` | `kernel32.dll` | Standard User | **Active** |
| **Network (Iface)**| Octet counters, speeds, status | `GetIfTable2`, `GetAdaptersAddresses` | `iphlpapi.dll` | Standard User | **Being Added** |
| **Sockets (TCP/UDP)**| Active connections, ports, PID owner | `GetExtendedTcpTable`, `GetExtendedUdpTable` | `iphlpapi.dll` | Standard User | **Being Added** |
| **Services** | Win32 service state, PID, names | `EnumServicesStatusExW` | `advapi32.dll` | Standard User | **Being Added** |
| **GPU (Identity)** | Primary GPU name & display adapters | `EnumDisplayDevicesW` | `user32.dll` | Standard User | **Being Added** |
| **GPU (Telemetry)**| Utilization & VRAM metrics | NVML / `D3DKMTQueryStatistics` | Vendor / `gdi32.dll` | Specialized | **Future Work** |
| **CPU Temperature**| Thermal sensors per core | Kernel-mode driver (MSRs) / ACPI | Ring 0 Driver | Kernel Driver | **Limited** (Shows `N/A`) |
| **Containers** | Docker / OCI containers | Docker Engine Named Pipe API | Pipe / Socket | Daemon Access | **Future Work** |
