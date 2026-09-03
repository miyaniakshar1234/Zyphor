# Zyphor System Architecture & Engineering Internals

## High-Level Architectural Model

Zyphor is engineered as a low-latency, native systems observability engine written in Zig 0.15.2. It delivers real-time system metrics, lineage tree analysis, hardware sensors, and kernel logs with zero-overhead differential ANSI rendering.

```
┌─────────────────────────────────────────────────────────────┐
│                    Zyphor Terminal UI (TUI)                 │
│  ┌───────────────────────┐       ┌───────────────────────┐  │
│  │ 6 Powerhouse Screens  │       │ Multi-Signal Modals   │  │
│  └───────────┬───────────┘       └───────────┬───────────┘  │
│              └───────────────┬───────────────┘              │
│                              ▼                              │
│                 ScreenBuffer & Diff Engine                  │
│               (Cell Comparison & ANSI Stream)               │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│                    SystemEngine Core Layer                  │
│  ┌───────────────────────┐       ┌───────────────────────┐  │
│  │ SystemHistory RingBuf │       │ FlightRecorder (60s)  │  │
│  └───────────────────────┘       └───────────────────────┘  │
│  ┌───────────────────────┐       ┌───────────────────────┐  │
│  │ Health & Alert Engine │       │ Process Tree Lineage  │  │
│  └───────────────────────┘       └───────────────────────┘  │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│                 Platform Abstraction Layer                  │
│   ┌──────────────┐     ┌──────────────┐     ┌─────────────┐ │
│   │ Windows PDH  │     │ Linux /proc  │     │ macOS Mach  │ │
│   └──────────────┘     └──────────────┘     └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## 6 Consolidated Powerhouse Viewports

To prevent tab header truncation on narrow or standard terminals (80–120 columns), Zyphor consolidates all monitoring capabilities into 6 high-density screens:

1. **`⬡ 1: Overview` (btop++ 4-Quadrant Architecture):**
   - **Quadrant 1 (Top-Left):** CPU Compute Fabric — AVX2/FMA3/BMI2 capabilities, per-core frequencies, user/sys/iowait load breakdown, rolling 2x4 Braille Area Waveform history graph, and multi-core heatmap grid.
   - **Quadrant 2 (Bottom-Left):** Memory & Virtual Pagefile Fabric — RAM usage, App vs Page Cache segmented bar, rolling Braille memory history, Swap pagefile bar, and PSI (Pressure Stall Information).
   - **Quadrant 3 (Top-Right):** Storage & Disk I/O Fabric — Filesystem mounts, read/write MB/s throughput, aggregate IOPS, and rolling Braille disk throughput waveform.
   - **Quadrant 4 (Bottom-Right):** Network Oscilloscope & Sockets — Ingress/Egress MB/s, rolling Braille network waveform, active adapter, and TCP connection count.
   - **Bottom HUD Strip:** Dedicated Hardware Acceleration & Sensor HUD — Discrete GPU engine load, dedicated VRAM footprint, core temperatures, clock frequencies, and ACPI battery power metrics.

2. **`◈ 2: Processes`:**
   - Real-time process matrix with CPU, RSS, PID, User, Threads, IOPS, and dynamic lineage tree hierarchy with cycle-proof DFS traversal.

3. **`⬢ 3: Storage`:**
   - Physical disk topology, mount partitions, usage gauges, IOPS metrics, and directory space analyzer.

4. **`◉ 4: Network`:**
   - Network adapter fabric, bandwidth meters, active TCP/UDP socket table, and built-in latency/saturation benchmarks.

5. **`⚡ 5: Hardware & GPU`:**
   - Discrete GPU accelerators (NVIDIA/AMD/Intel), dedicated VRAM allocations, thermal heatmap, fan RPM, battery status, and instruction set extensions.

6. **`❤ 6: Observability & Logs`:**
   - Unified system health score (0–100) with 5-subsystem radar, active daemon services with process state, and live kernel event flight log stream with interactive search filtering.

---

## Subsystem Breakdown

### 1. Differential Screen Buffer (`src/ui/buffer.zig`)
- **2D Frame Buffers (`cells` and `prev_cells`):** Compares character, foreground/background TrueColor, bold, and underline state cell-by-cell.
- **Differential ANSI Streaming:** Generates minimal ANSI escape sequences (`\x1b[y;xH`) only for changed cells, cutting terminal write bandwidth by over 90%.
- **Auto-Chunk Flushing:** Automatically flushes chunks when the ANSI buffer reaches 60 KB, preventing buffer overflows on ultra-wide 4K/8K displays.

### 2. Zero-Allocation History Ring Buffer (`src/core/history.zig`)
- Circular 120-slot ring buffer tracking rolling telemetry across all hardware sensors.
- **NaN-Resilient Metrics:** Filters out corrupted sensor samples and division-by-zero floating point anomalies.
- **Inline Percentile Estimation:** Computes `p50`, `p90`, `p99` without dynamic heap allocations in hot render loops.

### 3. Cycle-Proof Process Tree Engine (`src/process/tree.zig`)
- **Parent Traversal Validation:** Detects and prevents cyclic parent-child PPID loops (`wouldCreateCycle`).
- **Aggregate Metric Propagation:** Recursively bubbles child process CPU and RSS usage up the tree to parent processes.

### 4. Explainable Health Diagnostic Engine (`src/alerts/health.zig`)
- Computes composite health scores across compute, memory, storage, and network subsystems.
- Emits structured actionable remediation playbooks for automated self-healing.

### 5. Dynamic Responsive Tab Bar (`src/ui/widgets.zig`)
- Employs adaptive label shortening based on terminal column width:
  - `< 82 columns`: `Overview`, `Procs`, `Disks`, `Net`, `HW`, `Logs`
  - `82–104 columns`: `Overview`, `Processes`, `Storage`, `Network`, `Hardware`, `Observability`
  - `≥ 105 columns`: Full descriptive titles
- Completely eliminates tab bar clipping and horizontal scroll bugs on small screens.

---

*Lead Architect: Akshar Miyani ([@miyaniakshar1234](https://github.com/miyaniakshar1234))*
