# Zyphor System Architecture

## Architectural Overview
Zyphor is architected as a high-performance, native terminal observatory built in Zig 0.15.2. It delivers zero-overhead hardware monitoring and process diagnostics without external runtime dependencies or virtual machines.

```
┌─────────────────────────────────────────────────────────────┐
│                    Zyphor Terminal UI                       │
│  - ScreenBuffer: Double-buffered diff cell rendering        │
│  - Widgets: 6 consolidated powerhouse tabs (btop++ style)   │
│  - Theme: 24-bit TrueColor with ANSI fallback               │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│                    Core Telemetry Engine                    │
│  - SystemEngine: Frame scheduler and double-arena memory    │
│  - SystemHistory: Lock-free ring buffer time series         │
│  - HealthEngine: Heuristic multi-subsystem scoring          │
│  - ProcessManager: Toolhelp32 process snapshotting & DFS    │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│                 Native Platform Layer (Win32)               │
│  - NtQuerySystemInformation: Per-core CPU utilization       │
│  - Registry: ProcessorNameString and ~MHz base clock        │
│  - GetIfTable: Interface octet network throughput           │
│  - GetExtendedTcpTable: Live socket tracking with PID       │
│  - EnumServicesStatusExW: Service Control Manager daemons   │
│  - EnumDisplayDevicesW: Discrete GPU hardware discovery     │
└─────────────────────────────────────────────────────────────┘
```

## Core Subsystems
1. **Platform Layer (`src/platform/`)**:
   Provides uniform VTable interface (`PlatformCollector`) across target OS environments. On Windows, calls flat C APIs from `kernel32.dll`, `ntdll.dll`, `iphlpapi.dll`, `advapi32.dll`, and `user32.dll`.
2. **Core Engine (`src/core/`)**:
   Coordinates metric collection, snapshot historical ring buffering, and autonomous subsystem health auditing.
3. **UI Engine (`src/ui/`)**:
   Implements an in-memory `ScreenBuffer` matrix with differential flush, minimizing ANSI escape writes to the terminal emulator.
