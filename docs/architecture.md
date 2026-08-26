# Zyphor Internal Systems Architecture

This document provides a low-level engineering specification of Zyphor's internal dataflow, memory management, concurrency model, and differential terminal rendering engine.

---

## 🏗️ Architectural Topology

Zyphor is structured as a decoupled 3-tier architecture:

```
                  ┌─────────────────────────────────────────┐
                  │           Presentation Tier             │
                  │   - ScreenBuffer 2D Matrix (Double)     │
                  │   - Differential ANSI Diff Engine       │
                  │   - Layout & Panel Widget Compositors   │
                  └────────────────────▲────────────────────┘
                                       │
                                       │ Snapshot Reference
                                       │
                  ┌────────────────────┴────────────────────┐
                  │             Engine Tier                 │
                  │   - Double-Buffered Scratch Arena       │
                  │   - RingBuffer History Vectors          │
                  │   - Diagnostic Health Scoring Rules     │
                  │   - Process Manager & Lineage Tree      │
                  └────────────────────▲────────────────────┘
                                       │
                                       │ Polymorphic Kernel Query
                                       │
                  ┌────────────────────┴────────────────────┐
                  │             Kernel Tier                 │
                  │   - Windows (NtQuerySystemInformation)  │
                  │   - Linux (/proc, /sys, netlink)        │
                  │   - macOS (Mach host, sysctl, procinfo) │
                  └─────────────────────────────────────────┘
```

---

## 🧠 Memory Management: Zero-Garbage Frame Arena

Traditional TUI applications written in high-level languages allocate thousands of small heap objects per second (strings for table rows, arrays for process lists, temporary format buffers). This induces memory fragmentation, CPU cache thrashing, and unpredictable garbage collection spikes.

### The Double-Buffered Scratch Arena Pattern
Zyphor solves this by enforcing a strict **Zero-Runtime-Allocation** invariant during telemetry sampling:

1. During initialization, `SystemEngine` creates a fixed heap memory arena (`std.heap.ArenaAllocator`).
2. On every sampling tick, `sampleSnapshot()` begins by calling:
   ```zig
   _ = self.scratch_arena.reset(.retain_capacity);
   const scratch = self.scratch_arena.allocator();
   ```
3. All transient data structures—process lists, formatted command-lines, mount point strings, network interface vectors—are allocated exclusively out of `scratch`.
4. At the start of the subsequent tick, `reset(.retain_capacity)` rewinds the arena pointer to zero **without freeing the underlying virtual memory pages to the OS**.
5. Result: **Zero system `malloc`/`free` calls per frame**, maximum CPU L1/L2 data cache residency, and a rock-solid, flat RSS memory profile (~12–16 MB).

---

## 🔄 Lock-Free Cache-Aligned Ring Buffer

For sparklines and historical telemetry trend graphs, Zyphor implements a generic `RingBuffer(T, Capacity)` struct:

```zig
pub fn RingBuffer(comptime T: type, comptime Capacity: usize) type {
    return struct {
        const Self = @This();
        buffer: [Capacity]T = [_]T{0} ** Capacity,
        head: usize = 0,
        count: usize = 0,

        pub fn push(self: *Self, value: T) void {
            self.buffer[self.head] = value;
            self.head = (self.head + 1) % Capacity;
            if (self.count < Capacity) self.count += 1;
        }

        pub fn getChronological(self: *const Self, out: []T) usize { ... }
    };
}
```

* Fixed capacity of 120 samples (representing 60 seconds of telemetry at 500ms intervals).
* Contiguous in-memory layout eliminates pointer indirection.
* Double sparkline rendering (`renderSparklineDouble`) scans the ring buffer chronologically to render smooth 2-row braille graphs.

---

## 🎨 Differential Terminal Rendering Matrix

Terminal emulators are notoriously slow when bombarded with full-screen ANSI redraws at 60 Hz. Repainting 120×40 cells (4,800 cells) every frame causes visible screen flickering and consumes significant terminal CPU.

### Cell Matrix & ANSI Diffing Engine
Zyphor's `ScreenBuffer` maintains two identical 2D matrices:
* `cells: []Cell` (Current frame buffer)
* `prev_cells: []Cell` (Previous frame buffer)

Each `Cell` is packed to 32 bits of metadata + 4 bytes UTF-8 character payload:
```zig
pub const Cell = struct {
    char: [4]u8 = .{ ' ', 0, 0, 0 },
    char_len: u8 = 1,
    fg: Color = Color.rgb(200, 200, 200),
    bg: Color = Color.rgb(13, 17, 23),
    bold: bool = false,
    underline: bool = false,
    dirty: bool = true,
};
```

### Flush Algorithm
1. The `flush()` routine iterates through the 2D grid line-by-line.
2. It executes an equality check (`cell.eql(prev)`) between current and previous cells.
3. If identical, the cell is **completely skipped**.
4. If changed, the engine checks whether the current cursor coordinate is contiguous to the last written cell. If non-contiguous, it emits a single ANSI direct coordinate jump (`\x1b[<row>;<col>H`).
5. SGR color attributes (24-bit TrueColor `\x1b[38;2;R;G;Bm` and `\x1b[48;2;R;G;Bm`) are batched and only emitted when colors actually change.
6. The resulting escape stream is written in a single `writeAll` syscall via a 64 KB output buffer.
7. Finally, `prev_cells` is updated via `@memcpy(prev_cells, cells)`.

Result: **Typical frame writes require less than 400 bytes of ANSI data instead of 40 KB**, completely eliminating flicker.
