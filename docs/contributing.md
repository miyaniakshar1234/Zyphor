# Contributing to Zyphor

Thank you for your interest in contributing to Zyphor! We welcome improvements, bug reports, and optimizations.

## Toolchain Requirements
- **Zig 0.15.2** or compatible release.
- **Git** for version control.
- Windows Terminal, Alacritty, or any TrueColor ANSI capable terminal emulator.

## Building and Testing
```bash
# Run test suite
zig build test --summary all

# Build debug binary
zig build

# Build optimized ReleaseFast binary
zig build -Doptimize=ReleaseFast
```

## Coding Conventions
1. **Zero-Allocation Hot Paths**: UI rendering loops and ring buffer operations must not allocate on the heap.
2. **Strict Win32 Honesty**: Never fabricate mock or simulated telemetry data. If a hardware metric requires elevated kernel drivers (e.g. MSR thermals), display `N/A` or inform the user cleanly.
3. **Explicit Error Handling**: Do not catch errors with empty blocks unless deliberately handling expected non-fatal conditions.
4. **Format & Quality**: Ensure `zig build test` passes with zero failures before submitting PRs.
