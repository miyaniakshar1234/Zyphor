# Zyphor CLI Reference Manual

Zyphor includes a comprehensive command-line interface suitable for direct terminal queries, automated monitoring scripts, and CI/CD pipelines.

---

## 📌 Global Syntax

```bash
zyphor [OPTIONS] [SUBCOMMAND] [SUBCOMMAND_OPTIONS]
```

### Global Flags
| Flag | Short | Description |
| :--- | :--- | :--- |
| `--help` | `-h` | Display global help or subcommand help |
| `--version` | `-v` | Display version information and compiler build mode |
| `--json` | `-j` | Output results in clean, machine-readable JSON format |
| `--plain` | `-p` | Disable ANSI color escapes and Unicode symbols (ASCII only) |
| `--refresh <ms>` | `-r` | Set real-time sampling and refresh interval in milliseconds (default: `1000`) |
| `--config <path>` | `-c` | Path to custom configuration file |

---

## 🛠️ Subcommands

### 1. `zyphor` (Interactive TUI Mode)
Launches the full interactive terminal user interface.
```bash
zyphor
zyphor --refresh 500
zyphor --plain
```

---

### 2. `zyphor doctor` (System Diagnostics)
Audits the host environment, kernel telemetry availability, hardware sensor access, user privilege level, and terminal capabilities.

```bash
zyphor doctor
zyphor doctor --json
```

**JSON Output Structure:**
```json
{
  "os": "Windows",
  "arch": "x86_64",
  "kernel": "10.0.26100",
  "is_elevated": false,
  "telemetry": {
    "cpu": true,
    "memory": true,
    "disk": true,
    "network": true,
    "processes": true,
    "gpu": true,
    "sensors": true
  },
  "compatibility_score": 100
}
```

---

### 3. `zyphor cpu` (Instant CPU Telemetry)
Displays aggregate and per-core CPU usage, clock speeds, and interrupt statistics.

```bash
zyphor cpu
zyphor cpu --cores
zyphor cpu --json
```

**Output Example:**
```text
CPU Telemetry:
  Model:             AMD Ryzen 9 7950X 16-Core Processor
  Overall Usage:     14.2%
  User:              9.8%
  System:            4.4%
  Clock Frequency:   4,500 MHz
  Logical Cores:     32
  Core Utilization:
    Core #0: [████░░░░░░░░░░░░░░░░] 22.1%
    Core #1: [██░░░░░░░░░░░░░░░░░░] 11.4%
    ...
```

---

### 4. `zyphor memory` (Memory & Swap Breakdown)
Outputs physical memory utilization, cache buffers, swap metrics, and memory pressure state.

```bash
zyphor memory
zyphor memory --json
```

**Output Example:**
```text
Memory & Swap Telemetry:
  Physical RAM:      32,768 MB (32.00 GB)
  Used RAM:          18,420 MB (56.2%)
  Available RAM:     14,348 MB (43.8%)
  Cached / Buffers:   6,120 MB
  Swap / Pagefile:   16,384 MB Total | 512 MB Used (3.1%)
  Memory Pressure:   LOW (Healthy)
```

---

### 5. `zyphor process` (Process Table Query)
Queries the live process table without starting the TUI. Supports sorting, filtering, and row limits.

```bash
# Top 10 processes by CPU
zyphor process --sort cpu --limit 10

# Top 5 processes by Memory
zyphor process --sort mem --limit 5

# Filter processes containing "zig"
zyphor process --filter zig

# Complete process table in JSON format
zyphor process --json
```

**Options:**
* `--sort <cpu|mem|pid|name>`: Column to sort by (default: `cpu`).
* `--limit <n>`: Number of processes to display (default: `20`).
* `--filter <query>`: Case-insensitive substring match against executable name.
* `--tree`: Render as hierarchical text tree.

---

### 6. `zyphor disk` (Storage Telemetry)
Lists mounted partitions, filesystem types, capacity, and current I/O rates.

```bash
zyphor disk
zyphor disk --json
```

---

### 7. `zyphor network` (Network Interfaces & Sockets)
Lists active interfaces, IP configurations, and instantaneous throughput.

```bash
zyphor network
zyphor network --connections
zyphor network --json
```

---

### 8. `zyphor snapshot` (Point-in-time Export)
Captures an instantaneous, comprehensive system snapshot (including CPU, Memory, Disk, Network, Top Processes, and System Health) and writes it to a timestamped JSON file.

```bash
zyphor snapshot
zyphor snapshot --output my-machine-snapshot.json
```

---

### 9. `zyphor export` (Continuous Metrics Export)
Streams live metrics in JSON or CSV format at regular intervals for ingestion into Prometheus, Grafana, or local log aggregators.

```bash
zyphor export --format json --interval 1000
zyphor export --format csv --interval 500
```
