# Getting Started with Zyphor

This guide walks you through acquiring, installing, building, and verifying Zyphor on Linux, Windows, and macOS systems.

---

## 📥 Installation Methods

### 1. Pre-compiled Static Binaries (Recommended)
Pre-built static binaries with zero external runtime dependencies are available from the official [GitHub Releases](https://github.com/miyaniakshar1234/Zyphor/releases) page.

#### Linux (x86_64 / AArch64)
```bash
# Download latest static release
curl -LO https://github.com/miyaniakshar1234/Zyphor/releases/latest/download/zyphor-linux-x86_64.tar.gz

# Extract archive
tar -xzf zyphor-linux-x86_64.tar.gz

# Install binary to system PATH
sudo install -m 755 zyphor /usr/local/bin/zyphor

# Verify installation
zyphor doctor
```

#### Windows (x86_64 / AArch64)
```powershell
# Using PowerShell to download latest binary
Invoke-WebRequest -Uri "https://github.com/miyaniakshar1234/Zyphor/releases/latest/download/zyphor-windows-x86_64.zip" -OutFile "zyphor.zip"

# Expand archive
Expand-Archive -Path "zyphor.zip" -DestinationPath "$env:LOCALAPPDATA\Programs\Zyphor"

# Add to User PATH
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
[Environment]::SetEnvironmentVariable("Path", "$userPath;$env:LOCALAPPDATA\Programs\Zyphor", "User")

# Verify
zyphor doctor
```

#### macOS (Apple Silicon & Intel)
```bash
# Download universal or architecture-specific binary
curl -LO https://github.com/miyaniakshar1234/Zyphor/releases/latest/download/zyphor-macos-aarch64.tar.gz
tar -xzf zyphor-macos-aarch64.tar.gz
sudo install -m 755 zyphor /usr/local/bin/zyphor
zyphor doctor
```

---

## 🛠️ Compiling from Source

Zyphor is built with **Zig 0.15.x+**. The build system is entirely self-contained with no external C library dependencies.

### Prerequisites
* **Zig Compiler:** [Zig 0.15.2 or later](https://ziglang.org/download/)
* **Git:** For repository cloning

### Build Commands
```bash
# 1. Clone the repository
git clone https://github.com/miyaniakshar1234/Zyphor.git
cd Zyphor

# 2. Build in Debug mode (with full runtime assertions and safety checks)
zig build

# 3. Build in optimized Release mode (ReleaseFast for maximum throughput)
zig build -Doptimize=ReleaseFast

# 4. Run automated test suite
zig build test

# 5. The resulting executable is placed in:
./zig-out/bin/zyphor
```

### Cross-Compilation
Zig natively supports cross-compilation out of the box. You can cross-compile Zyphor from any operating system for any supported target:

```bash
# Cross-compile for Linux x86_64 (musl static) from Windows or macOS
zig build -Dtarget=x86_64-linux-musl -Doptimize=ReleaseFast

# Cross-compile for Windows x86_64 from Linux
zig build -Dtarget=x86_64-windows -Doptimize=ReleaseFast

# Cross-compile for macOS Apple Silicon from Linux or Windows
zig build -Dtarget=aarch64-macos -Doptimize=ReleaseFast
```

---

## 🩺 Verifying System Compatibility: `zyphor doctor`

Before launching the full interactive observatory, run `zyphor doctor` to perform an exhaustive environment and kernel sensor audit:

```bash
zyphor doctor
```

### Expected Output Example
```text
==================================================================
  ZYPHOR SYSTEM COMPATIBILITY & DIAGNOSTICS AUDIT (zyphor doctor)
==================================================================

  OS Platform:             windows (x86_64)
  Compiler & Target:       Zig 0.15.x
  Privilege Level:         Standard User

  Subsystem Readiness:
    ✓ CPU Telemetry:       Available (28 logical cores, 3200 MHz)
    ✓ Memory Telemetry:    Available (31 GB RAM detected)
    ✓ Disk Telemetry:      Available (2 partitions detected)
    ✓ Network Telemetry:   Available (2 interfaces active)
    ✓ Process Explorer:    Available (Direct OS native snapshot)
    ✓ GPU Telemetry:       Direct3D 12 / Dedicated GPU
    ✓ Battery / Power:     Battery detected
    ✓ ANSI Virtual Term:   Fully Supported

  System Health Score:     92/100 [EXCELLENT]
  Overall Readiness:       100% - Ready for full observatory mode!
==================================================================
```

---

## 🎯 First Launch

To start the interactive system observatory, simply execute:
```bash
zyphor
```

### Common Flags for First-Time Users:
* `zyphor --plain`: Launches in monochrome ASCII mode without ANSI color escapes (ideal for serial consoles, remote SSH over low-bandwidth connections, or vintage terminal emulators).
* `zyphor --refresh 250`: Overrides default sampling rate to 250 milliseconds.
* `zyphor --help`: Displays all command-line flags and subcommands.

Next Step: Read the [User Manual](user-manual.md) to master keyboard navigation, process tree analysis, and diagnostic views.
