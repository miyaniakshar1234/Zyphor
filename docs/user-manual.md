# 📖 Zyphor Observatory — Comprehensive User Manual

*Author: Akshar Miyani • Version: 1.0.0 • Architecture: Zero-Allocation Native Systems Observatory*

---

## Table of Contents
1. [Introduction & Core Concepts](#1-introduction--core-concepts)
2. [Subsystem Panels (The 7 Pillars)](#2-subsystem-panels-the-7-pillars)
   - [Panel 1: Overview Dashboard (Flight Recorder)](#panel-1-overview-dashboard-flight-recorder)
   - [Panel 2: Process Explorer & Lineage Trees](#panel-2-process-explorer--lineage-trees)
   - [Panel 3: Storage Fabrics & Disk I/O Analyzer](#panel-3-storage-fabrics--disk-io-analyzer)
   - [Panel 4: Network Observability & Active Sockets](#panel-4-network-observability--active-sockets)
   - [Panel 5: Autonomous Root-Cause Diagnostics & Health](#panel-5-autonomous-root-cause-diagnostics--health)
   - [Panel 6: System Services & Background Daemons](#panel-6-system-services--background-daemons)
   - [Panel 7: Container Observatory (Docker / OCI)](#panel-7-container-observability-docker--oci)
3. [Interactive Process Profiler (Deep Trace Modal)](#3-interactive-process-profiler-deep-trace-modal)
4. [Command Palette & Fast Launcher](#4-command-palette--fast-launcher)
5. [Complete Keyboard Shortcuts & Navigation Reference](#5-complete-keyboard-shortcuts--navigation-reference)
6. [Broadband Speed & Network Saturation Benchmark](#6-broadband-speed--network-saturation-benchmark)
7. [Instant Incident Snapshot Export (`E`)](#7-instant-incident-snapshot-export-e)
8. [Telemetry Interpretation & Incident Response Playbook](#8-telemetry-interpretation--incident-response-playbook)

---

## 1. Introduction & Core Concepts

Zyphor is a native, real-time operating system observatory and diagnostics engine. Unlike traditional process monitors that poll operating system APIs blindly and write raw escape strings directly to standard output, Zyphor operates on two core principles:

1. **Zero-Allocation Telemetry Loop:** Telemetry is sampled directly into pre-allocated memory structures using double-arena swapping. The application generates **zero general-purpose heap allocations** during standard monitoring.
2. **Double-Buffered Differential Rendering:** All visual elements are drawn into an off-screen virtual framebuffer of `Cell` structures. The engine computes a cell-by-cell delta against the prior frame and transmits ANSI escape codes *strictly for modified terminal cells*. This produces zero screen tearing and enables ultra-smooth 30–60 FPS updates with less than 0.1% CPU overhead.

---

## 2. Subsystem Panels (The 7 Pillars)

You can jump directly to any subsystem panel by pressing numerical keys <kbd>1</kbd> through <kbd>7</kbd>, or cycle through them in order using <kbd>Tab</kbd> and <kbd>Shift+Tab</kbd>.

---

### Panel 1: Overview Dashboard (Flight Recorder)
*Access: Hotkey <kbd>1</kbd>*

The **Overview Dashboard** serves as the system's flight recorder. It provides an immediate, high-density visualization of overall hardware health.

```
┌─ [1] OVERVIEW ────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                                                       │
│  ◈ CPU COMPUTE & CORES           ◈ PHYSICAL RAM & SWAP            ◈ STORAGE & DISK FABRIC             │
│   ╭─────────╮                     [██████████░░░░░░░░] 54.2%       Read:  142.5 MB/s                  │
│  │  38.4%   │ 3.8 GHz Nominal     Used:  17.3 GB / 32.0 GB         Write:  48.2 MB/s                  │
│   ╰─────────╯                     Swap:   1.2 GB / 16.0 GB (7.5%)  IOPS:  1,420                       │
│  Core 0: [██████░░░░] 62%                                                                             │
│  Core 1: [████░░░░░░] 41%        ◈ NETWORK FLOW                   ◈ ANOMALY STREAM (AI)               │
│  Core 2: [██░░░░░░░░] 22%         ↓ Ingress:  12.4 MB/s           • [INFO] Memory allocations normal  │
│  Core 3: [█████░░░░░] 50%         ↑ Egress:    2.1 MB/s           • [OK] Zero thermal throttling      │
│                                                                                                       │
└───────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

#### Metrics Explained:
* **Radial CPU Load Dial:** Real-time aggregate compute utilization across all logical cores. Computed from user-mode and kernel-mode CPU time deltas over the sampling window.
* **Per-Core Bar Matrix:** Individual horizontal load gauges for every logical processor core, highlighting single-threaded bottlenecks or uneven thread distribution.
* **Physical RAM Meter:** Resident physical memory allocated across all active processes, cached buffers, and kernel structures.
* **VMM Pagefile Swap Gauge:** Dedicated meter tracking virtual memory paging activity. A climbing swap meter indicates physical memory exhaustion and impending disk thrashing.
* **Live Incident Stream:** Chronological feed of threshold events, anomalous spikes, and subsystem warnings detected by the heuristic analyzer.

---

### Panel 2: Process Explorer & Lineage Trees
*Access: Hotkey <kbd>2</kbd>*

The **Process Explorer** provides granular, low-latency control over every user and kernel thread running on the machine.

#### Data Columns:
| Column | Description | Data Source / Computation |
| :--- | :--- | :--- |
| **PID** | Process Identifier | Unique numerical OS process ID. |
| **PPID** | Parent Process ID | Process ID of the spawning parent. Used for lineage tree generation. |
| **USER** | Security Context / Owner | Username or security principal owning the process token. |
| **CPU%** | CPU Utilization | Time delta spent in user + kernel mode scaled across active cores. |
| **MEM (RSS)**| Resident Set Size | Physical RAM pages actively held in main memory by this process. |
| **VSIZE** | Virtual Memory Size | Total address space mapped by the process (including mapped files & shared libraries). |
| **DISK R/W** | Instantaneous I/O | Live rate of bytes read from and written to storage per second. |
| **THR** | Thread Count | Number of active execution threads registered in the process. |
| **STATE** | Process Lifecycle State | `R` (Running), `S` (Sleeping), `D` (Disk/Uninterruptible Wait), `Z` (Zombie), `T` (Stopped). |

#### Interactive Controls in Process Explorer:
* **Toggle Lineage Tree (<kbd>t</kbd>):** Switches between a flat sortable table and a hierarchical parent-child tree view using Depth-First Search (DFS) traversal. Child processes are visually indented under their parent processes (e.g., `bash` ➔ `node` ➔ `esbuild`).
* **Deep Inspector Side-Pane (<kbd>Enter</kbd>):** Opens an in-depth telemetry card on the right side of the screen displaying target PID details, parent metadata, full image binary paths, working directory, thread state, and memory quota limits.
* **Real-Time Search (<kbd>/</kbd>):** Activates instant substring filtering. Type any process name or PID to immediately filter the table without losing selection state.
* **Instant Sorting:**
  * <kbd>c</kbd>: Sort by **CPU%** descending.
  * <kbd>m</kbd>: Sort by **Resident Memory (RSS)** descending.
  * <kbd>p</kbd>: Sort by **Process ID (PID)** ascending.
  * <kbd>n</kbd>: Sort by **Process Name** alphabetical.
* **Process Interception & Signal Dispatch:**
  * <kbd>x</kbd>: **Terminate Process** — Sends `SIGKILL` on POSIX systems or calls `TerminateProcess()` on Windows.
  * <kbd>s</kbd>: **Suspend Process** — Sends `SIGSTOP` on POSIX systems or calls `NtSuspendProcess()` on Windows to freeze execution without terminating.
  * <kbd>u</kbd>: **Resume Process** — Sends `SIGCONT` on POSIX systems or calls `NtResumeProcess()` on Windows to restore a frozen process.

---

### Panel 3: Storage Fabrics & Disk I/O Analyzer
*Access: Hotkey <kbd>3</kbd>*

Provides full visibility into mounted filesystems, capacity limits, partition tables, and disk controller transfer rates.

#### Key Features:
* **Partition Allocation Table:** Shows all local and network mount points (`C:`, `/`, `/home`, `/data`), underlying filesystem types (`NTFS`, `ext4`, `apfs`, `btrfs`, `zfs`), total capacity, used gigabytes, and remaining free space.
* **Live I/O Throughput Gauges:** Dedicated dual read/write throughput meters displaying real-time disk transfer speeds in megabytes per second (MB/s).
* **IOPS Counters:** Tracks input/output operations per second to identify random read/write storage queue saturation.

---

### Panel 4: Network Observability & Active Sockets
*Access: Hotkey <kbd>4</kbd>*

Comprehensive networking console combining real-time ingress/egress graphs, network adapter status cards, and live TCP/UDP socket tracking.

#### Sub-Cell Braille Sparklines:
The network panel renders 60-second historical traffic graphs using Unicode Braille patterns (`⠋`, `⠙`, `⠹`, `⠸`, etc.). By encoding 8 discrete dot positions within a single character cell, Zyphor achieves **4x vertical and 2x horizontal resolution** compared to standard block characters.

#### Active Socket Connection Matrix:
Maps active network connections to their originating local processes:
* **PID & Process Name:** The application owning the socket.
* **Local Endpoint:** IP and Port bound locally (e.g., `127.0.0.1:8080` or `0.0.0.0:22`).
* **Remote Endpoint:** IP and Port of the remote peer (e.g., `142.250.190.46:443`).
* **Protocol & State:** TCP connection states (`ESTABLISHED`, `LISTEN`, `SYN_SENT`, `TIME_WAIT`, `CLOSE_WAIT`) or stateless UDP.

#### Network Diagnostics Tools:
* **Integrated Speed Test (<kbd>s</kbd>):** Initiates an automated broadband speed test to measure latency, download bitrate, and bufferbloat.
* **Multi-Stream Stress Engine (<kbd>S</kbd>):** Opens the network saturation test configuration modal to test local link stability under heavy concurrent load.

---

### Panel 5: Autonomous Root-Cause Diagnostics & Health
*Access: Hotkey <kbd>5</kbd>*

The Heuristic AI Engine analyzes live snapshot data to identify root causes of system degradation before they lead to complete failure.

#### 5-Subsystem Hardware Radar:
Each major hardware domain is continuously evaluated and assigned an integer health score from `0` (Critical Failure) to `100` (Optimal Condition):
1. **Compute Core (CPU):** Evaluates load spikes, thread queue depth, and thermal throttling velocity.
2. **Memory Fabric (RAM):** Monitors physical saturation and swap paging activity.
3. **Storage Fabric (I/O):** Assesses disk I/O queue wait times and partition capacity limits.
4. **Network Links:** Tracks link drops, packet errors, and socket connection anomalies.
5. **Thermal Margins:** Watches CPU core temperatures and clock throttling behavior.

#### Explainable Root-Cause Insights & Action Playbooks:
When a subsystem score drops, the Heuristic Engine generates an **Insight Card** containing three components:
1. **Diagnosis:** A clear statement of what is occurring (e.g., *"VMM Swap Thrashing Detected"*).
2. **Evidence:** The mathematical metrics proving the diagnosis (e.g., *"RAM is 94% saturated. Pagefile swap rate is 42 MB/s. Process 'java.exe' (PID 4812) holds 8.4 GB RSS."*).
3. **Defensive Action Playbook:** A concrete step to resolve the issue (e.g., *"Terminate or suspend PID 4812 to prevent host lockup."*).

---

### Panel 6: System Services & Background Daemons
*Access: Hotkey <kbd>6</kbd>*

Observes all background services and daemons registered with the operating system (Windows Service Control Manager or Linux `systemd`).

* **Service Table:** Displays Service Identifier, Human-Readable Display Name, Current Status (`RUNNING`, `STOPPED`, `STARTING`, `PAUSED`), Startup Type (`Automatic`, `Manual`, `Disabled`), and PID if running.
* **Service Deep Inspector:** Selecting a service displays its underlying executable binary path, service group, and description.

---

### Panel 7: Container Observatory (Docker / OCI)
*Access: Hotkey <kbd>7</kbd>*

Provides direct telemetry on local containers via the OCI/Docker plugin interface.

* **Resource Quota Gauges:** Compares actual container RAM usage against hard memory quota limits (`memory_limit_bytes`).
* **Container Telemetry:** Displays Container ID, Container Name, Base Image Tag, Execution State (`running`, `exited`, `paused`), CPU utilization, and isolated network ingress/egress.

---

## 3. Interactive Process Profiler (Deep Trace Modal)

*Access: Highlight any process in Tab 2 and press <kbd>P</kbd>*

When diagnosing an erratic or leaking process, standard 1-second polling intervals are often too coarse to capture micro-spikes. The **Process Profiler** provides dedicated high-frequency tracing.

```
┌─ ◈ PERFORMANCE PROFILER ◈ ────────────────────────────────────────────────────────┐
│                                                                                   │
│  Target: postgres.exe (PID: 4120)                                                 │
│  Status: RUNNING                                                                  │
│                                                                                   │
│  [██████████████████████░░░░░░░░░░░░░░░░░░░░] 54.0%                               │
│  Elapsed: 5.4s / 10s                                                              │
│                                                                                   │
│  Current CPU:  34.2%                                                              │
│  Current RAM:  812 MB                                                             │
│                                                                                   │
└───────────────────────────────────────────────────────────────────────────────────┘
```

### Profiler Workflow:
1. Navigate to **Tab 2 (Processes)** and use <kbd>j</kbd>/<kbd>k</kbd> to select the target process.
2. Press <kbd>P</kbd>. A high-frequency tracing thread attaches to the process for **10 seconds**.
3. During execution, the profiler draws a real-time progress bar, live sampling rate, and memory usage.
4. Upon completion, the profiler displays a final **Telemetry Audit Report**:
   * **Peak Utilization (Max Jitter):** The maximum CPU percentage reached during the trace.
   * **Rolling Average:** The smoothed average CPU utilization across the 10-second window.
   * **Minimum Footprint:** Baseline idle compute utilization.
   * **Memory Trend:** Identifies whether the process Resident Set Size (RSS) is climbing (leak pattern) or stable.
5. Press <kbd>Esc</kbd> to close the report and return to the Process Explorer.

---

## 4. Command Palette & Fast Launcher

*Access: Hotkey <kbd>:</kbd> or <kbd>Ctrl+P</kbd>*

The **Command Palette** is a floating launcher that gives you instant, keyboard-driven access to every command in Zyphor without needing to remember hotkeys.

```
┌─ ◈ QUICK ACTION COMMAND PALETTE ◈ ────────────────────────────────────────────────┐
│                                                                                   │
│  > Jump to Tab 1: Overview Dashboard                                              │
│    Jump to Tab 2: Process Explorer & Tree                                         │
│    Jump to Tab 3: Storage & Directory Analyzer                                    │
│    Jump to Tab 4: Network & Active Socket Map                                     │
│    Jump to Tab 5: Root-Cause Health & Diagnostics                                 │
│    Cycle TrueColor Theme (Anthropic, Cyber, Tokyo Night...)                       │
│    Sort Processes by CPU% Load                                                    │
│    Export Telemetry Snapshot to JSON (E)                                          │
│    Show Full Keyboard Shortcuts & Help (?)                                        │
│    Quit Zyphor (q)                                                                │
│                                                                                   │
└───────────────────────────────────────────────────────────────────────────────────┘
```

* Use <kbd>j</kbd>/<kbd>k</kbd> or <kbd>↓</kbd>/<kbd>↑</kbd> to navigate commands.
* Press <kbd>Enter</kbd> to execute the highlighted action immediately.
* Press <kbd>Esc</kbd> to dismiss the palette.

---

## 5. Complete Keyboard Shortcuts & Navigation Reference

### Global Navigation
| Hotkey | Action | Description |
| :--- | :---: | :--- |
| <kbd>1</kbd> .. <kbd>7</kbd> | Direct Jump | Switch to Overview, Processes, Disks, Network, Health, Services, or Containers. |
| <kbd>Tab</kbd> | Next Panel | Advance viewport to the next subsystem panel. |
| <kbd>Shift+Tab</kbd> | Prev Panel | Advance viewport to the previous subsystem panel. |
| <kbd>:</kbd> or <kbd>Ctrl+P</kbd> | Command Palette | Open the floating quick action launcher. |
| <kbd>?</kbd> | Help Modal | Display full modal cheatsheet of all keyboard shortcuts. |
| <kbd>q</kbd> or <kbd>Ctrl+C</kbd> | Exit | Restore terminal cursor state and exit cleanly. |

### Process & List Navigation (Vim-Style)
| Hotkey | Action | Description |
| :--- | :---: | :--- |
| <kbd>j</kbd> or <kbd>↓</kbd> | Move Down | Advance cursor to next item in the list. |
| <kbd>k</kbd> or <kbd>↑</kbd> | Move Up | Move cursor to previous item in the list. |
| <kbd>g</kbd> | Jump to Top | Move cursor directly to the first row. |
| <kbd>G</kbd> | Jump to Bottom | Move cursor directly to the last row. |
| <kbd>PgDn</kbd> | Page Down | Scroll list down by 10 items. |
| <kbd>PgUp</kbd> | Page Up | Scroll list up by 10 items. |
| <kbd>/</kbd> | Global Search | Activate real-time search filter for active panel. |
| <kbd>Esc</kbd> | Clear / Close | Clear active search filter or close open modal overlay. |

### Process Actions & Sorting
| Hotkey | Action | Description |
| :--- | :---: | :--- |
| <kbd>Enter</kbd> | Deep Inspector | Toggle side-pane detailed telemetry card for selected item. |
| <kbd>t</kbd> | Lineage Tree | Toggle DFS parent-child tree indentation mode in Process Explorer. |
| <kbd>c</kbd> | Sort by CPU | Sort processes by CPU utilization descending. |
| <kbd>m</kbd> | Sort by RAM | Sort processes by Resident Set Size (RSS) descending. |
| <kbd>p</kbd> | Sort by PID | Sort processes by numerical Process ID ascending. |
| <kbd>n</kbd> | Sort by Name | Sort processes alphabetically by image binary name. |
| <kbd>x</kbd> | Terminate (Kill) | Send `SIGKILL` (POSIX) or `TerminateProcess()` (Windows) to target. |
| <kbd>s</kbd> | Suspend | Send `SIGSTOP` / `NtSuspendProcess` to freeze target. |
| <kbd>u</kbd> | Resume | Send `SIGCONT` / `NtResumeProcess` to unfreeze target. |

### Telemetry & Diagnostics Control
| Hotkey | Action | Description |
| :--- | :---: | :--- |
| <kbd>P</kbd> | Process Profiler | Launch 10-second high-frequency trace on highlighted process. |
| <kbd>E</kbd> | Export Snapshot | Dump instantaneous machine state to `zyphor-export-[timestamp].json`. |
| <kbd>Space</kbd> | Freeze Stream | Pause live telemetry polling to freeze values for inspection. |
| <kbd>]</kbd> or <kbd>Shift+T</kbd> | Cycle Theme | Cycle through all 10 built-in 24-bit TrueColor palettes. |

---

## 6. Broadband Speed & Network Saturation Benchmark

Zyphor includes native network benchmarking tools embedded directly in the binary.

### Triggering a Broadband Speed Test:
1. Jump to **Tab 4 (Network)**.
2. Press <kbd>s</kbd>.
3. Zyphor spins up an asynchronous background thread that executes latency pings, bufferbloat measurements, and multi-chunk HTTP download streams.
4. The live HUD displays progress animated at 30 FPS. Results are recorded directly into your network telemetry history.

### Triggering a Multi-Stream Saturation Test:
1. Jump to **Tab 4 (Network)**.
2. Press <kbd>S</kbd> (Shift+S).
3. Use numerical keys <kbd>1</kbd>–<kbd>6</kbd> to select target duration (10s to 1 hour) and <kbd>+</kbd>/<kbd>-</kbd> to configure concurrent socket streams (1 to 64 streams).
4. Press <kbd>Enter</kbd> to launch. Zyphor saturates local bandwidth to test switch stability, adapter throughput limits, and router bufferbloat under extreme concurrency.

---

## 7. Instant Incident Snapshot Export (`E`)

When a transient incident occurs (e.g., a sudden 5-second CPU spike or memory leak), reproducing it later is often impossible without telemetry records.

**Zyphor solves this with Instant Telemetry Export:**
* At any moment while running the TUI, press <kbd>E</kbd>.
* Zyphor immediately captures the full internal `SystemSnapshot` object across all subsystems (CPU threads, process table with RSS/VSize, storage partitions, active network socket maps, AI diagnostic results, and service states).
* The snapshot is serialized to clean JSON and written to `zyphor-export-[timestamp].json` in the current working directory.
* A confirmation message is displayed in the bottom status bar: `Telemetry exported to zyphor-export-1724781290.json`.

---

## 8. Telemetry Interpretation & Incident Response Playbook

### Scenario A: High CPU Load, System Unresponsive
1. Jump to **Tab 2 (Processes)**.
2. Press <kbd>c</kbd> to sort by CPU descending. The offending process will jump to the top row.
3. If the process is a background worker or build task, press <kbd>s</kbd> to **Suspend** it. This frees CPU cores immediately without destroying unsaved work.
4. If the process is rogue, press <kbd>x</kbd> to **Terminate** it.

### Scenario B: Memory Pressure & Disk Thrashing
1. Jump to **Tab 1 (Overview)** and inspect the **Physical RAM** and **VMM Swap** meters.
2. If Swap is climbing above 30%, jump to **Tab 5 (Health & Diagnostics)**.
3. Check the **Memory Fabric Radar** and read the **AI Diagnostic Insight Card**. The engine will identify the process with the highest Resident Set Size (RSS) and calculate whether paging is causing disk I/O bottlenecks.
4. Jump to **Tab 2 (Processes)**, press <kbd>m</kbd> to sort by RAM, and inspect the memory footprint of the top consumer.

### Scenario C: High Network Latency & Unknown Socket Activity
1. Jump to **Tab 4 (Network)**.
2. Review the **Sub-Cell Braille Sparklines** to check if ingress or egress bandwidth is saturated.
3. Scroll through the **Active Socket Map** on the right side of the screen to identify which PID is bound to active external connections.
4. If unexpected remote IP endpoints are detected, note the PID, jump to Tab 2, and press <kbd>Enter</kbd> to inspect the binary image path and parent process lineage.

---

*Authored with precision by Akshar Miyani.*
