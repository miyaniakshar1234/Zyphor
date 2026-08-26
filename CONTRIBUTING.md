# Contributing to Zyphor

First off, thank you for considering contributing to Zyphor! It's people like you that make Zyphor such a great tool for the systems engineering community.

## 🧠 Philosophy
Zyphor is built on three core pillars:
1. **Zero Allocations in the Hot Path:** Once the UI engine is running, we do not allocate memory dynamically. We use pre-allocated Arenas and Ring Buffers.
2. **Explainable Telemetry:** We don't just show spikes; we diagnose them (via the heuristics engine in `src/core/diagnostics.zig`).
3. **Data Density:** The terminal is a canvas. Use Braille mapping, custom glyphs, and spatial arrangement to maximize the data-to-pixel ratio.

## 🛠️ Development Setup

You will need:
- **Zig 0.15.x** (Strict version requirement)
- Git

### Build Instructions
```bash
# Clone the repository
git clone https://github.com/miyaniakshar1234/Zyphor.git
cd Zyphor

# Build a fast, optimized release
zig build -Doptimize=ReleaseFast

# Run tests
zig build test
```

## 🏗️ Architecture Overview

If you want to contribute, understanding the architecture is crucial. The codebase is heavily decoupled:

- **`src/core/`**: Platform-agnostic data structures. Ring buffers for history (`history.zig`), process structures (`types.zig`), and the heuristics engine (`diagnostics.zig`).
- **`src/platform/`**: OS-specific metric collectors. `windows.zig` uses `NtQuerySystemInfo`, `linux.zig` parses `/proc`, and `macos.zig` uses Mach ports.
- **`src/ui/`**: The entire presentation layer. `buffer.zig` is the differential rendering engine. `widgets.zig` draws the actual layouts. `graphs.zig` contains the Braille mapping math.

## 💡 How to Contribute

### 1. Find an Issue
Look for issues tagged with `good first issue` or `help wanted`. If you have a massive architectural change in mind, please open a Discussion first!

### 2. Branch and Commit
- Create a branch for your feature (`git checkout -b feat/my-cool-feature`).
- Follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) standard for your commit messages (e.g., `feat: add APFS disk detection`, `fix: handle negative PID wraparound`).

### 3. Coding Standards
- **No `std.heap.page_allocator` in loops!** Use the provided `ArenaAllocator` during startup, and rely on fixed-size buffers during the render loop.
- **Errors are handled.** Zig forces you to handle errors. Use `try` or `catch` properly. Do not swallow fatal OS errors without logging them.
- **Format your code.** Run `zig fmt` before committing.

### 4. Open a Pull Request
Submit your PR against the `master` branch. Include screenshots if you made visual changes!

## 📜 Code of Conduct
By participating in this project, you agree to maintain a welcoming, inclusive, and harassment-free environment for everyone. Let's build cool things together.
