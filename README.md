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

Unlike traditional tabular layouts, Zyphor renders real-time telemetry like a **Command Center**:
- **Radial Dials & CPU Matrices:** Sub-pixel circular load gauges for CPU and Memory, coupled with per-core activity matrices.
- **Topological Process Lineage:** True depth-first search (`DFS`) process trees using Unicode box-drawing (`├─`, `└─`, `│`). Instantly suspend, resume, or kill misbehaving trees.
- **Masonry Grid Storage:** Drives and partitions are rendered as a responsive 2D masonry grid of beautiful floating cards, complete with localized capacity bars.
- **Global Network Matrices:** Massive, flowing Braille-based matrices for aggregate Ingress and Egress, alongside individual adapter tracking.
- **Root-Cause Diagnostics:** A composite 0-100 Health Score dial that detects memory leaks, swap thrashing, thermal throttling, and process zombie swarms automatically.

---

## ⚡ Zero-Flicker Architecture

Zyphor operates entirely on a **Double-Buffered Differential Rendering Engine**.
1. We snapshot OS telemetry (using `NtQuerySystemInfo` on Windows, `/proc` on Linux).
2. We draw everything to a virtual off-screen `ScreenBuffer`.
3. We compute a strict `Cell`-level diff against the previous frame.
4. We only emit the precise ANSI escape sequences for pixels that actually changed.

The result? Absolute zero tearing, zero flickering, and imperceptible overhead even at sub-100ms refresh rates.

---

## 🛠️ Quickstart

### Pre-built Binaries
Download the latest static binary for your architecture from the [Releases](https://github.com/miyaniakshar1234/Zyphor/releases) page. Zyphor is distributed as a single, zero-dependency executable.

### Build from Source
Building Zyphor requires [Zig 0.15.x](https://ziglang.org/download/):

```bash
git clone https://github.com/miyaniakshar1234/Zyphor.git
cd Zyphor
zig build -Doptimize=ReleaseFast
./zig-out/bin/zyphor
```

### CLI Automation Pipelines
Zyphor isn't just a UI; it's a scriptable observability engine:
```bash
# Full environment readiness, permissions, and sensor audit
zyphor doctor

# Top 10 processes sorted by CPU utilization
zyphor process --sort cpu --limit 10

# Export comprehensive instantaneous system snapshot to JSON for CI/CD
zyphor snapshot -o system-state.json
```

---

## 🎮 Global Controls & Navigation

Zyphor supports standard arrow keys, numerical hotkeys, and full **Vim-style navigation** (`h`, `j`, `k`, `l`, `g`, `G`):

| Key | Action | Description |
| :--- | :---: | :--- |
| <kbd>Tab</kbd> | Next Tab | Advances viewport across the 5 sub-systems. |
| <kbd>1</kbd> .. <kbd>5</kbd> | Direct Jump | Switch immediately to Overview, Processes, Storage, Net, or Health. |
| <kbd>/</kbd> | Search / Filter | Activates live search mode to filter processes by name or PID. |
| <kbd>Enter</kbd> | Deep Inspector | Opens full-screen process inspector modal for highlighted task. |
| <kbd>t</kbd> | Lineage Tree | Toggles hierarchical process parent/child trees. |
| <kbd>c</kbd> / <kbd>m</kbd> / <kbd>p</kbd> / <kbd>n</kbd>| Sort Modes | Instantly sort by CPU, Memory, PID, or Name. |
| <kbd>Space</kbd> | Pause/Resume | Toggles freeze mode on live telemetry sampling. |
| <kbd>T</kbd> | Cycle Theme | Cycles through 7 built-in 24-bit TrueColor palettes (Default: `Cyber`). |
| <kbd>?</kbd> | Help Modal | Opens full keyboard shortcut overlay. |
| <kbd>q</kbd> | Exit | Restores terminal cursor and exits cleanly. |

---

## 🎨 Built-in TrueColor Themes

Zyphor ships with 7 hand-tuned 24-bit TrueColor palettes designed for maximum legibility and reduced visual fatigue. The default theme is **Cyber**:

* ⚡ **Cyber (Default):** High-contrast cyberpunk palette with magenta `#FF0080`, neon blue `#00F0FF`, and an interpunct background matrix.
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
| 📖 [**Observatory User Manual**](docs/user-manual.md) | Full guide to every panel, process tree inspection, kill/suspend workflows, and telemetry metrics. |
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
