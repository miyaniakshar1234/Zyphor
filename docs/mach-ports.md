# Zyphor macOS Mach Port & Apple Silicon Telemetry

## Overview
On Darwin / macOS (x86_64 and Apple Silicon arm64), Zyphor interfaces with the Mach kernel layer via Mach port handles (`mach_host_self()`) and sysctl MIB trees.

## Metrics & Kernel Probes

- **Host Processor Statistics (`host_processor_info`):** High-precision CPU ticks per logical and performance core.
- **Unified Memory Architecture (`vm_statistics64`):** Active, wire, speculative, and compressed memory pages.
- **Apple Silicon Energy Profiler (`IOReport`):** P-Core (Firestorm/Avalanche) and E-Core (Icestorm/Blizzard) cluster wattage and GPU fabric utilization.
