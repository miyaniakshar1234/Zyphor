<div align="center">
  <picture>
    <img src="assets/logo.svg" alt="ZYPHOR Logo" width="650">
  </picture>

  <p align="center">
    <strong>A mercilessly optimized, zero-allocation native systems observatory, real-time diagnostic engine, and process profiler.</strong>
  </p>

  [![Build Status](https://img.shields.io/github/actions/workflow/status/miyaniakshar1234/Zyphor/release.yml?branch=master&style=for-the-badge&logo=github)](https://github.com/miyaniakshar1234/Zyphor/actions)
  [![Zig Version](https://img.shields.io/badge/Zig-0.15.2+-F7A41D?style=for-the-badge&logo=zig)](https://ziglang.org)
  [![Binary Size](https://img.shields.io/badge/Binary_Size-1.1_MB-00f0ff?style=for-the-badge)](https://github.com/miyaniakshar1234/Zyphor/releases)
  [![Memory Footprint](https://img.shields.io/badge/RAM_Footprint-<3_MB-00ff66?style=for-the-badge)](docs/architecture.md)
  [![License](https://img.shields.io/badge/License-MIT-purple.svg?style=for-the-badge)](LICENSE)

  <p align="center">
    <a href="#-why-zyphor-the-manifesto">The Manifesto</a> •
    <a href="#-visual-tour--feature-walkthrough">Visual Tour</a> •
    <a href="#-feature-matrix--comparison">Comparison</a> •
    <a href="#-core-architecture--systems-design">Architecture</a> •
    <a href="#-cli-toolchain--automation">CLI Suite</a> •
    <a href="#-keyboard-controls--navigation">Keybinds</a> •
    <a href="#-installation--getting-started">Installation</a> •
    <a href="#-about-the-developer">Author</a> •
    <a href="docs/user-manual.md">User Manual</a>
  </p>
</div>

---

## 🛑 Why Zyphor? (The Manifesto)

Modern system monitoring software has lost its way. 

On one side, we have **bloated GUI applications and Electron wrappers** that consume hundreds of megabytes of RAM, take seconds to boot, and spin up entire Chromium browser instances just to display a CPU percentage. On the other side, we have **legacy terminal monitors** that write raw ANSI streams directly to `stdout`, causing severe visual tearing, flickering at high frame rates, and dropping frames when rendering complex graphs.

**Zyphor was designed and engineered by Akshar Miyani to eliminate this compromise.**

Built from bare metal in **Zig**, Zyphor operates on pure systems-programming principles:
1. **Direct Kernel Interfacing:** Bypasses slow management abstraction layers (like Windows WMI) in favor of raw ring-0 telemetry via `ntdll.dll` (`NtQuerySystemInformation`) on Windows and zero-copy `/proc` parsing on Linux.
2. **Zero-Allocation Render Loop:** The entire rendering pipeline runs with **zero general-purpose heap allocations** in the hot path. All frame allocations utilize dual swapping `ArenaAllocators` with instantaneous pointer resets.
3. **Double-Buffered Differential ANSI Engine:** Frames are rendered to an off-screen virtual framebuffer and diffed against the previous frame at the cell level. Only modified screen cells emit ANSI escape codes, yielding absolute zero flicker and rock-solid 30–60 FPS rendering at less than **0.1% CPU overhead**.
4. **Autonomous Root-Cause Diagnostics:** Zyphor does not simply dump numbers; an embedded heuristic engine mathematically correlates telemetry (thermal velocity, VMM swap thrashing, I/O wait) to provide actionable English playbooks for resolving system bottlenecks.
5. **Standalone 1.1 MB Single-File Executable:** Statically linked with zero runtime dependencies. No DLLs, no Python virtual environments, no node_modules.

---

## 📸 Visual Tour & Feature Walkthrough

Zyphor is organized into 7 distinct observatory subsystems, supplemented by modal overlays, profiling tools, and command palettes.

---

### 1. Overview Dashboard (System Matrix & Flight Recorder)
*Hotkey: `1`*

The master command center. Aggregates global compute metrics, thread-level distribution, physical vs. virtual memory allocation, live disk I/O rates, network flow, boot diagnostics, and the real-time AI anomaly stream.

<div align="center">
  <img src="screenshot/01-overview.png" alt="Zyphor Overview Dashboard" width="850">
</div>

* **Compute Core Matrix:** Radial load dial paired with granular per-core/per-thread utilization bar graphs.
* **Memory Breakdown:** Real-time visualization of Resident RAM vs. VMM Pagefile Swap pressure.
* **Boot & Power Diagnostics:** Kernel boot duration, system uptime counters, and battery discharge velocity.
* **Live Incident Stream:** Rolling chronological ticker of system threshold events.

---

### 2. Process Explorer & Deep Lineage Trees
*Hotkey: `2`*

A comprehensive process manager featuring instant search, live sorting, parent-child tree views, and deep inspection.

<div align="center">
  <img src="screenshot/02-processes.png" alt="Process Explorer and Lineage Tree" width="850">
</div>

* **Lineage Trees (`t`):** Recursive Depth-First Search (DFS) hierarchy view displaying parent/child process trees (e.g., `init` -> `systemd` -> `dockerd` -> `container-shim`).
* **Deep Inspector Pane (`Enter`):** Split-pane inspector displaying target PID, PPID, execution state, security context, thread count, and memory allocation quotas.
* **Live Sorting (`c`, `m`, `p`, `n`):** Instant re-sorting by CPU load, Resident Memory (RSS), Process ID, or Name.
* **Process Interception (`x`, `s`, `u`):** Send `SIGKILL` (Terminate), `SIGSTOP` (Suspend), or `SIGCONT` (Resume) directly from the interface.

---

### 3. Storage Fabrics & Disk I/O Analyzer
*Hotkey: `3`*

Granular visibility into local partitions, mounted filesystems, transfer speeds, and storage health.

<div align="center">
  <img src="screenshot/03-storage.png" alt="Storage and Disk Analyzer" width="850">
</div>

* **Partition Table:** Real-time space allocation across all mounted drives (`NTFS`, `ext4`, `apfs`, `btrfs`), showing total, used, free capacity, and mount targets.
* **I/O Bandwidth Gauges:** Live telemetry tracking instantaneous Read and Write throughput in MB/s along with real-time IOPS.

---

### 4. Network Observability & Socket Connection Matrix
*Hotkey: `4`*

Real-time traffic flow visualization, network interface hardware cards, and active process socket maps.

<div align="center">
  <img src="screenshot/04-network.png" alt="Network Dashboard and Active Sockets" width="850">
</div>

* **Sub-Cell Braille Sparklines:** 60-second rolling ingress (download) and egress (upload) charts rendered with Unicode Braille dot patterns for sub-character precision.
* **Adapter Status Cards:** Detailed statistics for physical and virtual network interface cards (NICs), including IPv4/IPv6 addresses, link status, and cumulative byte counters.
* **Active Socket Map:** Real-time mapping of open TCP/UDP sockets to specific process IDs, local ports, remote endpoints, and protocol states (`ESTABLISHED`, `LISTEN`, `TIME_WAIT`).
* **Broadband Speed & Stress Tools (`s`, `S`):** Integrated speed test runner and multi-stream network socket saturation benchmark.

---

### 5. Autonomous Root-Cause Diagnostics & Health Radar
*Hotkey: `5`*

An intelligent, explainable heuristics engine that answers the fundamental question: *"Why is my system slow?"*

<div align="center">
  <img src="screenshot/05-health-diagnostics.png" alt="Health Diagnostics and AI Remediation" width="850">
</div>

* **5-Subsystem Health Radar:** Discrete 0–100 health scoring for Compute, Memory Fabric, Storage I/O, Network Links, and Thermal Margins.
* **Explainable Root-Cause Insights:** Deterministic anomaly detection covering thermal throttling, VMM thrashing, memory leaks, high IRQ interrupt load, and rogue background processes.
* **Defensive Action Playbooks:** Every detected incident is accompanied by a concrete, plain-English remediation step.

---

### 6. System Services & Background Daemons
*Hotkey: `6`*

Real-time monitoring and control of operating system background services (Windows Services / systemd units).

<div align="center">
  <img src="screenshot/06-services.png" alt="System Services and Daemons" width="850">
</div>

* **Service Inventory:** Displays service display names, internal unit identifiers, process IDs, execution states (`RUNNING`, `STOPPED`, `STARTING`), and startup types (`Automatic`, `Manual`, `Disabled`).
* **Service Telemetry Inspector:** Dedicated side-card providing service descriptions, binary paths, and group assignments.

---

### 7. Container Observatory (Docker / OCI Engine)
*Hotkey: `7`*

Direct observation of local container runtimes via a modular plugin architecture.

<div align="center">
  <img src="screenshot/07-containers.png" alt="Containers and Docker Telemetry" width="850">
</div>

* **Resource Quota Tracking:** Real-time comparison of container memory usage against hard cgroup limits (`memory_limit_bytes`).
* **Container Telemetry:** Instant CPU percentage, isolated network ingress/egress, image tags, and lifecycle states (`running`, `exited`, `paused`).

---

### 8. Microsecond Process Profiler Modal
*Hotkey: `P`*

Time-bound, high-frequency rolling performance trace of any target process.

<div align="center">
  <img src="screenshot/09-profiler.png" alt="Process Profiler Modal" width="850">
</div>

* **10-Second High-Frequency Sampling:** Intercepts a target PID and samples its CPU and memory utilization at sub-frame intervals.
* **Telemetry Analysis:** Computes Peak Utilization Jitter, Minimum Footprint, and True Rolling Averages, graphing the trace into memory.

---

### 9. Quick-Action Command Palette
*Hotkey: `:` or `Ctrl+P`*

Floating, keyboard-centric launcher providing instant access to all internal operations.

<div align="center">
  <img src="screenshot/08-command-palette.png" alt="Command Palette" width="850">
</div>

* **Instant Jump:** Switch between all 7 views without remembering hotkeys.
* **Direct Actions:** Trigger hardware benchmarks, cycle themes, freeze telemetry polling, export snapshots, or initiate process termination.

---

### 10. Hand-Tuned 24-Bit TrueColor Theme Catalog
*Hotkey: `]` or `Shift+T`*

Zyphor ships with 10 built-in, meticulously calibrated 24-bit TrueColor themes designed for prolonged terminal monitoring sessions.

<div align="center">
  <table border="0">
    <tr>
      <td align="center"><b>Anthropic (Default Warm Aesthetic)</b><br><img src="screenshot/10-theme-anthropic.png" width="410"></td>
      <td align="center"><b>Cyber (High-Contrast Neon Cyberpunk)</b><br><img src="screenshot/11-theme-cyber.png" width="410"></td>
    </tr>
  </table>
</div>

* 🏺 **Anthropic (Default):** Warm charcoal base (`#1F1D1C`), terracotta accents (`#D97757`), sand highlights (`#E5C07B`), sage green meters (`#718E75`).
* ⚡ **Cyber:** High-contrast palette with electric cyan (`#00F0FF`) and neon magenta (`#FF0080`).
* 🌃 **Tokyo Night:** Deep indigo base (`#1A1B26`) with soft lavender and electric cyan.
* 💻 **Hacker:** Classic monochrome CRT phosphor aesthetic with obsidian black and radiant green (`#20C20E`).
* 🌌 **Midnight:** Navy slate foundation with ice-blue and emerald telemetry accents.
* 🌿 **Aurora:** Nordic evening glow featuring seafoam greens, teal bars, and soft amethyst borders.
* ❄️ **Nord:** Authentic arctic slate design tokens with frozen glacier blues.
* ☀️ **Solarized Dark:** Low-glare classic palette tuned for eye comfort during long operational sessions.
* ☕ **Gruvbox:** Retro warm-contrast palette with amber meters and terracotta highlights.
* ⬛ **High Contrast:** Pure black/white monochrome for accessibility and minimal terminal emulators.

---

## 📊 Feature Matrix & Comparison

| Feature / Metric | **Zyphor** | **htop** | **btop** | **Glances** | **Windows Task Mgr** |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Implementation Language** | **Zig (Native)** | C | C++ | Python | C++ / WinUI |
| **Binary Size** | **1.1 MB** | ~3.5 MB | ~8.2 MB | ~45 MB (deps) | System Native |
| **Memory Usage (RAM)** | **< 3 MB** | ~5 MB | ~25 MB | ~90 MB | ~60 MB |
| **Zero-Allocation Render Path** | **Yes (Dual Arena)** | No | No | No | No |
| **Double-Buffered Diff Engine** | **Yes (Zero Flicker)** | No (Flickers) | Partial | No | N/A |
| **Autonomous AI Diagnostics** | **Yes (Deterministic)**| No | No | Basic Alerts | No |
| **Time-Bound Process Profiler** | **Yes (Hotkey `P`)** | No | No | No | No |
| **Remote HTTP / TCP JSON Daemon**| **Yes (`zyphor daemon`)**| No | No | Yes (Web UI) | No |
| **Instant Telemetry Snapshot (`E`)**| **Yes (`.json`)** | No | No | Export flags | No |
| **Container Engine Telemetry** | **Yes (Docker/OCI)** | No | No | Yes | No |
| **Parent-Child Lineage Tree** | **Yes (`t` DFS)** | Yes | Yes | No | Partial |
| **Command Palette (`Ctrl+P`)** | **Yes** | No | No | No | No |
| **24-Bit TrueColor Palettes** | **10 Built-in** | 16-color | Custom RGB | 16-color | OS Theme |

---

## 🧠 Core Architecture & Systems Design

Zyphor's extreme performance is achieved through strict adherence to **Data-Oriented Design (DOD)** and cache-locality principles.

```
                    ┌──────────────────────────────────────────────┐
                    │               OPERATING SYSTEM               │
                    │   Windows (ntdll)   /   Linux (/proc)        │
                    └──────────────────────┬───────────────────────┘
                                           │ Direct Syscalls / Zero-Copy Reads
                                           ▼
                    ┌──────────────────────────────────────────────┐
                    │         CORE TELEMETRY ENGINE                │
                    │   CPU • RAM • Disks • Network • Services     │
                    └──────────────────────┬───────────────────────┘
                                           │
                                           ├──────────────────────────┐
                                           │ Snapshot Data            │
                                           ▼                          ▼
        ┌──────────────────────────────────────────────┐   ┌────────────────────────┐
        │        DOUBLE ARENA ALLOCATION MODEL         │   │ HEURISTIC AI ENGINE    │
        │  [FrameArenaA] ──swap──> [FrameArenaB]       │   │ Thermal / Thrashing    │
        │  (Zero heap mallocs in critical loop)        │   │ Anomaly Correlator     │
        └──────────────────────┬───────────────────────┘   └──────────┬─────────────┘
                               │                                      │
                               ▼                                      ▼
        ┌───────────────────────────────────────────────────────────────────────────┐
        │                  DOUBLE-BUFFERED DIFFERENTIAL RENDERER                    │
        │                                                                           │
        │  [Current Virtual Framebuffer]  <───diff───>  [Previous Screen Framebuffer]│
        │                                                                           │
        │                      Compute Cell Mutex Deltas:                           │
        │                      dirty_cells = (curr[i] != prev[i])                   │
        └──────────────────────────────────────┬────────────────────────────────────┘
                                               │
                                               ▼ Only modified ANSI sequences emitted
                                ┌──────────────────────────────┐
                                │     TERMINAL EMULATOR        │
                                │   Zero Tearing • 30–60 FPS   │
                                └──────────────────────────────┘
```

### Key Architectural Invariants:
1. **The Double-Arena Memory Model:** Two static arenas (`ArenaAllocator`) alternate every frame. Dynamic process lists and strings are allocated into the active arena. At the start of the next cycle, the inactive arena is completely cleared via an `O(1)` pointer reset, preventing heap fragmentation and memory leaks entirely.
2. **Cell-Level Differential Rendering:** The screen is maintained as an array of `Cell` structures containing glyphs and 24-bit RGB values. The rendering pass updates an off-screen buffer. The diffing pass compares `current_cells[i]` against `prev_cells[i]` and generates an optimized ANSI sequence that positions the cursor only where data has changed.
3. **Low-Latency Platform Probes:** 
   * On **Windows**, Zyphor links dynamically against `ntdll.dll` to invoke `NtQuerySystemInformation(SystemProcessInformation)`, retrieving global thread and process states in a single atomic kernel transition.
   * On **Linux**, Zyphor performs zero-copy parsing of `/proc/stat`, `/proc/meminfo`, `/proc/net/dev`, and `/proc/[pid]/stat` using pre-allocated stack buffers without regular expression engines.

---

## 🛠️ CLI Toolchain & Automation

Zyphor is designed for both interactive monitoring and automated headless scripting in CI/CD pipelines.

```bash
# 1. Start the interactive Zero-Flicker TUI
zyphor

# 2. Start TUI with a specific TrueColor theme (e.g., cyber, tokyo_night, hacker, nord)
zyphor --theme cyber

# 3. Plain ASCII mode for minimal or legacy terminals
zyphor --plain

# 4. Run an automated environment audit (Kernel probes, permissions, sensors)
zyphor doctor

# 5. Run native CPU compute (Integer MOP/s) and RAM bandwidth (GB/s) benchmarks
zyphor bench

# 6. Prove Zyphor's lightweight nature (Measures telemetry sampling latency & RAM footprint)
zyphor overhead

# 7. Start the headless TCP daemon streaming live JSON telemetry on port 7777
zyphor daemon

# 8. Export an instantaneous, comprehensive system telemetry snapshot to JSON
zyphor snapshot -o system-state.json

# 9. Query top processes from the CLI without launching the TUI
zyphor process --sort cpu --limit 10
```

---

## 🎮 Keyboard Controls & Navigation

Zyphor supports standard navigation keys, arrow keys, and full **Vim-style navigation** (`h`, `j`, `k`, `l`, `g`, `G`).

### Viewport Navigation
| Hotkey | Action | Description |
| :--- | :---: | :--- |
| <kbd>1</kbd> .. <kbd>7</kbd> | Direct Jump | Switch to Overview, Processes, Disks, Network, Health, Services, or Containers. |
| <kbd>Tab</kbd> / <kbd>Shift+Tab</kbd> | Next / Prev Tab | Advance viewport sequentially across panels. |
| <kbd>:</kbd> or <kbd>Ctrl+P</kbd> | Command Palette | Open floating quick-action command launcher. |
| <kbd>?</kbd> | Help Overlay | Display full modal cheatsheet of all keyboard shortcuts. |
| <kbd>q</kbd> or <kbd>Ctrl+C</kbd> | Clean Exit | Restore terminal cursor state and exit cleanly. |

### Process & List Manipulation
| Hotkey | Action | Description |
| :--- | :---: | :--- |
| <kbd>j</kbd> / <kbd>k</kbd> or <kbd>↓</kbd> / <kbd>↑</kbd> | Navigate Cursor | Move process / service selection down or up. |
| <kbd>g</kbd> / <kbd>G</kbd> | Top / Bottom | Jump cursor to the top or bottom of the list. |
| <kbd>PgUp</kbd> / <kbd>PgDn</kbd> | Page Scroll | Scroll list by 10 items at a time. |
| <kbd>/</kbd> | Global Search | Enter live search filter mode (filters active panel in real time). |
| <kbd>Esc</kbd> | Clear / Close | Clear active search query or close the open modal. |
| <kbd>Enter</kbd> | Deep Inspector | Toggle side-pane telemetry inspector for selected item. |
| <kbd>t</kbd> | Lineage Tree | Toggle hierarchical DFS process parent/child tree mode. |
| <kbd>c</kbd> / <kbd>m</kbd> / <kbd>p</kbd> / <kbd>n</kbd> | Sort Modes | Instantly sort by CPU%, Memory (RSS), PID, or Name. |
| <kbd>x</kbd> | Terminate (Kill) | Send `SIGKILL` / `TerminateProcess` to highlighted process. |
| <kbd>s</kbd> | Suspend | Send `SIGSTOP` to pause execution of target process. |
| <kbd>u</kbd> | Resume | Send `SIGCONT` to unpause execution of target process. |

### Telemetry & Diagnostics
| Hotkey | Action | Description |
| :--- | :---: | :--- |
| <kbd>P</kbd> | Process Profiler | Launch 10-second high-frequency telemetry trace on selected PID. |
| <kbd>E</kbd> | Export Snapshot | Dump instantaneous machine state to `zyphor-export-[timestamp].json`. |
| <kbd>Space</kbd> | Freeze Telemetry | Pause live sampling loop to freeze screen metrics for inspection. |
| <kbd>]</kbd> or <kbd>Shift+T</kbd> | Cycle Theme | Hot-swap between all 10 built-in 24-bit TrueColor palettes. |

---

## 📦 Installation & Getting Started

Zyphor compiles to a single, standalone `1.1 MB` static executable.

### 1. One-Line Universal Installers

#### Linux & macOS (Bash / Zsh):
```bash
curl -fsSL https://raw.githubusercontent.com/miyaniakshar1234/Zyphor/master/install.sh | bash
```

#### Windows (PowerShell):
```powershell
irm https://raw.githubusercontent.com/miyaniakshar1234/Zyphor/master/install.ps1 | iex
```

---

### 2. Native Package Managers

#### macOS & Linux (Homebrew):
```bash
brew tap miyaniakshar1234/zyphor
brew install zyphor
```

#### Windows (Winget):
```powershell
winget install miyaniakshar1234.Zyphor
```

#### Windows (Scoop):
```powershell
scoop bucket add zyphor https://github.com/miyaniakshar1234/scoop-zyphor
scoop install zyphor
```

#### Arch Linux (AUR):
```bash
yay -S zyphor-bin
# or
paru -S zyphor-bin
```

---

### 3. Build from Source

Building Zyphor requires [Zig 0.15.2+](https://ziglang.org/download/):

```bash
# Clone the repository
git clone https://github.com/miyaniakshar1234/Zyphor.git
cd Zyphor

# Compile with ReleaseFast optimizations
zig build -Doptimize=ReleaseFast

# The optimized static binary is generated at:
./zig-out/bin/zyphor
```

---

## 📚 Exhaustive Documentation Index

For in-depth operational and engineering guides, explore the dedicated documentation suite:

| Document | Focus Area |
| :--- | :--- |
| 📖 [**Observatory User Manual**](docs/user-manual.md) | Complete guide to all 7 panels, process trees, inspector cards, profiling workflows, and metrics. |
| 🧠 [**Internal Systems Architecture**](docs/architecture.md) | Low-level design, memory models, double arenas, differential rendering, and zero-allocation invariants. |
| 🚨 [**Alerts & Diagnostics Engine**](docs/alerts-and-diagnostics.md) | Heuristic algorithms, 0–100 health scoring formulas, anomaly detection, and remediation playbooks. |
| 🧬 [**Platform Internals & Probes**](docs/platform-internals.md) | Kernel telemetry implementations: Windows NT direct syscalls, Linux `/proc` zero-copy, and macOS Mach probes. |
| 🤖 [**CLI & Automation Reference**](docs/cli-reference.md) | Comprehensive subcommand reference, JSON export schemas, Prometheus exporter integration, and scripting recipes. |
| 🎨 [**Theming & Customization**](docs/theming-and-customization.md) | 24-bit TrueColor tokens, custom palette configuration, and visual overrides. |
| 🔧 [**Troubleshooting & FAQ**](docs/troubleshooting.md) | Terminal compatibility, Windows console modes, Linux capability permissions (`CAP_SYS_PTRACE`), and FAQ. |
| 🤝 [**Contributing Guide**](docs/contributing.md) | Coding standards, memory safety invariants, testing harness, benchmarking requirements, and PR workflows. |

---

## 👨‍💻 About the Developer

Zyphor was architected, designed, and built by **Akshar Miyani**.

* **Philosophy:** Software should treat hardware with absolute respect. A diagnostic tool should never impose a significant burden on the system it is tasked with observing.
* **Focus:** Low-level systems engineering, cache-friendly data-oriented design, kernel telemetry, compiler-level optimizations, and modern terminal user experiences.
* **GitHub:** [@miyaniakshar1234](https://github.com/miyaniakshar1234)
* **Repository:** [https://github.com/miyaniakshar1234/Zyphor](https://github.com/miyaniakshar1234/Zyphor)

---

## 📄 License

Zyphor is open-source software licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

<div align="center">
  <sub>Engineered with precision for the global systems community by <b>Akshar Miyani</b>.</sub>
</div>
