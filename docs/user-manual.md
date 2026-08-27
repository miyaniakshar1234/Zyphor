# Zyphor Observatory User Manual

Zyphor is a mercilessly optimized system monitor. This manual covers how to navigate the TUI and interpret the hardware telemetry.

## The 7 Subsystems
Zyphor is divided into 7 distinct panels, navigable via \1\-\7\ or \Tab\:
1. **Overview (1):** High-level flight recorder. Displays top CPU/RAM consumption, real-time boot timing, power drain, and the anomaly event stream.
2. **Processes (2):** Deep-dive task manager. Features hierarchical tree views (\	\), search filtering (\/\), and real-time profiling (\P\).
3. **Storage (3):** Disk I/O bandwidth and partition space utilization.
4. **Network (4):** Socket tracking and active TCP/UDP connection matrices.
5. **Health & Diagnostics (5):** The AI-driven heuristic engine. Provides root-cause analysis for system bottlenecks.
6. **Services (6):** Background OS daemons (e.g. systemd or Windows Services).
7. **Containers (7):** OCI/Docker container tracking with isolated memory/CPU limits.

## The Process Profiler
Press \P\ on any process to trigger a time-bound trace. Zyphor will aggressively sample that specific PID for 10 seconds, bypassing standard refresh rates, to calculate peak jitter, minimum footprints, and exact average resource usage.

## Advanced Sorting
- \c\: CPU Descending
- \m\: Memory Descending
- \p\: PID Ascending
- \
\: Name Ascending
