# Zyphor Internal Systems Architecture

Zyphor's speed comes from its strict adherence to Data-Oriented Design (DOD) principles.

## The Rendering Engine
Modern terminal emulators are notoriously slow when bombarded with escape sequences. Zyphor solves this with a **Double-Buffered Differential Engine**:
1. Two contiguous arrays of Cell structs represent the screen state (prev_cells and current_cells).
2. Every frame, Zyphor clears current_cells and paints the entire UI into memory.
3. A fast linear sweep compares current_cells[i] against prev_cells[i].
4. Only cells with dirty == true trigger ANSI sequence emission. 

This guarantees O(changes) rendering time rather than O(screen_size).

## Zero-Allocation Philosophy
The entire event loop executes without a single call to malloc or the general purpose allocator.
- System metrics are scraped into fixed-size stack buffers.
- String formatting is handled via std.fmt.bufPrint.
- Process lists are allocated using two ArenaAllocators that swap and reset every frame, completely eliminating memory fragmentation and leak potential.
