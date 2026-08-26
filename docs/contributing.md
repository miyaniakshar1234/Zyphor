# Contributing to Zyphor

Thank you for your interest in contributing to **Zyphor**! We welcome bug reports, performance benchmarks, platform probes, documentation improvements, and code contributions.

Zyphor is a high-craft systems engineering project. We hold the codebase to high standards of memory safety, determinism, performance, and cross-platform reliability.

---

## 🧭 Code of Conduct

All contributors and maintainers are expected to adhere to our [Code of Conduct](../CODE_OF_CONDUCT.md). Please be respectful, constructive, and collaborative.

---

## 🛠️ Development Environment Setup

### Prerequisites
1. **Zig Compiler:** [Zig 0.15.2+](https://ziglang.org/download/)
2. **Git:** Version 2.40+

### Clone & Build
```bash
# Clone the repository
git clone https://github.com/miyaniakshar1234/Zyphor.git
cd Zyphor

# Build in debug mode
zig build

# Run full test suite
zig build test

# Run the compiled binary
./zig-out/bin/zyphor
```

---

## 📐 Core Engineering Invariants

When writing or modifying code in Zyphor, you must uphold the following architectural invariants:

### 1. Zero Runtime Allocations in Sampling Loops
* Never call `std.heap.page_allocator` or raw `malloc` inside the frame loop.
* All transient structures must use the frame's `scratch_arena`.
* If a data structure must survive across frames, store it explicitly in the `SystemEngine` state struct.

### 2. Strict Weak Ordering in Sort Comparators
* Any custom sort comparator used with `std.sort.block` or `std.sort.pdq` must satisfy strict weak ordering ($a < a$ is false).
* Always provide a deterministic tie-breaker (e.g., compare `PID` when primary metric values are equal) to prevent assertion panics.

### 3. Cross-Platform Parity
* When adding a new metric or probe, implement the polymorphic interface in `src/platform/interface.zig`.
* Provide implementations (or graceful fallbacks) across `windows.zig`, `linux.zig`, and `macos.zig`.

### 4. Terminal Code Page & UTF-8 Safety
* All terminal output must be UTF-8 encoded.
* Windows terminal initialization must explicitly set `CP_UTF8` (65001) on `enterRawMode` and restore original code pages on `exitRawMode`.

---

## 🧪 Testing Guidelines

Before submitting a Pull Request, verify that:
1. `zig build` compiles cleanly with zero warnings or errors.
2. `zig build test` passes all unit and integration tests.
3. `zig build -Doptimize=ReleaseFast` compiles cleanly.
4. `zyphor doctor` runs without runtime assertions or crashes.

---

## 🔀 Pull Request Workflow

1. Fork the repository on GitHub.
2. Create a feature branch: `git checkout -b feat/my-new-probe`.
3. Commit your changes following [Conventional Commits](https://www.conventionalcommits.org/):
   * `feat(platform): add Linux cgroups v2 memory pressure probe`
   * `fix(ui): resolve column padding in high core-count topologies`
   * `docs(manual): expand process tree navigation shortcuts`
4. Push to your fork: `git push origin feat/my-new-probe`.
5. Open a Pull Request against the `master` branch.
