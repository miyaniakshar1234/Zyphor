# Zyphor Comprehensive User Manual

Welcome to the official manual for Zyphor. This document contains every tiny operational detail of the platform. By the end of this guide, you will be able to navigate the Observatory, intercept process trees, and read hardware telemetry like a seasoned Systems Engineer.

---

## 1. Subsystem Panels (The 7 Pillars)

Zyphor is split into 7 isolated metric panels. You can jump to them directly using the number keys (`1` through `7`), or cycle through them using `Tab` and `Shift+Tab`.

### [1] Overview Dashboard
The flight recorder. This panel aggregates the most critical data:
* **CPU Compute & Core Matrix:** A radial dial showing global CPU usage, plus an individual bar chart for every logical thread in your processor. 
* **Physical Memory Allocation:** Shows actual RAM usage vs. VMM (Virtual Memory Manager) Swap usage. If Swap climbs, your system is paging to disk.
* **Network Egress/Ingress:** Instantaneous throughput metrics for your NICs.
* **Diagnostics Stream:** A rolling ticker of anomalies detected by the AI engine.

### [2] Process Explorer
The deep-dive task manager.
* **Columns:** PID, User, CPU%, Resident Set Size (RSS), Virtual Size (VSIZE), Threads, and State.
* **Deep Inspector:** Press `Enter` on any process to open a side-pane detailing its parent PID, execution state, and exact memory mapping constraints.
* **Lineage Trees:** Press `t` to toggle DFS (Depth-First Search) mode. This indents child processes under their parents (e.g., `bash` -> `node` -> `esbuild`), making it trivial to find the root cause of a memory leak.

### [3] Storage & I/O
* **Partition Map:** Shows every mounted filesystem, its format (e.g., `NTFS`, `ext4`), and space utilization.
* **I/O Bandwidth:** Tracks instantaneous Read/Write bytes per second to detect disk bottlenecks.

### [4] Network Sockets
* **Adapters:** Lists hardware interfaces (like `eth0` or `Wi-Fi`) and their link states.
* **Global Flow Graphs:** High-resolution Braille-character sparklines visualizing the last 60 seconds of bandwidth usage.

### [5] Health & Diagnostics
The brain of Zyphor. The Heuristic Engine constantly analyzes the telemetry. If it detects an issue (like Thermal Throttling or high IRQ interrupts), it generates an **Insight Card**.
* **Severity Levels:** `EXCELLENT`, `FAIR`, `WARNING`, `CRITICAL`.
* **Playbooks:** Every warning includes an "Action" field—a plain-English instruction on how to resolve the bottleneck.

### [6] Services & Daemons
Monitors OS-level background workers (like `systemd` units or Windows Services).
* Displays the startup type (Automatic/Manual) and running status.

### [7] Containers
Connects to the local OCI/Docker daemon socket.
* Tracks container limits (CPU Quotas, Memory Limits) against actual usage, ensuring no single container starves the host.

---

## 2. Global Hotkeys & Keybinds

Zyphor heavily leverages Vim-style (`h, j, k, l`) keyboard navigation for speed. 

| Key(s) | Function | Granular Detail |
| :--- | :--- | :--- |
| `Up` / `k` | Move cursor up | Navigates lists (processes, services). |
| `Down` / `j` | Move cursor down | Navigates lists. |
| `PgUp` / `PgDn` | Page jump | Skips 10 items at a time for fast scrolling. |
| `g` / `G` | Top / Bottom | `g` jumps to the absolute top of the list, `G` to the very bottom. |
| `/` | Global Search | Opens a filter bar. Works dynamically across Processes, Services, and Containers. |
| `:` | Command Palette | Opens a floating searchable menu to execute any command in the app. |
| `t` | Toggle Tree | Switches the Process view between flat-list and parent-child tree. |
| `c`, `m`, `p`, `n` | Sort Toggles | Sort Processes by **C**PU, **M**emory (RSS), **P**ID, or **N**ame. |
| `Space` | Freeze View | Pauses the UI render loop. Useful if a process is jumping around and you want to lock it in place to read it. |
| `x` | Terminate (Kill) | Sends `SIGKILL` (Linux/Mac) or `TerminateProcess` (Windows). |
| `s` | Suspend | Sends `SIGSTOP` to freeze a process without killing it. |
| `u` | Resume | Sends `SIGCONT` to unfreeze a suspended process. |
| `]` or `Shift+T` | Cycle Theme | Hot-swaps the rendering colors. |
| `E` | Export Telemetry | **Instantly dumps the machine's current state to a JSON file (`zyphor-export-[timestamp].json`). Highly useful for incident post-mortems.** |
| `P` | Launch Profiler | Opens the Time-Bound Trace modal (see Section 3). |

---

## 3. The Process Profiler (Deep Trace)

If you suspect a process is behaving erratically, highlighting it and pressing `P` will open the **Performance Profiler**.
Zyphor will launch an isolated background thread that samples *only* that specific process at an extremely high frequency for 10 seconds.
It calculates:
1. **Peak Jitter:** The absolute maximum CPU spike during the trace.
2. **Rolling Averages:** Smoothing out the numbers to find the true baseline utilization.
3. **Memory Footprint:** Tracks if the RSS is slowly climbing (a sign of a memory leak) or stable.

---

## 4. CLI Toolchain (Headless Automation)

Zyphor is not just a visual tool. You can invoke it from your terminal scripts:

* `zyphor doctor` - Runs a 5-second environment audit to ensure Zyphor has kernel-level permissions.
* `zyphor bench` - Executes a native hardware benchmark (Integer MOP/s and Memory Bandwidth) and prints the results to stdout.
* `zyphor overhead` - Proves Zyphor's efficiency by running the telemetry loop 50 times in memory and timing it (usually completes in <10ms).
* `zyphor daemon` - Binds a TCP listener on port `7777` and serves the live OS state as JSON via HTTP. Useful for hooking Zyphor into Grafana or Prometheus.

---

*Prepared by Akshar Miyani.*
