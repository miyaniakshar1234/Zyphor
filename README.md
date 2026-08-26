<div align="center">
  <img src="https://raw.githubusercontent.com/miyaniakshar1234/Zyphor/master/docs/assets/logo.png" alt="Zyphor Logo" width="120" />

  # Zyphor

  **The Next-Generation Terminal Operating Environment**  
  *Zero-allocation, blazing-fast system observatory written in pure Zig.*

  [![Zig 0.15+](https://img.shields.io/badge/Zig-0.15%2B-F7A41D?logo=zig)](https://ziglang.org)
  [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
  [![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
  [![Platform: Windows | Linux | macOS](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey)](#)
</div>

---

> **Why Zyphor?** `htop` is from 2004, and `btm` is too heavy. Zyphor is raw Zig performance combined with an unprecedented Sci-Fi HUD utilizing true sub-pixel Braille rendering, dynamic masonry layouts, and root-cause diagnostics. 

Zyphor entirely re-imagines what a terminal system monitor can be. We use $2 \times 4$ Braille matrices to push sub-pixel resolution graphs, custom trigonometric radial dials, and a zero-flicker double-buffered rendering engine that sips CPU cycles.

## 🚀 The Next-Gen Vibe

Unlike traditional tabular layouts, Zyphor renders real-time telemetry like a **High-Density Sci-Fi Command Center**:
- **Radial Dials & CPU Matrices:** Sub-pixel circular Braille load gauges for CPU and Memory, coupled with per-core activity heatmaps.
- **Topological Process Lineage:** True depth-first search (`DFS`) process trees using Unicode box-drawing (`├─`, `└─`, `│`). Instantly suspend, resume, or kill misbehaving trees.
- **Masonry Storage & Directory Tree Analyzer (PRD §16):** Responsive 2D masonry cards for mounted partitions coupled with a directory-level capacity tree explorer (`Program Files`, `AppData`, `Projects`).
- **Global Network & Active Socket Map (PRD §18):** Massive flowing Braille waveforms for aggregate Ingress/Egress, alongside live process-to-socket mapping (`PID`, `Local Port`, `Remote IP:Port`, `State`).
- **Explainable Root-Cause Diagnostics (PRD §30):** A composite 0-100 Health Score radar that detects memory leaks, swap thrashing, thermal throttling, and anomalies automatically with actionable remediation advice.
- **System Services & Daemons Observatory (PRD §23):** Real-time tracking of OS background services with startup type and status monitoring.
- **Quick Command Palette (PRD §33):** Instant developer-tool command launcher (`Ctrl+P` or `:`) for 17 direct actions, sorting modes, theme switches, and process controls.
- **Native Hardware Benchmark Engine (PRD §25):** Built-in single-core integer MOP/s, multi-threaded GFLOPS, and memory bandwidth (GB/s) profiler.

---

## ⚡ Zero-Flicker Architecture

Zyphor operates entirely on a **Double-Buffered Differential Rendering Engine**:
1. Telemetry snapshot sampled with near-zero overhead (`NtQuerySystemInfo` on Windows, `/proc` on Linux).
2. Renders all viewport layers to a virtual off-screen `ScreenBuffer`.
3. Computes a strict `Cell`-level diff against the previous frame.
4. Emits only the exact ANSI escape sequences for cells that changed.

The result? Absolute zero tearing, zero flickering, and sub-0.1% CPU overhead even at high refresh rates.

---

## 🛠️ Quickstart

### Pre-built Binaries
Download the latest static binary for your architecture from the [Releases](https://github.com/miyaniakshar1234/Zyphor/releases) page. Zyphor is distributed as a single, zero-dependency native executable.

### Build from Source
Building Zyphor requires [Zig 0.15.x](https://ziglang.org/download/):

```bash
git clone https://github.com/miyaniakshar1234/Zyphor.git
cd Zyphor
zig build -Doptimize=ReleaseFast
./zig-out/bin/zyphor
```

### CLI Automation & Diagnostics Pipelines
Zyphor isn't just a TUI; it's a scriptable observability engine:
```bash
# Full environment readiness, permissions, and sensor audit
zyphor doctor

# Run native CPU compute and RAM bandwidth benchmark
zyphor bench

# Explainable root-cause health & diagnostics audit
zyphor health

# Storage partitions and directory space consumer tree
zyphor disk

# Network interfaces and active process socket connection table
zyphor net

# OS background services and daemons
zyphor services

# Top 10 processes sorted by CPU utilization
zyphor process --sort cpu --limit 10

# Export comprehensive instantaneous system snapshot to JSON
zyphor snapshot -o system-state.json
```

---

## 🎮 Global Controls & Navigation

Zyphor supports standard arrow keys, numerical hotkeys, and full **Vim-style navigation** (`h`, `j`, `k`, `l`, `g`, `G`):

| Key | Action | Description |
| :--- | :---: | :--- |
| <kbd>Tab</kbd> / <kbd>Shift+Tab</kbd> | Next / Prev Tab | Advances viewport across the 6 sub-system panels. |
| <kbd>1</kbd> .. <kbd>6</kbd> | Direct Jump | Switch to Overview, Processes, Storage, Net, Health, or Services. |
| <kbd>:</kbd> / <kbd>Ctrl+P</kbd> | Command Palette | Opens floating quick action command palette (PRD §33). |
| <kbd>/</kbd> | Search / Filter | Activates live search mode to filter processes or services. |
| <kbd>Enter</kbd> | Deep Inspector | Opens full-screen process inspector modal for highlighted task. |
| <kbd>t</kbd> | Lineage Tree | Toggles hierarchical process parent/child trees. |
| <kbd>c</kbd> / <kbd>m</kbd> / <kbd>p</kbd> / <kbd>n</kbd>| Sort Modes | Instantly sort by CPU, Memory, PID, or Name. |
| <kbd>x</kbd> / <kbd>s</kbd> / <kbd>u</kbd> | Process Actions | Kill, Suspend (SIGSTOP), or Resume (SIGCONT) selected process. |
| <kbd>Space</kbd> | Pause/Resume | Toggles freeze mode on live telemetry sampling. |
| <kbd>T</kbd> | Cycle Theme | Cycles through 10 built-in 24-bit TrueColor palettes (Default: `Anthropic`). |
| <kbd>?</kbd> | Help Modal | Opens full keyboard shortcut overlay. |
| <kbd>q</kbd> | Exit | Restores terminal cursor and exits cleanly. |

---

## 🎨 Hand-Tuned TrueColor Themes

Zyphor ships with 10 built-in 24-bit TrueColor palettes. The default theme is **Anthropic**:

* 🏺 **Anthropic (Default):** Warm dark charcoal `#1F1D1C`, terracotta `#D97757`, biscuit sand `#E5C07B`, and sage green `#718E75`.
* ⚡ **Cyber:** High-contrast cyberpunk palette with magenta `#FF0080` and neon blue `#00F0FF`.
* 🌃 **Tokyo Night:** Deep indigo `#1a1b26`, electric cyan `#7dcfff`, and magenta `#bb9af7`.
* 💻 **Hacker:** Classic terminal aesthetic with CRT phosphors `#20C20E` and dark obsidian `#0C100C`.
* 🌌 **Midnight:** Deep slate-navy base with electric cyan and emerald accents.
* 🌿 **Aurora:** Nordic evening glow featuring seafoam greens and soft amethyst.
* ❄️ **Nord:** Arctic slate aesthetic based on authentic Nord design tokens.
* ☀️ **Solarized Dark:** Classic low-glare palette tuned for long diagnostic sessions.
* ☕ **Gruvbox:** Warm retro contrast with amber accents and terracotta highlights.
* ⬛ **High Contrast:** Pure monochrome black/white for maximum accessibility.

---

## 📚 Comprehensive Documentation

Exhaustive, deeply technical documentation is available in the [`docs/`](docs/) directory:

| Document | Focus Area |
| :--- | :--- |
| 📖 [**Observatory User Manual**](docs/user-manual.md) | Full guide to all 6 panels, process tree inspection, kill/suspend workflows, and telemetry metrics. |
| 🚀 [**Getting Started & Setup**](docs/getting-started.md) | Prebuilt binaries, distribution packages, source builds, permissions, and configuration. |
| 🤖 [**CLI & Automation Reference**](docs/cli-reference.md) | Subcommands, JSON schemas, pipeable automation scripts, and Prometheus exporters. |
| 🧠 [**Internal Systems Architecture**](docs/architecture.md) | Low-level systems design, zero-allocation memory models, double arenas, and differential rendering engine. |
| 🚨 [**Alerts & Diagnostics Engine**](docs/alerts-and-diagnostics.md) | Root-cause analysis heuristics, 0-100 health scoring formulas, anomaly detection, and hysteresis. |
| 🧬 [**Platform Internals & Probes**](docs/platform-internals.md) | Deep kernel telemetry implementation: Windows NT, Linux `/proc` & netlink, and macOS Mach ports. |
| 🤝 [**Contributing Guide**](CONTRIBUTING.md) | Coding standards, memory safety invariants, testing harness, benchmarking, and PR workflows. |

---

## 🤝 Contributing

We want to make Zyphor the undisputed king of terminal monitors. If you want to contribute new OS abstractions, UI widgets, or analytics engines, read our [Contributing Guide](CONTRIBUTING.md) to get started!

<div align="center">
  <i>Created and maintained with precision for the systems engineering community.</i>
</div>
