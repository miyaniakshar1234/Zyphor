# ⚡ Zyphor

> **The Next-Generation Terminal Operating Environment & Systems Observatory**  
> *Zero-allocation, sub-pixel Braille rendering, and real-time hardware diagnostics written in pure Zig.*

[![Crates.io](https://img.shields.io/crates/v/zyphor.svg?color=fc8d62&logo=rust)](https://crates.io/crates/zyphor)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![GitHub](https://img.shields.io/badge/GitHub-Repository-181717?logo=github)](https://github.com/miyaniakshar1234/Zyphor)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey)](#)

---

## ⚡ Quick Start with Cargo

Install Zyphor directly via Cargo:

```bash
cargo install zyphor
```

Then launch the observatory:

```bash
zyphor
```

---

## 🚀 Key Highlights

* 🔬 **Sub-Pixel Braille Graphs:** High-density sparklines and trigonometric circular dials utilizing $2 \times 4$ Braille matrices.
* ⚡ **Zero-Allocation Architecture:** Double-buffered arena allocator resetting memory in $O(1)$ without heap thrashing.
* 🖥️ **Differential ANSI Engine:** Minimal diff rendering ensuring zero screen tearing and sub-0.1% CPU overhead.
* 🌳 **Topological Process Tree:** Parent-child process lineage with instant suspend (`SIGSTOP`), resume (`SIGCONT`), and termination (`SIGKILL`).
* 🩺 **Autonomous Health Radar:** 0–100 composite health scoring across CPU, memory pressure, swap thrashing, storage, and thermal metrics.
* 🚀 **Built-in Hardware Benchmarking:** Direct benchmark suite measuring single-core MOP/s, multi-core GFLOPS, and RAM bandwidth (`zyphor bench`).
* 🌐 **Live Network Speed & Stress Testing:** Multi-stream TCP throughput testing and latency/jitter diagnostics.
* 🕹️ **Quick Command Palette:** Floating action launcher (`Ctrl+P` or `:`) for rapid navigation and process control.

---

## 🎮 Keyboard Controls

Full Vim navigation support out of the box:

| Key | Action | Description |
| :--- | :---: | :--- |
| <kbd>Tab</kbd> / <kbd>Shift+Tab</kbd> | Next / Prev Tab | Navigate across Overview, Processes, Storage, Net, Health, Services, Docker. |
| <kbd>1</kbd> .. <kbd>7</kbd> | Direct Jump | Switch directly to a specific subsystem panel. |
| <kbd>:</kbd> / <kbd>Ctrl+P</kbd> | Command Palette | Open floating action launcher. |
| <kbd>/</kbd> | Search / Filter | Live search to filter processes or services. |
| <kbd>Enter</kbd> | Deep Inspector | Inspect process threads, memory map, environment, and open sockets. |
| <kbd>t</kbd> | Lineage Tree | Toggle tree hierarchy view vs flat sorted table. |
| <kbd>c</kbd> / <kbd>m</kbd> / <kbd>p</kbd> / <kbd>n</kbd> | Sort Modes | Sort processes by CPU %, Memory RSS, PID, or Name. |
| <kbd>x</kbd> / <kbd>s</kbd> / <kbd>u</kbd> | Process Actions | Kill (<kbd>x</kbd>), Suspend (<kbd>s</kbd>), or Resume (<kbd>u</kbd>) target task. |
| <kbd>Space</kbd> | Pause / Resume | Freeze telemetry stream for granular inspection. |
| <kbd>T</kbd> | Cycle Themes | Switch between 10 built-in TrueColor palettes (Default: `Anthropic`). |
| <kbd>?</kbd> | Help Modal | Open keybinding reference overlay. |
| <kbd>q</kbd> | Exit | Restore terminal screen buffer and exit cleanly. |

---

## 🛠️ CLI Automation Subcommands

```bash
# Comprehensive host audit and sensor discovery
zyphor doctor

# Run native compute and memory bandwidth benchmark
zyphor bench

# Diagnostic health check with root-cause recommendations
zyphor health

# Storage partitions and top directory consumers
zyphor disk

# Network interfaces and live socket connections
zyphor net

# Background services and daemons
zyphor services

# Top 10 processes sorted by CPU
zyphor process --sort cpu --limit 10

# Export complete system snapshot to JSON
zyphor snapshot -o snapshot.json
```

---

## 📚 Technical Documentation

* 📖 [**User Manual**](https://github.com/miyaniakshar1234/Zyphor/blob/master/docs/user-manual.md)
* 🧠 [**Architecture Specification**](https://github.com/miyaniakshar1234/Zyphor/blob/master/docs/architecture.md)
* 🚨 [**Alerts & Diagnostics Engine**](https://github.com/miyaniakshar1234/Zyphor/blob/master/docs/alerts-and-diagnostics.md)
* 🤖 [**CLI Reference**](https://github.com/miyaniakshar1234/Zyphor/blob/master/docs/cli-reference.md)
* 🧬 [**Platform Internals**](https://github.com/miyaniakshar1234/Zyphor/blob/master/docs/platform-internals.md)

---

## 📄 License

MIT © [Akshar Miyani](https://github.com/miyaniakshar1234)
