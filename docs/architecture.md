# 🧠 Zyphor Internal Systems Architecture

*Author: Akshar Miyani • Version: 1.0.0 • Systems Engineering Deep Dive*

---

## Table of Contents
1. [Core Architectural Philosophy](#1-core-architectural-philosophy)
2. [Memory Management & Zero-Allocation Invariants](#2-memory-management--zero-allocation-invariants)
   - [The Double-Arena Swapping Model](#the-double-arena-swapping-model)
   - [Fixed-Size Buffer Allocation in Hot Paths](#fixed-size-buffer-allocation-in-hot-paths)
3. [Double-Buffered Differential Rendering Engine](#3-double-buffered-differential-rendering-engine)
   - [The ScreenBuffer & Cell Abstraction](#the-screenbuffer--cell-abstraction)
   - [Cell-Level Delta Diffing Algorithm](#cell-level-delta-diffing-algorithm)
   - [ANSI Stream Compression & Optimization](#ansi-stream-compression--optimization)
4. [Platform Telemetry Probing Pipeline](#4-platform-telemetry-probing-pipeline)
   - [Windows NT Kernel Interfacing (`ntdll.dll`)](#windows-nt-kernel-interfacing-ntdlldll)
   - [Linux Zero-Copy `/proc` Parser](#linux-zero-copy-proc-parser)
5. [Heuristic AI Diagnostics Engine](#5-heuristic-ai-diagnostics-engine)
6. [Plugin Architecture & Virtual Tables](#6-plugin-architecture--virtual-tables)
7. [Thread Model & Dynamic FPS Scheduling](#7-thread-model--dynamic-fps-scheduling)

---

## 1. Core Architectural Philosophy

Zyphor was architected around three non-negotiable systems engineering requirements:
1. **Zero-Allocation Hot Path:** A monitoring tool should not generate memory churn or trigger garbage collection pauses on the system it is tasked with observing.
2. **Deterministic O(Changes) Rendering:** Terminal update time must scale with the quantity of mutated data on screen, rather than screen resolution.
3. **Zero Kernel Abstraction Layers:** Bypasses heavy multi-megabyte frameworks (WMI, Python `psutil`, Electron) in favor of direct, zero-overhead OS system calls.

---

## 2. Memory Management & Zero-Allocation Invariants

### The Double-Arena Swapping Model

Standard monitoring applications typically allocate heap memory (via `malloc` or general-purpose allocators) to store dynamic arrays of processes, disk structures, and network sockets on every refresh cycle. Over prolonged monitoring sessions, this causes memory fragmentation, allocator lock contention, and latency spikes.

Zyphor eliminates heap allocations during standard monitoring by utilizing two alternating `std.heap.ArenaAllocator` instances: `FrameArenaA` and `FrameArenaB`.

```
 Cycle N (Even Frame):
 ┌─────────────────────────────────────────────────────────────┐
 │ FrameArenaA (Active Allocation Target)                      │
 │ ├── [ProcessInfo Array] (PID, CPU, RSS, Strings)            │
 │ ├── [DiskPartition Array]                                   │
 │ └── [NetworkInterface Array]                                │
 └─────────────────────────────────────────────────────────────┘
 ┌─────────────────────────────────────────────────────────────┐
 │ FrameArenaB (Holding Frame N-1 State for Diff Calculation)   │
 └─────────────────────────────────────────────────────────────┘

 End of Cycle N Transition:
 1. FrameArenaB is reset in O(1) time: arena_b.reset(.retain_capacity);
 2. Active pointer swaps to FrameArenaB for Cycle N+1.
```

#### Why This Works:
* **Zero Fragmentation:** Memory inside an arena is allocated sequentially in contiguous memory blocks.
* **Instant Freeing:** Clearing an arena does not traverse linked lists of heap nodes. It simply resets the arena's internal buffer offset pointer to zero (`O(1)` complexity).
* **Capacity Retention:** By specifying `.retain_capacity`, underlying virtual memory pages remain mapped to the process, eliminating OS page allocation syscalls after the initial warm-up frame.

---

### Fixed-Size Buffer Allocation in Hot Paths

For string formatting, status messages, and numerical conversions, Zyphor strictly forbids dynamic heap allocation. All string formatting uses `std.fmt.bufPrint` targeting stack-allocated fixed-size buffers (`[N]u8`):

```zig
// Example: Zero-allocation stack formatting
var status_buf: [128]u8 = undefined;
const formatted_status = try std.fmt.bufPrint(
    &status_buf,
    "Target: {s} (PID: {d}) | CPU: {d:.1}%",
    .{ proc.getName(), proc.pid, proc.cpu_percent }
);
```

---

## 3. Double-Buffered Differential Rendering Engine

### The ScreenBuffer & Cell Abstraction

Terminal emulators are notoriously slow when processing large volumes of ANSI escape sequences. Transmitting a full 120x40 screen buffer (4,800 cells) over `stdout` at 30 FPS requires transmitting hundreds of kilobytes per second, causing terminal cursor stuttering and high CPU consumption.

Zyphor solves this by modeling the terminal as an off-screen matrix of `Cell` structures:

```zig
pub const Cell = struct {
    char: u21 = ' ',         // UTF-8 / Unicode codepoint (supports Braille patterns)
    fg: Color = Color.white, // 24-bit RGB TrueColor foreground
    bg: Color = Color.black, // 24-bit RGB TrueColor background
    bold: bool = false,      // Bold text attribute
    dim: bool = false,       // Dim text attribute
    underline: bool = false, // Underline text attribute
};
```

Zyphor maintains two contiguous allocations of `Cell`:
1. `current_cells: []Cell` — The off-screen canvas where widgets draw the current frame.
2. `prev_cells: []Cell` — The exact snapshot of what is currently visible on the user's physical terminal screen.

---

### Cell-Level Delta Diffing Algorithm

During each render tick, Zyphor executes a 3-step pipeline:
1. **Compositing:** Widgets clear and paint the `current_cells` buffer in memory.
2. **Differential Sweep:** A linear sweep iterates through all cells, comparing `current_cells[i]` against `prev_cells[i]`.
3. **Damage Emitting:** When a discrepancy is found (`current_cells[i] != prev_cells[i]`), Zyphor positions the terminal cursor directly at `(x, y)` and emits the ANSI escape sequence for the new cell attributes.

```zig
// Conceptual Diffing Loop
var idx: usize = 0;
while (idx < total_cells) : (idx += 1) {
    const cur = current_cells[idx];
    const prev = prev_cells[idx];

    // Fast-path bitwise equality check
    if (!std.meta.eql(cur, prev)) {
        const x = @as(u16, @intCast(idx % width));
        const y = @as(u16, @intCast(idx / width));

        try emitCursorPosition(writer, x + 1, y + 1);
        try emitCellAttributes(writer, cur);
        try emitCodepoint(writer, cur.char);

        prev_cells[idx] = cur; // Update front buffer
    }
}
```

---

### ANSI Stream Compression & Optimization

To further minimize bytes sent over `stdout`, Zyphor implements attribute caching:
* If consecutive dirty cells share identical foreground and background colors, color escape sequences are **not re-emitted**.
* If consecutive dirty cells are horizontally contiguous, cursor positioning sequences (`\x1b[y;xH`) are omitted in favor of natural cursor advancement.

This reduces typical terminal I/O to **less than 2 KB per frame**, allowing Zyphor to run smoothly over SSH connections and slow terminal emulators.

---

## 4. Platform Telemetry Probing Pipeline

```
              ┌──────────────────────────────────────────────────────────┐
              │                   SystemEngine Loop                      │
              └────────────────────────────┬─────────────────────────────┘
                                           │
                      ┌────────────────────┴────────────────────┐
                      ▼                                         ▼
        ┌───────────────────────────┐             ┌───────────────────────────┐
        │   WindowsCollector        │             │   LinuxCollector          │
        │   (src/platform/windows)  │             │   (src/platform/linux)    │
        └─────────────┬─────────────┘             └─────────────┬─────────────┘
                      │                                         │
                      │ NtQuerySystemInformation                │ Direct /proc Parsing
                      ▼                                         ▼
        ┌───────────────────────────┐             ┌───────────────────────────┐
        │ Ring-0 Atomic Snapshot:   │             │ Stack-Buffered Parsing:   │
        │ • SystemProcessInfo       │             │ • /proc/stat (CPU Ticks)  │
        │ • SystemPerformanceInfo   │             │ • /proc/meminfo (RAM/Swap)│
        │ • Global CPU Thread Times │             │ • /proc/net/dev (Network) │
        │ • Physical Memory Map     │             │ • /proc/[pid]/stat (Procs)│
        └───────────────────────────┘             └───────────────────────────┘
```

### Windows NT Kernel Interfacing (`ntdll.dll`)
Standard Windows tools rely on WMI (Windows Management Instrumentation) or PDH (Performance Data Helper). WMI introduces multi-second query latencies and spawns `WmiPrvSE.exe` processes that consume significant CPU.

Zyphor connects directly to `ntdll.dll` using raw dynamic symbol loading (`GetModuleHandleA` / `GetProcAddress`):
* `NtQuerySystemInformation(SystemProcessInformation, ...)` retrieves every running process, thread count, user-mode CPU time, kernel-mode CPU time, and resident page count in a **single kernel context switch** taking under 2 milliseconds.
* Privilege checking uses `advapi32.dll` (`AllocateAndInitializeSid` and `CheckTokenMembership`) to determine whether Zyphor is running with elevated Administrator privileges.

---

### Linux Zero-Copy `/proc` Parser
On Linux, Zyphor parses the virtual filesystem `/proc` without spawning external shell utilities (`ps`, `top`, `free`):
* **CPU Load:** Reads `/proc/stat` to calculate deltas across `user`, `nice`, `system`, `idle`, `iowait`, `irq`, and `softirq` counters.
* **Memory Fabric:** Scans `/proc/meminfo` to extract `MemTotal`, `MemFree`, `MemAvailable`, `Cached`, `SwapTotal`, and `SwapFree`.
* **Network Flow:** Parses `/proc/net/dev` to calculate byte-level throughput for physical interfaces.
* **Process Lineage:** Iterates `/proc/[0-9]*/stat` directly, parsing process names, parent PIDs (`ppid`), thread counts, execution states, and resident page counts (`rss`).

---

## 5. Heuristic AI Diagnostics Engine

Located in `src/core/ai.zig`, the Heuristic Engine operates deterministically during each telemetry frame to correlate disparate metrics into explainable root-cause insights.

```
                          ┌──────────────────────────┐
                          │  SystemSnapshot Ingestion │
                          └─────────────┬────────────┘
                                        │
             ┌──────────────────────────┼──────────────────────────┐
             ▼                          ▼                          ▼
   [Thermal Velocity Check]    [VMM Thrashing Check]    [Memory Leak Heuristic]
   CPU Load > 85%              RAM > 85% + Swap > 20%   Process RSS > 1 GB
   Clock Drop vs Base          Disk I/O Wait Spiking    Monotonic Growth
             │                          │                          │
             └──────────────────────────┼──────────────────────────┘
                                        │
                                        ▼
                          ┌──────────────────────────┐
                          │    AIInsight Card Emit   │
                          │ • Diagnosis (What)       │
                          │ • Evidence (Why)         │
                          │ • Action Playbook (How)  │
                          └──────────────────────────┘
```

---

## 6. Plugin Architecture & Virtual Tables

Zyphor abstracts optional metric providers (such as Docker container tracking) through a Virtual Table (vtable) interface (`src/core/plugin.zig`):

```zig
pub const Plugin = struct {
    name: []const u8,
    ctx: *anyopaque,
    initFn: *const fn(ctx: *anyopaque, allocator: std.mem.Allocator) anyerror!void,
    updateFn: *const fn(ctx: *anyopaque, snapshot: *types.SystemSnapshot, allocator: std.mem.Allocator) anyerror!void,
    deinitFn: *const fn(ctx: *anyopaque, allocator: std.mem.Allocator) void,
};
```

This guarantees that external subsystem collectors (e.g., Docker, NVIDIA GPU, eBPF) remain completely decoupled from the core engine.

---

## 7. Thread Model & Dynamic FPS Scheduling

Zyphor operates on an adaptive event loop designed to conserve CPU when idle while providing fluid 30–60 FPS animation when modals or benchmarks are active:

* **Baseline Monitoring:** Sleep interval is set to **1000ms (1 FPS)**.
* **Interactive Navigation:** When a user is typing a search query or moving through lists, the event loop responds to input immediately without waiting for the timer.
* **Active Modal / Profiler Trace:** When a high-frequency modal (Process Profiler, Speed Test, Saturation Benchmark) is active, the loop dynamically accelerates to **33ms (~30 FPS)** to render smooth progress bars and live Braille graphs.

---

*Architected with precision by Akshar Miyani.*
