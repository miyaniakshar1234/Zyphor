# Zyphor Internal Systems Architecture

This document provides a low-level engineering specification of Zyphor's internal dataflow, memory management, concurrency model, and platform abstraction layer.

---

## 🏛️ High-Level System Architecture

```
                          ┌────────────────────────┐
                          │   Terminal UI Thread   │
                          │   - Event Loop (Async) │
                          │   - Buffer Renderer    │
                          │   - Widget Tree        │
                          └───────────┬────────────┘
                                      │ Atomic Epoch / Triple-Buffer Read
                          ┌───────────┴────────────┐
                          │  Engine / Aggregator   │
                          │  - Anomaly Detector    │
                          │  - Diagnostics Rules   │
                          │  - Health Evaluator    │
                          │  - Circular History    │
                          └───────────┬────────────┘
                                      │ Normalized Metric Types
              ┌───────────────────────┼───────────────────────┐
              ▼                       ▼                       ▼
   ┌─────────────────────┐ ┌─────────────────────┐ ┌─────────────────────┐
   │   Windows Backend   │ │    Linux Backend    │ │    macOS Backend    │
   │ - NtQuerySystemInfo │ │ - /proc & /sys      │ │ - sysctl & Mach     │
   │ - Win32 & PDH       │ │ - Netlink           │ │ - proc_pidinfo      │
   │ - DXGI / D3DKMT     │ │ - libdrm / NVML     │ │ - IOKit / Metal     │
   └─────────────────────┘ └─────────────────────┘ └─────────────────────┘
```

---

## 💾 Memory Architecture & Zero-Garbage Cadence

In systems monitoring, the tool itself must **never** become the source of CPU or memory overhead. Zyphor adheres to three strict memory rules:

### 1. Double-Buffered Frame Arenas
During every UI render tick and metric collection pass, transient string formatting (e.g. converting integers to formatted string buffers, building table rows, rendering braille points) uses an `std.heap.ArenaAllocator`.
* At the beginning of each frame: `scratch_arena.reset(.retain_capacity)`.
* Zero allocation calls escape to the OS heap during steady-state execution.

### 2. Struct-of-Arrays (SoA) Process Table
Traditional object-oriented designs use an Array-of-Structs (`[]Process`), where each process struct is 128+ bytes. Sorting 1,000 processes by CPU percentage requires swapping 128-byte records, evicting CPU cache lines.

Zyphor uses **Struct-of-Arrays (SoA)**:
```zig
pub const ProcessTable = struct {
    pids: []u32,
    ppids: []u32,
    cpu_percent: []f32,
    memory_rss: []u64,
    read_bytes_sec: []u64,
    write_bytes_sec: []u64,
    thread_counts: []u32,
    names: [][32]u8,
    count: usize,
};
```
* Sorting by CPU only scans and permutes the contiguous `cpu_percent: []f32` vector, fitting completely within L1/L2 cache.

### 3. Circular Ring Buffers for History
Historical metrics (1 minute, 1 hour, 24 hours) are stored in pre-allocated, fixed-capacity circular ring buffers:
```zig
pub fn HistoryBuffer(comptime T: type, comptime Capacity: usize) type {
    return struct {
        data: [Capacity]T,
        head: usize = 0,
        count: usize = 0,
        
        pub fn push(self: *@This(), value: T) void {
            self.data[self.head] = value;
            self.head = (self.head + 1) % Capacity;
            if (self.count < Capacity) self.count += 1;
        }
    };
}
```

---

## ⚡ Concurrency & Lock-Free State Swapping

Zyphor isolates metric acquisition from user interface rendering across dedicated threads:

1. **Main UI Thread:** Handles keyboard/mouse input and renders differential terminal cells at 30-60 Hz.
2. **Metrics Collector Thread:** Polls hardware counters and kernel APIs on tiered intervals (CPU: 250ms, Memory/Disk/Net: 500ms, Processes: 1000ms).
3. **Lock-Free State Publication:**
   - The collector writes to an offline snapshot buffer.
   - Once complete, it publishes the snapshot via an atomic pointer swap.
   - The UI thread reads the latest immutable snapshot without holding locks or mutexes.

---

## 🎨 Differential Terminal Rendering Engine

To ensure sub-millisecond render passes over SSH and terminal emulators, Zyphor implements a **Cell-Diffing Renderer**:

```
Previous Frame Buffer             Next Frame Buffer               Terminal Stream
┌───┬───┬───┬───┐                 ┌───┬───┬───┬───┐
│ A │ B │ C │ D │   Diffing Pass  │ A │ X │ C │ D │   ANSI Sequence
├───┼───┼───┼───┤  ─────────────► ├───┼───┼───┼───┤  ───────────────►  \x1b[1;2HX
│ E │ F │ G │ H │                 │ E │ F │ G │ H │                     (Only 1 cell updated!)
└───┴───┴───┴───┘                 └───┴───┴───┴───┘
```

* Only modified terminal cells emit ANSI escape sequences (`\x1b[row;colH`).
* Eliminates screen flicker, tearing, and high bandwidth overhead over remote SSH sessions.
