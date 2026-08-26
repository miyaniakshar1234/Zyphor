# Alerts & Diagnostics Engine

Unlike traditional monitors that show only raw percentages, Zyphor incorporates an **explainable root-cause diagnostic engine** and an objective **System Health Score**.

---

## 🩺 System Health Score Algorithm

Zyphor evaluates system health continuously on a scale from **0 to 100**.

```
                           System Health Score (0 - 100)
                                        │
           ┌──────────────┬─────────────┼──────────────┬──────────────┐
           ▼              ▼             ▼              ▼              ▼
       CPU Score     Memory Score   Disk Score    Thermal Score   Network Score
       (Weight: 25%)  (Weight: 30%)  (Weight: 20%)  (Weight: 15%)  (Weight: 10%)
```

### Health Categories
* **90 – 100 (EXCELLENT):** All subsystems nominal, low latency, zero thrashing.
* **75 – 89 (GOOD):** Normal operating load, mild resource utilization.
* **50 – 74 (FAIR):** Moderate contention; potential elevated thermals or disk I/O wait.
* **25 – 49 (POOR):** Severe bottleneck detected (e.g. swap thrashing, sustained >95% CPU).
* **0 – 24 (CRITICAL):** System stability at immediate risk (runaway memory leak, critical thermal throttling).

---

## 🔍 Deterministic Root-Cause Diagnostics

Zyphor avoids opaque heuristic black-boxes. All diagnostics are rule-based, deterministic, and explainable:

### Diagnostic Rule 1: Swap Thrashing Detection
* **Trigger Condition:** `memory.used_pct > 90%` AND `swap.activity_rate > 10 MB/s` for `> 15s`.
* **Diagnosis:** *"System is actively swapping memory pages to disk, causing high latency and micro-stutters."*
* **Root Cause Identified:** Identifies the top 3 processes with the largest `(RSS + Swap)` allocation.
* **Recommended Action:** Suspend or terminate memory-heavy processes.

### Diagnostic Rule 2: I/O Saturation & Storage Bottleneck
* **Trigger Condition:** `disk.queue_depth > 4` AND `cpu.iowait_pct > 25%`.
* **Diagnosis:** *"Storage I/O queue is saturated. CPU cores are idling in I/O wait state."*
* **Root Cause Identified:** Pinpoints the specific PID generating the highest write throughput.

### Diagnostic Rule 3: Runaway Single-Thread CPU Loop
* **Trigger Condition:** Single logical core at `100%` while aggregate CPU is `< 25%`, with 1 process consuming exactly `100% / N_cores`.
* **Diagnosis:** *"Process appears stuck in an unyielding single-threaded computation or infinite loop."*

### Diagnostic Rule 4: Thermal Throttling
* **Trigger Condition:** `cpu.temperature_c > 90°C` AND `cpu.frequency_mhz < cpu.base_frequency_mhz * 0.7`.
* **Diagnosis:** *"CPU is aggressively downclocking to prevent thermal damage."*
