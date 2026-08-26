# Zyphor Comprehensive User Manual

The **Zyphor User Manual** provides an exhaustive reference for operating the interactive Terminal User Interface (TUI), navigating dashboard panels, inspecting process lineage trees, managing processes defensively, and interpreting real-time telemetry graphs.

---

## 🖥️ User Interface Anatomy

When launched in full interactive mode (`zyphor`), the screen is divided into 4 primary visual zones:

```text
┌─────────────────────────────────────────────────────────────────────────────────┐
│ 1. Header Bar: Logo, Version, Title, and System Health Score Badge             │
├─────────────────────────────────────────────────────────────────────────────────┤
│ 2. Tab Navigation Bar: Active Panel Indicator & Section Switcher (1 - 5)        │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│ 3. Main Viewport: Context-specific subsystem visualization & data matrices      │
│    (Overview 4-Quadrant, Process Explorer, Storage, Network, Diagnostics)       │
│                                                                                 │
├─────────────────────────────────────────────────────────────────────────────────┤
│ 4. Status & Context Bar: Hotkey hints, dynamic status alerts, search status     │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🎛️ Navigation & Global Shortcuts

Zyphor supports standard terminal arrow keys, numerical hotkeys, and full **Vim-style navigation** (`h`, `j`, `k`, `l`, `g`, `G`):

| Key | Action | Description |
| :--- | :---: | :--- |
| <kbd>Tab</kbd> | Next Tab | Advances viewport to next subsystem tab (wraps around). |
| <kbd>Shift+Tab</kbd> | Prev Tab | Moves viewport to previous subsystem tab. |
| <kbd>1</kbd> | Overview | Directly selects Tab 1: 4-Quadrant Overview. |
| <kbd>2</kbd> | Processes | Directly selects Tab 2: Process Explorer & Lineage Tree. |
| <kbd>3</kbd> | Storage | Directly selects Tab 3: Filesystem & Disk I/O. |
| <kbd>4</kbd> | Network | Directly selects Tab 4: Network Adapters & Bandwidth. |
| <kbd>5</kbd> | Diagnostics | Directly selects Tab 5: System Health & Anomaly Rules. |
| <kbd>/</kbd> | Search / Filter | Activates live search mode to filter processes by name or PID. |
| <kbd>Enter</kbd> | Deep Inspector | Opens full-screen process inspector modal for highlighted task. |
| <kbd>Space</kbd> | Pause/Resume | Toggles freeze mode on live telemetry sampling. |
| <kbd>T</kbd> | Cycle Theme | Cycles through 7 built-in 24-bit TrueColor palettes. |
| <kbd>?</kbd> | Help Modal | Opens full keyboard shortcut overlay. |
| <kbd>q</kbd> / <kbd>Ctrl+C</kbd> | Exit | Restores terminal cursor and exits cleanly. |

---

## 📑 Viewport Tab Reference

### Tab 1: Overview Dashboard (4-Quadrant Grid)

The Overview panel provides an instantaneous holistic health snapshot split across 4 quadrants:

#### Top-Left: CPU Subsystem
* **Aggregated Load Meter:** Quarter-block sub-cell gradient gauge (`[████░░░░]`) dynamically shifting from emerald green (< 50%) to amber (50–75%) to crimson (> 85%).
* **Clock Frequency & Topology:** Displays active clock speed (MHz), logical core count, physical cores, and detected processor microarchitecture.
* **Double-Row Waveform Sparkline:** 120-sample rolling history graph using Unicode block glyphs (` ▂▃▄▅▆▇█`) for sub-second trend visualization.
* **Per-Core Mini Grid:** Individual bar meters for every logical core (`C0` through `C27+`) enabling immediate detection of single-threaded bottlenecks.

#### Top-Right: Memory Subsystem
* **Physical RAM Meter:** Real-time Used vs Total capacity in gigabytes with fine-grained percentage.
* **Swap/Pagefile Meter:** Virtual memory utilization and thrashing indicators.
* **Memory Pressure Indicator:** Kernel pressure state classified into `LOW (Healthy)`, `MEDIUM (Moderate)`, `HIGH (Contention)`, or `CRITICAL (Thrashing)`.
* **Rolling Memory Sparkline:** 120-sample trend of memory footprint changes.

#### Bottom-Left: GPU Subsystem
* **Discrete / Integrated GPU Name:** Direct3D 12 / Metal / NVML device detection.
* **Core Utilization %:** Compute engine load.
* **VRAM Residency:** Dedicated video memory allocation (e.g., `2.3 / 8.0 GB`).

#### Bottom-Right: Network Subsystem
* **Aggregate Throughput:** Real-time download (`↓ Ingress`) and upload (`↑ Egress`) throughput in megabytes per second.
* **Active Interfaces List:** IP address mapping and link status (`● UP` / `○ DOWN`).

---

### Tab 2: Process Explorer & Lineage Tree

The Process Explorer provides deep inspection of active OS tasks with millisecond-accurate CPU and memory accounting:

#### Process Navigation & Sorting
| Key | Sort Mode | Description |
| :---: | :--- | :--- |
| <kbd>c</kbd> | Sort by CPU% | Orders processes by descending CPU usage. |
| <kbd>m</kbd> | Sort by Memory | Orders processes by descending Resident Set Size (RSS). |
| <kbd>p</kbd> | Sort by PID | Orders processes ascending by Process ID. |
| <kbd>n</kbd> | Sort by Name | Orders processes alphabetically A–Z. |
| <kbd>↑</kbd> / <kbd>↓</kbd> or <kbd>j</kbd> / <kbd>k</kbd> | Navigate Rows | Moves selected row cursor (`▶`). |
| <kbd>PgUp</kbd> / <kbd>PgDn</kbd> | Page Scroll | Jumps viewport by half a screen page. |
| <kbd>Home</kbd> / <kbd>End</kbd> or <kbd>g</kbd> / <kbd>G</kbd> | Jump Bounds | Immediately jumps to top or bottom of process table. |

#### Interactive Search & Filter (<kbd>/</kbd>)
Pressing <kbd>/</kbd> activates the live search bar:
* Type any string to filter processes simultaneously by executable name or numeric PID.
* The process table updates instantly on every keystroke.
* Press <kbd>Enter</kbd> to confirm the active filter.
* Press <kbd>Esc</kbd> to cancel search mode and clear the filter.

#### Deep Process Inspector (<kbd>Enter</kbd>)
Pressing <kbd>Enter</kbd> on any highlighted process opens the **Deep Process Inspector Modal**:
* **Identity:** Process ID, Parent PID, Operational State (`Running`, `Sleeping`, `Disk Sleep`, `Stopped`).
* **Ownership:** Owning User account, active thread count.
* **Memory Breakdown:** Resident Working Set (RSS in MB and GB), Virtual / Pagefile allocation.
* **Direct Actions:** Dispatches <kbd>x</kbd> (Kill), <kbd>s</kbd> (Suspend), or <kbd>u</kbd> (Resume) directly from the inspector view.

#### Process Tree Mode (<kbd>t</kbd>)
Pressing <kbd>t</kbd> toggles the **Hierarchical Process Lineage Tree**. Instead of a flat list, processes are displayed with tree branch characters (`├─`, `└─`) showing parent-child relationships (PPID to PID). This makes it trivial to spot runaway sub-processes spawned by browsers, build tools, or container runtimes.

#### Defensive Process Signals (<kbd>x</kbd>, <kbd>s</kbd>, <kbd>u</kbd>)
* **Kill Process (<kbd>x</kbd>):** Displays a confirmation modal `Terminate "<name>" (PID <pid>)? [y] Confirm  [n/Esc] Cancel` before dispatching `SIGTERM` / `TerminateProcess`.
* **Suspend Process (<kbd>s</kbd>):** Sends `SIGSTOP` / `NtSuspendProcess` to freeze execution without losing process memory state.
* **Resume Process (<kbd>u</kbd>):** Sends `SIGCONT` / `NtResumeProcess` to resume execution.

---

### Tab 3: Storage & Filesystems

The Storage view monitors physical drives, partitions, and live I/O throughput:
* **Live Disk I/O Rates:** Real-time aggregate Read and Write bandwidth in MB/s along with IOPS counters.
* **Partition Table:** Mount point (e.g., `C:\`, `/`, `/data`), filesystem format (NTFS, ext4, APFS, btrfs, ZFS), used vs total gigabytes, and individual sub-cell capacity gauge bars.

---

### Tab 4: Network Adapters & Throughput

The Network view provides interface-level telemetry:
* **Aggregate Bandwidth Gauges:** Scaled visual gauges for total ingress/egress bandwidth.
* **Interface Detail Table:** Interface identifier, IPv4/IPv6 binding, transfer speed, and link operational state.

---

### Tab 5: System Health & Diagnostics

The Diagnostics view surfaces Zyphor's explainable root-cause diagnostic engine:
* **Composite Health Score (0–100):** Objective multi-factor assessment of system operational stability.
* **Subsystem Breakdown Scores:** Individual scores for CPU Compute, Physical RAM, Storage I/O, Network Link, and Thermal Zone.
* **Active Diagnostic Alerts:** List of fired heuristic rules (e.g., `[CRITICAL] Memory Pressure Exceeds Threshold`, `[WARNING] Storage Capacity > 85%`) with human-readable root-cause explanations.
