# Getting Started with Zyphor

This guide walks you through installing, building, and running Zyphor on Linux, Windows, and macOS.

---

## 📥 Installation

### 1. Precompiled Binary Releases
Precompiled standalone binaries are published with every GitHub release:

* **Linux (x86_64, ARM64):** `zyphor-linux-x86_64.tar.gz`
* **Windows (x86_64):** `zyphor-windows-x86_64.zip`
* **macOS (Universal / Apple Silicon / Intel):** `zyphor-macos-universal.tar.gz`

Download and extract the archive, then move `zyphor` (or `zyphor.exe`) to your system `$PATH` (e.g. `/usr/local/bin` or `C:\Program Files\Zyphor`).

---

### 2. Native Package Managers

#### Windows
```powershell
# Using Winget
winget install Zyphor.Zyphor

# Using Scoop
scoop bucket add zyphor https://github.com/zyphor-project/scoop-bucket
scoop install zyphor
```

#### macOS (Homebrew)
```bash
brew install zyphor-project/tap/zyphor
```

#### Linux (Arch AUR, Ubuntu, Fedora)
```bash
# Arch Linux (AUR)
yay -S zyphor

# Debian / Ubuntu (.deb)
sudo dpkg -i zyphor_amd64.deb

# Fedora / RHEL (.rpm)
sudo dnf install zyphor.rpm
```

---

## 🛠️ Building from Source

### Prerequisites
* **Zig Compiler**: Version **0.15.x** or higher ([Download Zig](https://ziglang.org/download/)).
* **Git**: To clone the repository.

### Compilation Steps
```bash
# 1. Clone the repository
git clone https://github.com/zyphor-project/zyphor.git
cd zyphor

# 2. Build the optimized release binary
zig build -Doptimize=ReleaseFast

# 3. The compiled binary is available in zig-out/bin/
./zig-out/bin/zyphor --version
```

### Running Test Suite
```bash
zig build test
```

---

## 🚀 First Run

### 1. Verify System Environment
Before launching the full TUI, run `zyphor doctor` to check OS metrics and terminal support:
```bash
zyphor doctor
```

Output will look like:
```text
Zyphor System Diagnostics & Health Check
=========================================
OS Platform:         Windows (x86_64)
Kernel / Build:      10.0.26100
Privilege Level:     Standard User
CPU Telemetry:       ✓ Available (16 logical cores)
Memory Telemetry:    ✓ Available (32.0 GB RAM)
Storage Telemetry:   ✓ Available (2 partitions detected)
Network Telemetry:   ✓ Available (Wi-Fi, Ethernet)
Process Telemetry:   ✓ Available (NtQuerySystemInformation)
Terminal VT100 / ANSI: ✓ Supported
Overall Readiness:   100% - Ready for full observatory mode
```

### 2. Launch the Interactive Dashboard
```bash
zyphor
```

### 3. Basic Navigation Controls
* Press <kbd>Tab</kbd> to cycle between tabs: **Overview**, **Processes**, **Disks**, **Network**, **Diagnostics**.
* Press <kbd>↑</kbd> and <kbd>↓</kbd> (or <kbd>j</kbd>/<kbd>k</kbd>) to navigate processes.
* Press <kbd>t</kbd> to switch to the hierarchical **Process Tree** view.
* Press <kbd>/</kbd> to filter processes by name or PID.
* Press <kbd>?</kbd> to view the in-app help modal.
* Press <kbd>q</kbd> to quit.
