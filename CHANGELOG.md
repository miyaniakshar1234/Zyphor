# Changelog

All notable changes to **Zyphor** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-08-26

### Added
- **Core Engine & Architecture:**
  - High-performance, zero-garbage metric collection engine built with pure Zig 0.15.x.
  - Normalized `PlatformCollector` interface decoupling OS-specific syscalls from application logic.
  - Double-buffered frame allocator design eliminating heap churn during continuous sampling.
- **Native OS Backends:**
  - **Windows:** Native NT & Win32 backend (`NtQuerySystemInformation`, `GlobalMemoryStatusEx`, `GetSystemTimes`, `GetIfTable2`, `GetDiskFreeSpaceExW`).
  - **Linux:** `/proc` and `/sys` multi-core parser, thermal sensor discovery, network interface watcher.
  - **macOS:** Mach kernel `host_processor_info`, `mach_vm`, `proc_pidinfo` telemetry.
- **Process Explorer & Tree:**
  - Struct-of-Arrays (SoA) process table for ultra-fast column sorting (CPU, Memory, Threads, PID).
  - Parent-Child hierarchical process tree with interactive folding and aggregated resource metrics.
  - Safe process management (inspect, suspend, resume, terminate with confirmation).
- **Subsystem Observability:**
  - Multi-core CPU frequency, per-core utilization, system/user time split, thermal gauges.
  - Physical RAM breakdown (Used, Free, Cached, Available) and swap/pagefile telemetry.
  - Network interface activity (RX/TX throughput, bandwidth gauges).
  - Disk storage utilization, partition mounts, and available space.
  - System health scoring algorithm (0-100) with explainable category breakdowns.
- **Terminal User Interface (TUI):**
  - Modern, responsive TUI renderer with differential screen cell diffing.
  - Interactive panel switching (Overview, Processes, Disks, Network, Diagnostics).
  - Built-in theme engine (Midnight, Cyber, Aurora, Nord, Solarized, High Contrast, Plain).
  - Keyboard-first navigation and intuitive hotkeys (`Tab`, `/`, `k`, `r`, `t`, `?`, `q`).
- **CLI & Machine Output:**
  - Diagnostic command `zyphor doctor` checking OS APIs, permissions, and terminal support.
  - Instant metric subcommands: `zyphor cpu`, `zyphor memory`, `zyphor process`, `zyphor disk`, `zyphor network`.
  - Machine-readable `--json` output format for script automation and CI/CD pipelines.
  - Point-in-time state capture via `zyphor snapshot`.
- **Documentation:**
  - Complete `docs/` suite including User Manual, CLI Reference, Architecture Guide, Theming Guide, Platform Internals, and Troubleshooting.
