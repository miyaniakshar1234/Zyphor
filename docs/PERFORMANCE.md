# Zyphor Performance Engineering

## High-Frequency Telemetry with Zero Runtime Overhead
Zyphor is designed for low CPU and memory footprints, ensuring that the act of observing the system does not alter its performance.

## Key Performance Design Pillars
1. **Double-Arena Memory Cycling**:
   Frame allocations use alternating `std.heap.ArenaAllocator` instances. Temporary strings and slices are freed en masse every frame, preventing heap fragmentation.
2. **Differential Screen Buffer**:
   The `ScreenBuffer` maintains dual frame matrices (current and previous). The `flush()` method compares cells and only emits ANSI escape codes for cells that changed, reducing terminal I/O by over 90%.
3. **Lock-Free Ring Buffers**:
   Rolling history graphs store fixed-capacity ring buffers without dynamic reallocation or thread contention.
4. **Fast Win32 Snapshotting**:
   Uses `CreateToolhelp32Snapshot` and `GetIfTable` with fixed buffers, querying full system state in under 5 milliseconds.
