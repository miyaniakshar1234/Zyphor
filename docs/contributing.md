# Contributing to Zyphor

Thank you for your interest in contributing to Zyphor! We welcome bug reports, feature suggestions, documentation enhancements, and code contributions.

---

## 🛠️ Development Setup

### 1. Prerequisites
* **Zig Compiler**: **0.15.x** ([Download](https://ziglang.org/download/))
* **Git**

### 2. Fork and Clone
```bash
git clone https://github.com/your-username/zyphor.git
cd zyphor
```

### 3. Build & Test Commands
```bash
# Build in debug mode
zig build

# Build in optimized release mode
zig build -Doptimize=ReleaseFast

# Run all unit tests
zig build test --summary all

# Run the compiled binary
./zig-out/bin/zyphor
```

---

## 📐 Coding Conventions & Guidelines

* **Pure Zig Standard Library First:** Strive to avoid external C dependencies unless interfacing directly with OS headers.
* **Zero-Allocation Sampling:** Metric sampling loops must use arena allocators with `.retain_capacity` or pre-allocated buffers. Never call heap allocators on hot loops without reusing buffers.
* **Error Handling:** Use Zig's explicit error handling (`try`, `catch`, error unions). Never call `unreachable` or panic on recoverable platform metrics (e.g., if a sensor is missing or permission is denied).
* **Formatting:** Format all Zig code using `zig fmt`.

---

## 🚀 Pull Request Checklist

Before submitting a Pull Request:
1. Ensure the code compiles cleanly on Zig 0.15+: `zig build`
2. Ensure all unit tests pass: `zig build test`
3. Format all code: `zig fmt src/`
4. Update `CHANGELOG.md` with your changes under `[Unreleased]`.
