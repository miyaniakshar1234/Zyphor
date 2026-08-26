# Zyphor Documentation Hub

Welcome to the technical documentation for **Zyphor**, the high-performance, deterministic system observatory, process explorer, and diagnostics toolkit written in **pure Zig 0.15+**.

Zyphor is engineered for systems developers, infrastructure engineers, and performance analysts who require native kernel telemetry, sub-millisecond visualization, and explainable root-cause diagnostics with negligible CPU and memory overhead.

---

## 🗺️ Documentation Directory

```
docs/
├── getting-started.md            # Installation, prerequisites, and first-run guide
├── user-manual.md                # Interactive TUI guide, panels, and navigation
├── cli-reference.md              # CLI subcommands, flags, exit codes, and JSON API
├── architecture.md               # Systems architecture, memory model, and rendering engine
├── platform-internals.md         # Low-level kernel probes (Windows, Linux, macOS)
├── alerts-and-diagnostics.md     # Health scoring algorithm, heuristics, and anomaly engine
├── theming-and-customization.md  # 24-bit TrueColor palettes, themes, and configuration
├── contributing.md               # Developer setup, coding invariants, and PR workflow
└── troubleshooting.md            # Terminal rendering, code pages, permissions, and FAQ
```

---

## ⚡ Key Architectural Tenets

### 1. Zero Runtime Allocations
Zyphor utilizes a **double-buffered scratch arena** for frame-by-frame telemetry collection. The arena memory is pre-reserved during startup and reset with `.retain_capacity` on each tick. This guarantees zero heap fragmentation, zero memory leaks, and zero garbage collection pauses.

### 2. Differential ANSI Rendering Matrix
Rather than repainting the entire terminal grid every frame, Zyphor's presentation engine computes a cell-level diff between the previous and current frame buffers. Only modified cells trigger ANSI cursor repositioning and SGR escape sequences, reducing terminal I/O latency to microsecond thresholds.

### 3. Native Kernel Telemetry
Zyphor bypasses heavy userspace abstraction layers and talks directly to native kernel APIs:
* **Windows:** `NtQuerySystemInformation`, `Toolhelp32`, `GlobalMemoryStatusEx`, `GetDiskFreeSpaceExW`, DXGI/Direct3D 12.
* **Linux:** Direct `/proc` and `/sys` single-buffer parsers, `netlink` route sockets, sysfs DRM telemetry.
* **macOS:** Mach kernel host statistics, `proc_pidinfo`, `sysctlbyname`, IOKit/Metal sensors.

### 4. Explainable Diagnostics
Zyphor introduces a continuous **0–100 System Health Score** backed by deterministic root-cause analysis. It correlates multi-variate telemetry signals (CPU scheduler pressure, page faults, swap thrashing, disk queue depths, and network dropped packets) to identify system bottlenecks before catastrophic failure occurs.

---

## 🚀 Quick Links for New Users

* **Ready to install?** Read the [Getting Started Guide](getting-started.md).
* **Want to learn interactive controls?** Explore the [User Manual](user-manual.md).
* **Building automated scripts or CI checks?** Check the [CLI Reference](cli-reference.md).
* **Curious about internal systems engineering?** Read the [Systems Architecture](architecture.md).
* **Encountering terminal or permission quirks?** Consult [Troubleshooting & FAQ](troubleshooting.md).
