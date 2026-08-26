# Zyphor Documentation Hub

Welcome to the official documentation for **Zyphor**, the high-performance cross-platform system observatory, process explorer, and performance diagnostics toolkit written in Zig.

---

## 🧭 Navigation & Overview

### 🚀 Getting Started
* [**Getting Started Guide**](getting-started.md): Installation methods for Windows, Linux, and macOS, building from source, configuration prerequisites, and your first run.
* [**Troubleshooting & FAQ**](troubleshooting.md): Diagnosing permission constraints, terminal capability issues, and running `zyphor doctor`.

### 📖 User Manual & Reference
* [**Comprehensive User Manual**](user-manual.md): Deep walkthrough of all dashboard panels (Overview, Processes, Tree, Disks, Network, GPU, Diagnostics), keyboard shortcuts, and process actions.
* [**CLI & Automation Reference**](cli-reference.md): Detailed reference for command-line subcommands (`zyphor cpu`, `zyphor memory`, `zyphor process`, `zyphor doctor`), `--json` output, and point-in-time snapshot creation.
* [**Theming & Customization**](theming-and-customization.md): Configuring themes, keybindings, layout presets, and custom alert thresholds via TOML.

### 🏗️ Engineering & Architecture
* [**System Architecture**](architecture.md): Deep dive into memory management, double-buffered frame arenas, Struct-of-Arrays (SoA) process tables, and concurrency model.
* [**Platform Internals**](platform-internals.md): Low-level operating system APIs (Windows NT syscalls, Linux `/proc`/`/sys`, macOS Mach/sysctl), GPU discovery, and rootless telemetry.
* [**Alerts & Diagnostics Engine**](alerts-and-diagnostics.md): Deterministic root-cause analysis, anomaly detection, and explainable health score algorithms.
* [**Contributing Guide**](contributing.md): Setup Zig 0.15+ development environment, coding standards, test suite, and submitting pull requests.

---

## 🎯 Core Product Mission

Zyphor bridges the gap between raw terminal monitors and full-scale enterprise observability agents. Instead of running 5 separate utilities (`htop` + `iotop` + `iftop` + `nvtop` + `dstat`), Zyphor provides a unified, zero-overhead observatory that answers:

1. **What is happening?** (Instant macro health)
2. **Which subsystem is affected?** (CPU, Memory, Disk, Network, GPU, Thermals)
3. **Which process is responsible?** (Aggregated process trees and resource consumption)
4. **Why is it happening?** (Rule-based diagnostic explanation)
5. **What can be done?** (Safe, immediate remediation)
