# Zyphor CLI Reference Manual

Zyphor features a comprehensive command-line interface designed for terminal power users, cron jobs, system maintenance scripts, and CI/CD observability pipelines.

---

## 📖 Global Command Syntax

```bash
zyphor [OPTIONS] [SUBCOMMAND]
```

### Global Options

| Flag | Long Option | Description |
| :--- | :--- | :--- |
| `-j` | `--json` | Format output as structured, machine-readable JSON. |
| `-p` | `--plain` | Run in monochrome ASCII mode (disables ANSI TrueColor escape sequences). |
| `-r <ms>`| `--refresh <ms>`| Sampling loop interval in milliseconds (default: `250`). |
| `-h` | `--help` | Display command usage and exit. |
| `-v` | `--version` | Display version, commit hash, compiler target, and exit. |

---

## 🛠️ Subcommand Reference

### 1. `zyphor doctor`
Performs an exhaustive audit of operating system telemetry hooks, kernel sensor access, privilege levels, and system health readiness.

```bash
zyphor doctor [--json]
```

#### Exit Codes:
* `0`: All subsystems ready; system health is good/excellent.
* `1`: Subsystem probe failure or critical health warning detected.

---

### 2. `zyphor cpu`
Displays instantaneous processor load, user/system/idle breakdown, active clock frequency, and per-core topologies.

```bash
zyphor cpu [--json]
```

#### Human-Readable Output:
```text
CPU Telemetry:
  Model:           Intel / AMD x86_64 Processor
  Total Load:      24.2%
  User Time:       18.1%
  System Time:     6.1%
  Idle Time:       75.8%
  Clock Frequency: 3200 MHz
  Logical Cores:   28
  Physical Cores:  14
```

#### JSON Output (`zyphor cpu --json`):
```json
{
  "total_usage_pct": 24.20,
  "user_pct": 18.10,
  "system_pct": 6.10,
  "idle_pct": 75.80,
  "frequency_mhz": 3200,
  "logical_cores": 28,
  "physical_cores": 14
}
```

---

### 3. `zyphor memory`
Displays physical RAM residency, kernel page caches, swap space utilization, and memory pressure levels.

```bash
zyphor memory [--json]
```

#### Human-Readable Output:
```text
Memory & Swap Telemetry:
  Physical RAM:    32472 MB total (31.71 GB)
  Used RAM:        15961 MB (49.2%)
  Available RAM:   16510 MB (50.8%)
  Swap Space:      23988 MB used / 57048 MB total (42.0%)
  Memory Pressure: LOW (Healthy)
```

---

### 4. `zyphor process` (Alias: `zyphor ps`)
Queries active operating system processes with configurable sort keys and limits.

```bash
zyphor process [--sort <cpu|mem|pid|name>] [--limit <n>] [--json]
```

#### Options:
* `--sort <field>`: Sort column (`cpu`, `mem`, `pid`, `name`). Default: `cpu`.
* `--limit <n>`: Maximum number of rows to print. Default: `15`.

#### Example:
```bash
zyphor process --sort mem --limit 5
```

```text
  PID     PPID    NAME                   CPU%      RAM (MB)   THREADS  STATE
--------------------------------------------------------------------------------
  13628   14004   explorer.exe            22.5%         379       189  Running
  31012   17476   msedge.exe              22.5%          15        42  Running
  25044   1868    dllhost.exe             22.5%          12         4  Running
  31500   33392   cmd.exe                 23.5%          11         2  Running
  3316    1948    svchost.exe             23.5%           0         4  Running
```

---

### 5. `zyphor disk`
Lists mounted filesystems, total/used capacities, and live I/O transfer rates.

```bash
zyphor disk [--json]
```

#### Example Output:
```text
Storage Partitions:
  Mount: C:\          FS: NTFS     Used:  408.4 /  581.3 GB (70.3%)
  Mount: D:\          FS: NTFS     Used:   65.5 /  224.6 GB (29.2%)
```

---

### 6. `zyphor network` (Alias: `zyphor net`)
Lists active network interfaces, IP addresses, and throughput.

```bash
zyphor network [--json]
```

#### Example Output:
```text
Network Interfaces:
  Wi-Fi (Primary Adapter)   192.168.1.105     RX: 4.01 MB/s  TX: 0.81 MB/s
  Loopback (localhost)      127.0.0.1         RX: 0.01 MB/s  TX: 0.01 MB/s
```

---

### 7. `zyphor snapshot`
Captures an atomic, comprehensive system snapshot across all subsystems and outputs structured JSON to stdout or a designated file.

```bash
zyphor snapshot [-o <file.json>]
```

#### Example Automation Script:
```bash
# Capture hourly snapshot for server telemetry archiving
zyphor snapshot -o "/var/log/telemetry/snapshot-$(date +%Y%m%d-%H%M%S).json"
```

---

## 🤖 Pipeline Integration Examples

### Alert on High Memory Pressure via `jq`:
```bash
PRESSURE=$(zyphor memory --json | jq -r .pressure_level)
if [ "$PRESSURE" = "CRITICAL (Thrashing)" ]; then
    echo "ALERT: System is thrashing swap space!" | mail -s "Memory Alert" ops@example.com
fi
```

### Check Overall Health in CI/CD Pre-flight:
```bash
zyphor doctor || { echo "Environment check failed"; exit 1; }
```
