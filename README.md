<div align="center">

```
  ███████╗██╗   ██╗██████╗ ██╗  ██╗ ██████╗ ██████╗ 
  ╚══███╔╝╚██╗ ██╔╝██╔══██╗██║  ██║██╔═══██╗██╔══██╗
    ███╔╝  ╚████╔╝ ██████╔╝███████║██║   ██║██████╔╝
   ███╔╝    ╚██╔╝  ██╔═══╝ ██╔══██║██║   ██║██╔══██╗
  ███████╗   ██║   ██║     ██║  ██║╚██████╔╝██║  ██║
  ╚══════╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝
```

### **The Next-Generation System Observatory & Diagnostics Platform**

*Your System. Visualized.*

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Language: Zig](https://img.shields.io/badge/Language-Zig_0.15+-orange.svg)](https://ziglang.org)
[![Platform: Linux | Windows | macOS](https://img.shields.io/badge/Platform-Linux%20|%20Windows%20|%20macOS-informational.svg)]()
[![Status: Active](https://img.shields.io/badge/Status-Active_Development-brightgreen.svg)]()

[Features](#-key-features) •
[Quickstart](#-quickstart) •
[Installation](#-installation) •
[Documentation](#-documentation) •
[Architecture](#-architecture) •
[Contributing](#-contributing)

</div>

---

## ⚡ What is Zyphor?

**Zyphor** is an ultra-fast, modern, cross-platform system observatory, process explorer, and diagnostics toolkit built from the ground up in **pure Zig**.

Traditional terminal monitors answer: *"What processes are running right now?"*  
**Zyphor answers:** ***"What is happening across my entire computer, WHY is it happening, and WHAT can I do about it?"***

```text
╭──────────────────────── ZYPHOR SYSTEM OBSERVATORY ────────────────────────╮
│ CPU  [████████████░░░░░░░░]  58.4% 3.8 GHz  │ MEMORY [██████████████░░░░] 71.2% 22.8 GB │
│ GPU  [████████░░░░░░░░░░░░]  34.0% 54°C     │ DISK   [█████░░░░░░░░░░░░░] 26.5% 420 GB  │
│ NET  ↓ 14.2 MB/s  ↑ 2.1 MB/s (Wi-Fi)        │ HEALTH [█████████████████░] 92/100 EXCELLENT│
├───────────────────────────────────────────────────────────────────────────┤
│ PID    NAME             CPU%    RAM      DISK R/W       NET I/O    THREADS │
│ 4821   chrome           18.4%   2.4 GB   0.4 / 1.2 MB/s 8.4 MB/s   84      │
│ 1290   code             11.2%   1.1 GB   2.1 / 0.0 MB/s 0.1 MB/s   42      │
│ 8391   zig-build         9.8%   840 MB   45.2 / 8.1MB/s 0.0 MB/s   16      │
│ 2011   postgres          2.1%   410 MB   0.1 / 0.8 MB/s 1.2 MB/s   28      │
╰───────────────────────────────────────────────────────────────────────────╯
```

---

## 🚀 Key Features

* **⚡ Blazing Fast & Zero Bloat:** Built with **Zig**, featuring double-buffered frame arenas, zero-garbage sampling loops, `< 50ms` startup time, and `< 1%` CPU footprint.
* **🌳 Deep Process Explorer & Tree:** Instantly toggle between flat process tables and hierarchical parent-child process trees with aggregated CPU/RAM rollups.
* **🩺 Explainable Diagnostics & Health Score:** Live health score (0-100) with deterministic root-cause analysis (e.g., detecting memory leaks, swap thrashing, runaway CPU, and I/O bottlenecks).
* **🖥️ Comprehensive Subsystem Monitoring:**
  * **CPU:** Per-core utilization grids, frequency scaling, temperature, and context switches.
  * **Memory:** Physical RAM breakdown (Used/Free/Cached/Available), swap rates, page faults.
  * **Storage:** Mount point capacity, filesystem types, and live disk I/O rates.
  * **Network:** Real-time throughput (RX/TX), interface packet rates, active connections.
  * **GPU & Thermals:** Dynamic hardware telemetry across NVIDIA, AMD, Intel, and Apple Silicon.
* **🎨 Modern Terminal UI (TUI):** Differential ANSI screen diffing, rich braille graphs, responsive grid layouts, and built-in themes (Midnight, Cyber, Aurora, Nord, Solarized, Plain).
* **🤖 Scriptable & Automation Ready:** Native CLI subcommands (`zyphor cpu`, `zyphor memory`, `zyphor process`, `zyphor doctor`), machine-readable `--json` output, and point-in-time snapshots.
* **🛡️ Defensive & Private by Default:** Zero telemetry, no cloud accounts, least-privilege execution, and safe confirmation prompts for process signals.

---

## 📦 Quickstart

### Run the Interactive TUI
```bash
# Launch interactive dashboard
zyphor

# Launch in plain mode (ASCII only, no color - perfect for low-spec terminals)
zyphor --plain

# Launch with custom refresh rate (milliseconds)
zyphor --refresh 500
```

### Instant CLI Diagnostics & Metrics
```bash
# Check system compatibility & sensor health
zyphor doctor

# Inspect CPU usage & per-core frequencies
zyphor cpu

# View memory usage & swap status
zyphor memory

# View top processes
zyphor process --sort cpu --limit 10

# Export complete system snapshot to JSON
zyphor snapshot
```

---

## 🛠️ Building from Source

### Prerequisites
* [Zig](https://ziglang.org/download/) **0.15.x** or higher
* Git

### Build & Run
```bash
# Clone the repository
git clone https://github.com/zyphor-project/zyphor.git
cd zyphor

# Build release binary
zig build -Doptimize=ReleaseFast

# Run tests
zig build test

# Run the binary
./zig-out/bin/zyphor
```

---

## 📚 Documentation

Exhaustive documentation is available in the [`docs/`](docs/) directory:

| Document | Description |
| :--- | :--- |
| 📖 [**User Manual**](docs/user-manual.md) | Complete guide to dashboard panels, process tree navigation, and controls |
| 🚀 [**Getting Started**](docs/getting-started.md) | Installation across Linux, Windows, macOS, and first-run guide |
| ⌨️ [**CLI Reference**](docs/cli-reference.md) | Command syntax, flags, subcommands, and JSON export formats |
| 🏗️ [**Architecture**](docs/architecture.md) | Low-level systems design, Zig memory allocators, and concurrency model |
| 🎨 [**Theming & Customization**](docs/theming-and-customization.md) | Configuration files, custom color themes, and layout engine |
| 🩺 [**Alerts & Diagnostics**](docs/alerts-and-diagnostics.md) | Root-cause analysis engine, health scoring rules, and anomaly triggers |
| 🧩 [**Platform Internals**](docs/platform-internals.md) | Deep dive into Windows NT, Linux `/proc`, and macOS Mach kernel APIs |
| 🤝 [**Contributing Guide**](docs/contributing.md) | Coding standards, testing workflows, and PR checklist |
| 🔧 [**Troubleshooting**](docs/troubleshooting.md) | Common terminal quirks, permission issues, and `zyphor doctor` |

---

## 🗺️ Keyboard Shortcuts

| Key | Action |
| :---: | :--- |
| <kbd>Tab</kbd> / <kbd>Shift+Tab</kbd> | Cycle through panels (Overview, Processes, Disks, Network, Diagnostics) |
| <kbd>↑</kbd> / <kbd>↓</kbd> / <kbd>j</kbd> / <kbd>k</kbd> | Navigate process list |
| <kbd>Enter</kbd> | Open detailed process inspector |
| <kbd>t</kbd> | Toggle hierarchical Process Tree view |
| <kbd>/</kbd> | Open live fuzzy search |
| <kbd>c</kbd> / <kbd>m</kbd> / <kbd>p</kbd> | Sort by CPU, Memory, or PID |
| <kbd>x</kbd> | Kill / Terminate selected process (with confirmation) |
| <kbd>T</kbd> | Cycle color themes |
| <kbd>Space</kbd> | Pause / Resume real-time polling |
| <kbd>?</kbd> | Show Help popup |
| <kbd>q</kbd> / <kbd>Ctrl+C</kbd> | Exit Zyphor |

---

## 🏛️ System Architecture

Zyphor enforces clean separation between metric acquisition, normalized data representation, and the presentation layer:

```
                            ┌────────────────────────┐
                            │    Zyphor TUI App      │
                            │ (Renderer / Widgets)   │
                            └───────────┬────────────┘
                                        │ Atomic Snapshot
                            ┌───────────┴────────────┐
                            │     Zyphor Core        │
                            │ (Engine / Diagnostics) │
                            └───────────┬────────────┘
                                        │ Normalized Metrics Interface
                 ┌──────────────────────┼──────────────────────┐
                 ▼                      ▼                      ▼
    ┌────────────────────────┐┌────────────────────┐┌────────────────────┐
    │    Windows Backend     ││   Linux Backend    ││   macOS Backend    │
    │ - NtQuerySystemInfo    ││ - /proc & /sys     ││ - sysctl & Mach    │
    │ - Win32 & PDH          ││ - Netlink          ││ - proc_pidinfo     │
    │ - DXGI & D3DKMT        ││ - Sysfs DRM / NVML ││ - IOKit / Metal    │
    └────────────────────────┘└────────────────────┘└────────────────────┘
```

---

## 📄 License

Zyphor is open-source software licensed under the **[MIT License](LICENSE)**.
