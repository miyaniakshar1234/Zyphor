<div align="center">
  <img src="https://raw.githubusercontent.com/miyaniakshar1234/Zyphor/master/assets/logo.svg" alt="Zyphor Logo" width="420" />
  <br />
  <p><strong>The Next-Generation Terminal Operating Environment & Systems Observatory</strong></p>
  <p><em>Zero-allocation, sub-pixel Braille rendering, and real-time hardware diagnostics written in pure Zig.</em></p>

  <a href="https://github.com/miyaniakshar1234/Zyphor"><img src="https://img.shields.io/badge/GitHub-Repository-181717?logo=github" alt="GitHub Repo" /></a>
  <a href="https://www.npmjs.com/package/zyphor"><img src="https://img.shields.io/npm/v/zyphor?color=CB3837&logo=npm" alt="npm version" /></a>
  <a href="https://ziglang.org"><img src="https://img.shields.io/badge/Zig-0.15-F7A41D?logo=zig" alt="Zig Version" /></a>
  <a href="https://github.com/miyaniakshar1234/Zyphor/blob/master/LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT" /></a>
  <a href="https://github.com/miyaniakshar1234/Zyphor/actions"><img src="https://img.shields.io/github/actions/workflow/status/miyaniakshar1234/Zyphor/ci.yml?branch=master&label=CI" alt="CI Status" /></a>
</div>

---

## ⚡ Quick Launch

Run Zyphor immediately without global installation:

```bash
# Execute instantly via npx
npx zyphor

# Or run with Bun / PNPM
bunx zyphor
pnpm dlx zyphor
```

Or install globally as your default terminal monitor:

```bash
npm install -g zyphor
# or
bun install -g zyphor
pnpm add -g zyphor
yarn global add zyphor
```

---

## 🚀 Why Zyphor?

Traditional terminal monitors like `htop` are decades old, and alternative tools often suffer from high CPU consumption and terminal flickering. **Zyphor** delivers raw native performance:

* 🔬 **Sub-Pixel Braille Visualizations:** $2 \times 4$ Braille matrices deliver high-density sparklines, trigonometric radial gauges, and flowing ingress/egress network waveforms.
* ⚡ **Zero-Allocation Architecture:** Double-buffered arena model resets memory in $O(1)$ without standard heap thrashing.
* 🖥️ **Differential ANSI Rendering:** Frame diffing ensures zero screen tearing and sub-0.1% CPU overhead even at 60 FPS.
* 🌳 **Topological Process Tree:** Live parent-child lineage explorer with instant process suspend (`SIGSTOP`), resume (`SIGCONT`), and termination (`SIGKILL`).
* 🩺 **Autonomous Health Radar:** 0–100 composite health score evaluating CPU saturation, memory pressure, swap thrashing, storage margins, and thermal limits.
* 🚀 **Integrated Hardware Benchmarks:** Built-in compute benchmarking (`zyphor bench`) measuring single-core integer MOP/s, multi-core GFLOPS, and RAM bandwidth in GB/s.
* 🌐 **Live Network Speed & Stress Testing:** Multi-stream TCP throughput testing and latency/jitter diagnostics directly within the TUI.
* 🕹️ **Quick Command Palette:** Floating command launcher (`Ctrl+P` or `:`) with 17 direct actions, sorting modes, and theme switchers.

---

## 🎮 Navigation & Keyboard Controls

Full Vim navigation and hotkey support:

| Key | Action | Description |
| :--- | :---: | :--- |
| <kbd>Tab</kbd> / <kbd>Shift+Tab</kbd> | Next / Prev Tab | Navigate across Overview, Processes, Storage, Net, Health, Services, Docker. |
| <kbd>1</kbd> .. <kbd>7</kbd> | Direct Jump | Switch directly to a specific subsystem panel. |
| <kbd>:</kbd> / <kbd>Ctrl+P</kbd> | Command Palette | Open floating action and configuration launcher. |
| <kbd>/</kbd> | Search / Filter | Filter live process tree or system service list. |
| <kbd>Enter</kbd> | Deep Inspector | Inspect process threads, memory map, environment, and open sockets. |
| <kbd>t</kbd> | Lineage Tree | Toggle tree hierarchy view vs flat sorted table. |
| <kbd>c</kbd> / <kbd>m</kbd> / <kbd>p</kbd> / <kbd>n</kbd> | Sort Modes | Sort processes by CPU %, Memory RSS, PID, or Name. |
| <kbd>x</kbd> / <kbd>s</kbd> / <kbd>u</kbd> | Process Actions | Kill (<kbd>x</kbd>), Suspend (<kbd>s</kbd>), or Resume (<kbd>u</kbd>) target task. |
| <kbd>Space</kbd> | Pause / Resume | Freeze telemetry stream for granular inspection. |
| <kbd>T</kbd> | Cycle Themes | Switch between 10 built-in TrueColor palettes (Default: `Anthropic`). |
| <kbd>?</kbd> | Help Modal | Open keybinding reference overlay. |
| <kbd>q</kbd> | Exit | Restore terminal screen buffer and exit cleanly. |

---

## 🛠️ CLI Automation & Scripting

Zyphor provides pipeable JSON and plaintext diagnostics for automated monitoring:

```bash
# Comprehensive host audit and sensor discovery
zyphor doctor

# Run native CPU compute and memory bandwidth benchmark
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

## 🎨 Built-in TrueColor Themes

Zyphor ships with 10 hand-tuned 24-bit color palettes:
* 🏺 **Anthropic (Default):** Warm dark charcoal, terracotta accents, biscuit sand, and sage green.
* ⚡ **Cyber:** High-energy magenta and neon cyan.
* 🌃 **Tokyo Night:** Deep indigo with pastel blue and violet accents.
* 💻 **Hacker:** CRT phosphor green over dark obsidian.
* 🌌 **Midnight:** Deep navy slate with electric blue highlights.
* ❄️ **Nord:** Arctic slate aesthetic based on authentic Nord tokens.
* ☕ **Gruvbox:** Warm retro contrast with amber accents.
* ⬛ **High Contrast:** Pure black and white for accessibility.

---

## 📚 Documentation

* 📖 [**User Manual**](https://github.com/miyaniakshar1234/Zyphor/blob/master/docs/user-manual.md)
* 🧠 [**Architecture Specification**](https://github.com/miyaniakshar1234/Zyphor/blob/master/docs/architecture.md)
* 🚨 [**Alerts & Diagnostics Engine**](https://github.com/miyaniakshar1234/Zyphor/blob/master/docs/alerts-and-diagnostics.md)
* 🤖 [**CLI Reference**](https://github.com/miyaniakshar1234/Zyphor/blob/master/docs/cli-reference.md)
* 🧬 [**Platform Internals**](https://github.com/miyaniakshar1234/Zyphor/blob/master/docs/platform-internals.md)

---

## 📄 License

MIT © [Akshar Miyani](https://github.com/miyaniakshar1234)
