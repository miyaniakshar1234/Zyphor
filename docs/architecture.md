# Zyphor Internal Architecture

This document breaks down the low-level systems design that allows Zyphor to process thousands of OS metrics at 30 FPS while maintaining a memory footprint of less than 2 MB.

## 1. Zero-Allocation Philosophy

In high-frequency monitoring tools, allocating memory on the heap per-frame is the primary cause of latency spikes (due to garbage collection or allocator lock contention). Zyphor completely avoids standard heap allocations in its hot path.

Instead, we use a **Double Arena Allocator** strategy:
1. `FrameArenaA` and `FrameArenaB`.
2. On Frame 1, all dynamic data (like the list of 500+ processes) is allocated inside `FrameArenaA`.
3. On Frame 2, Zyphor reads from `FrameArenaA` to compute the diffs, while allocating the new incoming state into `FrameArenaB`.
4. At the end of Frame 2, `FrameArenaA` is wiped clean instantly via a pointer reset (`arena.reset()`). No `free()` loop is necessary. Memory fragmentation is mathematically impossible.

## 2. Double-Buffered Differential Rendering

Terminal emulators are slow. If you send a full screen of text over standard output 30 times a second, the terminal will tear, flicker, and consume massive amounts of CPU just to parse the ANSI codes.

To bypass this, Zyphor implements a software compositor:
1. The screen is modeled as an array of `Cell` structs. Each `Cell` contains the ASCII character, the foreground color (24-bit RGB), and the background color.
2. Zyphor maintains two arrays: `prev_frame` and `current_frame`.
3. The UI components (like the CPU graph or the process table) write directly to memory in `current_frame`.
4. A highly optimized linear sweep compares `current_frame[i]` with `prev_frame[i]`.
5. We then construct a highly compressed stream of ANSI escape sequences containing *only* the specific cells that mutated.

This means if a single number in the CPU usage changes, Zyphor only transmits the 4 bytes required to update that specific number on the screen. The terminal overhead drops to near zero.

## 3. Direct Kernel Telemetry

Zyphor does not use heavy abstraction layers like WMI (Windows Management Instrumentation) or Python's `psutil`.

*   **Windows:** We bypass the Win32 API entirely for process telemetry, linking directly against `ntdll.dll` to call `NtQuerySystemInformation` with the `SystemProcessInformation` class. This allows us to snapshot all threads in ring-0 with a single system call.
*   **Linux:** We parse `/proc` directly. To avoid file I/O overhead, we use pre-allocated stack buffers and raw string parsing to read `stat`, `status`, and `net/dev` files without regular expressions.

## 4. The Heuristic Engine (AI)

Instead of relying on a bloated LLM, Zyphor's "AI" is a deterministic Heuristic Rules Engine (`src/core/ai.zig`). It applies strict mathematical bounds to the telemetry:
*   **VMM Swap Analysis:** It checks `(swap_used / swap_total) > threshold` concurrently with `memory_rss` to definitively prove memory starvation.
*   **Thermal Velocity:** It monitors CPU frequency vs CPU load to detect physical throttling constraints.
*   It operates in `O(1)` time complexity during the event loop.

---

*Architected by Akshar Miyani.*
