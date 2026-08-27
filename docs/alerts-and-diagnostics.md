# 🚨 Zyphor Alerts & Heuristic Diagnostics Engine

*Author: Akshar Miyani • Version: 1.0.0 • Algorithmic Deep Dive*

---

## Table of Contents
1. [Overview & Philosophy](#1-overview--philosophy)
2. [Hardware Health Scoring Formulas (0–100)](#2-hardware-health-scoring-formulas-0100)
   - [Compute Subsystem Score](#compute-subsystem-score)
   - [Memory Fabric Score](#memory-fabric-score)
   - [Storage I/O Fabric Score](#storage-io-fabric-score)
   - [Network Link Score](#network-link-score)
   - [Thermal Score](#thermal-score)
   - [Global Aggregate Health Score](#global-aggregate-health-score)
3. [Deterministic Root-Cause Heuristic Rules](#3-deterministic-root-cause-heuristic-rules)
   - [Rule 1: CPU Congestion & Runaway Process](#rule-1-cpu-congestion--runaway-process)
   - [Rule 2: VMM Memory Saturation & Swap Thrashing](#rule-2-vmm-memory-saturation--swap-thrashing)
   - [Rule 3: Rapid Battery Depletion & Power Imbalance](#rule-3-rapid-battery-depletion--power-imbalance)
   - [Rule 4: Thermal Throttling Velocity](#rule-4-thermal-throttling-velocity)
4. [Hysteresis & Flap Prevention Algorithm](#4-hysteresis--flap-prevention-algorithm)
5. [Incident Alert Structure & JSON Export Schema](#5-incident-alert-structure--json-export-schema)
6. [Remediation Playbook Reference](#6-remediation-playbook-reference)

---

## 1. Overview & Philosophy

Most monitoring tools are passive: they display a wall of raw numbers and leave the interpretation entirely to the human operator. When a system becomes unresponsive, a human must manually correlate CPU spikes, memory paging rates, and disk I/O to deduce what happened.

**Zyphor's Heuristic AI Engine (`src/core/ai.zig` and `src/alerts/`) is active and deterministic.**

It ingests the instantaneous `SystemSnapshot`, cross-references multi-variable thresholds in $O(1)$ time, and automatically synthesizes:
1. **Health Scores (0–100):** Continuous numerical grades across all hardware domains.
2. **Explainable Diagnoses:** Plain-English statements describing the root issue.
3. **Mathematical Evidence:** The specific data points proving the diagnosis.
4. **Actionable Remediation Playbooks:** Exact steps to resolve the condition.

---

## 2. Hardware Health Scoring Formulas (0–100)

Every hardware subsystem is evaluated every frame. Scores are normalized to an integer between `0` (Critical Failure) and `100` (Optimal).

### Compute Subsystem Score
$$\text{Score}_{\text{CPU}} = \max\left(0, 100 - \left(\text{Usage}_{\text{total}}\right) - \text{Penalty}_{\text{skew}}\right)$$
* Where $\text{Penalty}_{\text{skew}}$ penalizes single-core saturation if one core is pinned at 100% while aggregate CPU is low.

### Memory Fabric Score
$$\text{Score}_{\text{RAM}} = \max\left(0, 100 - \left(0.7 \times \text{RAM}_{\text{used}}\%\right) - \left(1.5 \times \text{Swap}_{\text{used}}\%\right)\right)$$
* Swap usage carries a heavier weighting factor ($1.5\times$) because virtual memory paging directly induces disk I/O latency.

### Storage I/O Fabric Score
$$\text{Score}_{\text{Disk}} = \max\left(0, 100 - \left(0.8 \times \text{Partition}_{\text{max\_used}}\%\right) - \text{Penalty}_{\text{iowait}}\right)$$
* If any partition exceeds 90% capacity, score drops into the `CRITICAL` zone.

### Network Link Score
$$\text{Score}_{\text{Net}} = \max\left(0, 100 - \text{Penalty}_{\text{errors}} - \text{Penalty}_{\text{drops}}\right)$$

### Thermal Score
$$\text{Score}_{\text{Thermal}} = \begin{cases} 
100 & \text{if } T < 60^\circ\text{C} \\
100 - 2 \times (T - 60) & \text{if } 60^\circ\text{C} \le T \le 90^\circ\text{C} \\
0 & \text{if } T > 90^\circ\text{C} \text{ (Critical Throttling)}
\end{cases}$$

### Global Aggregate Health Score
$$\text{Score}_{\text{Global}} = 0.35 \times \text{Score}_{\text{CPU}} + 0.35 \times \text{Score}_{\text{RAM}} + 0.15 \times \text{Score}_{\text{Disk}} + 0.10 \times \text{Score}_{\text{Net}} + 0.05 \times \text{Score}_{\text{Thermal}}$$

---

## 3. Deterministic Root-Cause Heuristic Rules

### Rule 1: CPU Congestion & Runaway Process
* **Condition:** Aggregate CPU Usage $> 85.0\%$
* **Heuristic Analysis:** The engine searches `snapshot.top_processes` for the maximum CPU consumer.
* **Diagnosis:** *"High CPU Congestion Detected"*
* **Evidence:** *"The system is under heavy computational load (92.4%). 'zyphor-bench' is the primary contributor using 84.1% of CPU resources."*
* **Remediation Action:** *"Consider suspending (hotkey 's') or terminating (hotkey 'x') PID 4120 ('zyphor-bench') to restore responsiveness."*
* **Severity:** `CRITICAL`

---

### Rule 2: VMM Memory Saturation & Swap Thrashing
* **Condition:** Physical RAM Usage $> 85.0\%$
* **Heuristic Analysis:** Correlates Resident Set Size (`RSS`) of all processes against active Pagefile/Swap utilization.
* **Diagnosis:** *"Memory Saturation & Swap Risk"*
* **Evidence:** 
  * If $\text{Swap} > 20\%$: *"Memory pressure is causing active swap thrashing (Swap: 34%). 'postgres.exe' (PID 1840) is consuming 4.2 GB RSS."*
  * If $\text{Swap} \le 20\%$: *"System RAM is 88% saturated. 'node.exe' (PID 912) is the largest consumer at 2.1 GB RSS."*
* **Remediation Action:** *"Inspect process memory leaks or increase swap space."*
* **Severity:** `CRITICAL` if RAM $> 95\%$, otherwise `FAIR`

---

### Rule 3: Rapid Battery Depletion & Power Imbalance
* **Condition:** `battery.is_charging == false` AND `cpu.total_usage > 50.0%`
* **Diagnosis:** *"Rapid Battery Depletion Expected"*
* **Evidence:** *"High CPU compute load while discharging on DC battery power."*
* **Remediation Action:** *"Switch to a power-saving profile or suspend background telemetry agents."*
* **Severity:** `FAIR`

---

### Rule 4: Thermal Throttling Velocity
* **Condition:** Core frequency dropping below base clock while compute load is sustained above 80%.
* **Diagnosis:** *"Thermal Throttling Detected"*
* **Evidence:** *"CPU package temperature reached 94°C. Clock multiplier throttled by 35%."*
* **Remediation Action:** *"Inspect cooling fans, check airflow vents, or reduce concurrent thread pool limits."*
* **Severity:** `CRITICAL`

---

## 4. Hysteresis & Flap Prevention Algorithm

A common flaw in monitoring tools is **alert flapping** (an alert triggers and clears repeatedly when a metric oscillates around a threshold, e.g., fluctuating between 84.9% and 85.1%).

Zyphor implements a **Dual-Threshold Hysteresis Window**:

```
 Upper Trigger Threshold (85%):
 Metric > 85% ─────────────────────────► [STATE: ALERT ACTIVE]
                                                 │
 Metric fluctuates (82% - 84%) ──────────[STAYS ACTIVE]
                                                 │
 Metric drops below Lower Threshold (75%) ───────┴─► [STATE: ALERT CLEARED]
```

* **Upper Trigger Threshold ($\alpha$):** Metric must exceed $85.0\%$ to transition from `Normal` ➔ `Alert`.
* **Lower Reset Threshold ($\beta$):** Metric must drop below $75.0\%$ for 3 consecutive sampling cycles to transition from `Alert` ➔ `Normal`.

This ensures that the incident feed and status badges remain rock-solid and free of visual noise.

---

## 5. Incident Alert Structure & JSON Export Schema

When exported via CLI (`zyphor snapshot`) or TUI (<kbd>E</kbd>), incidents conform to a clean, strongly-typed JSON schema:

```json
{
  "timestamp": 1724781290,
  "overall_health_score": 72,
  "subsystems": {
    "cpu_score": 45,
    "memory_score": 88,
    "disk_score": 95,
    "network_score": 100,
    "thermal_score": 90
  },
  "insights": [
    {
      "severity": "CRITICAL",
      "title": "High CPU Congestion Detected",
      "explanation": "The system is under heavy computational load (92.4%). 'esbuild' is using 78.2% CPU.",
      "action": "Consider suspending or terminating PID 8912 (esbuild) to restore responsiveness."
    }
  ]
}
```

---

## 6. Remediation Playbook Reference

| Diagnostic Incident | Immediate Action (TUI Hotkey) | Long-Term Solution |
| :--- | :--- | :--- |
| **Runaway Process CPU** | Select process in Tab 2, press <kbd>s</kbd> to suspend or <kbd>x</kbd> to kill. | Profile process using <kbd>P</kbd> to identify infinite loops. |
| **Swap Thrashing** | Jump to Tab 2, press <kbd>m</kbd> to sort by RAM, terminate the largest RSS consumer. | Add physical RAM or optimize application memory pool settings. |
| **Disk Queue Saturation** | Identify high-IOPS process in Tab 2, inspect Disk R/W columns. | Move high-write databases to dedicated NVMe storage tiers. |
| **Network Socket Flood** | Jump to Tab 4, scroll Active Socket map to locate rogue PID. | Terminate socket-flooding binary and inspect firewall connection limits. |

---

*Engineered with mathematical precision by Akshar Miyani.*
