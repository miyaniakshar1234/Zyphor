# 🤖 Zyphor CLI & Automation Reference Manual

*Author: Akshar Miyani • Version: 1.0.0 • Automation & Toolchain Guide*

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
| `-r <ms>`| `--refresh <ms>`| Sampling loop interval in milliseconds (default: `1000` baseline, `33` active). |
| `-t <name>`| `--theme <name>`| Start TUI with a specific TrueColor theme (`anthropic`, `cyber`, `tokyo_night`, `hacker`, `nord`, etc.). |
| `-h` | `--help` | Display command usage and exit. |
| `-v` | `--version` | Display version, commit hash, compiler target, and exit. |

---

## 🛠️ Complete Subcommand Reference

### 1. `zyphor doctor`
Performs an exhaustive audit of operating system telemetry hooks, kernel sensor access, privilege levels, and system health readiness.

```bash
zyphor doctor [--json]
```

#### Exit Codes:
* `0`: All subsystems ready; system health is nominal.
* `1`: Subsystem probe failure or critical health warning detected.

---

### 2. `zyphor bench`
Executes native CPU compute (Single-Core Integer MOP/s, Multi-Threaded GFLOPS) and Memory Bandwidth (GB/s) benchmarks without external dependencies.

```bash
zyphor bench [--json]
```

#### Sample Output:
```text
┌─────────────────────────────────────────────────────────────┐
│  ZYPHOR NATIVE HARDWARE BENCHMARK ENGINE                    │
├─────────────────────────────────────────────────────────────┤
│  Single-Core Compute:    8,420 MOP/s                        │
│  Multi-Threaded Compute: 48,150 MOP/s (16 Cores Active)     │
│  Sequential Memory Read: 38.4 GB/s                          │
│  Sequential Memory Write:29.1 GB/s                          │
│  L1/L2 Cache Latency:    1.2 ns                             │
└─────────────────────────────────────────────────────────────┘
```

---

### 3. `zyphor overhead`
Measures Zyphor's internal telemetry polling latency and self-memory footprint by running 50 consecutive iterations of the engine in memory.

```bash
zyphor overhead [--json]
```

#### Sample Output:
```text
Zyphor Internal Telemetry Overhead Benchmark:
  Samples:               50 iterations
  Average Sampling Time: 1.24 ms
  Min / Max Time:        0.89 ms / 2.10 ms
  Process Footprint:     2.1 MB Resident RAM (RSS)
  Heap Mallocs in Loop:  0 (Zero-Allocation Dual Arena)
```

---

### 4. `zyphor daemon` (Alias: `zyphor server`)
Launches Zyphor in headless mode, binding a lightweight TCP HTTP listener on port `7777` to stream live JSON telemetry snapshots for remote monitoring.

```bash
zyphor daemon [--port <port>]
```

#### Remote Endpoints:
* `GET /api/snapshot`: Returns full instantaneous `SystemSnapshot` JSON payload.
* `GET /api/health`: Returns 0–100 health scores and heuristic AI diagnostic insight cards.

---

### 5. `zyphor snapshot`
Captures an atomic, comprehensive system snapshot across all subsystems (CPU, RAM, Disks, Network, Services, Containers, AI Diagnostics) and outputs structured JSON.

```bash
zyphor snapshot [-o <file.json>]
```

---

### 6. `zyphor process` (Alias: `zyphor ps`)
Queries active operating system processes from the CLI without launching the full TUI.

```bash
zyphor process [--sort <cpu|mem|pid|name>] [--limit <n>] [--json]
```

---

### 7. `zyphor disk`
Lists mounted storage partitions, filesystems, free capacity, and I/O transfer rates.

```bash
zyphor disk [--json]
```

---

### 8. `zyphor network` (Alias: `zyphor net`)
Displays network interface adapters, IP bindings, and live bandwidth throughput.

```bash
zyphor network [--json]
```

---

### 9. `zyphor health`
Runs the Heuristic AI engine to output current 0–100 subsystem health scores and active incident remediation playbooks.

```bash
zyphor health [--json]
```

---

### 10. `zyphor services`
Lists operating system background daemons, startup configurations, and execution states.

```bash
zyphor services [--json]
```

---

## 🤖 Pipeline Integration & Automation Recipes

### Automated Alerting Script (`cron` / Bash):
```bash
#!/usr/bin/env bash
HEALTH=$(zyphor health --json | jq -r .overall_health_score)

if [ "$HEALTH" -lt 70 ]; then
    zyphor snapshot -o "/var/log/incident-$(date +%s).json"
    echo "WARNING: System health degraded to $HEALTH" | mail -s "Node Health Alert" ops@example.com
fi
```

### Prometheus Exporter Ingestion:
Point your Prometheus scrape config or custom sidecar agent to the Zyphor daemon endpoint:
```yaml
scrape_configs:
  - job_name: 'zyphor'
    metrics_path: '/api/snapshot'
    static_configs:
      - targets: ['localhost:7777']
```

---

*Authored with precision by Akshar Miyani.*
