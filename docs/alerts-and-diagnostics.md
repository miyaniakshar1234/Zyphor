# Alerts & Diagnostics Engine

Traditional monitoring tools display raw metrics but leave the cognitive burden of root-cause correlation entirely to the operator. Zyphor introduces an **Explainable Root-Cause Diagnostic Engine** and an objective **System Health Score (0–100)**.

---

## 🎯 The System Health Score Algorithm

The overall system health score is a composite multi-factor evaluation bounded between $0$ (Catastrophic Degradation) and $100$ (Optimal Performance):

$$\text{HealthScore} = w_{\text{cpu}} \cdot S_{\text{cpu}} + w_{\text{mem}} \cdot S_{\text{mem}} + w_{\text{disk}} \cdot S_{\text{disk}} + w_{\text{net}} \cdot S_{\text{net}} + w_{\text{therm}} \cdot S_{\text{therm}}$$

### Subsystem Weights ($w_i$)
* **CPU Subsystem ($w_{\text{cpu}} = 0.30$):** High weight due to immediate impact on system responsiveness and thread scheduling.
* **Memory Subsystem ($w_{\text{mem}} = 0.30$):** High weight due to thrashing risks when swap spaces are exhausted.
* **Storage Subsystem ($w_{\text{disk}} = 0.15$):** Evaluates mount point capacity exhaustion and I/O saturation.
* **Network Subsystem ($w_{\text{net}} = 0.15$):** Evaluates packet drop rates and interface saturation.
* **Thermal Subsystem ($w_{\text{therm}} = 0.10$):** Evaluates thermal throttling risk.

### Health Status Classifications
| Score Range | Status | Meaning |
| :---: | :---: | :--- |
| **90 – 100** | `EXCELLENT` | Subsystems operating within optimal capacity margins. |
| **75 – 89** | `GOOD` | Nominal operation with mild resource utilization. |
| **60 – 74** | `FAIR` | Moderate resource contention; potential bottleneck forming. |
| **40 – 59** | `POOR` | Significant degradation; active performance penalty. |
| **0 – 39** | `CRITICAL` | Severe system stress; imminent risk of OOM kills or lockup. |

---

## 🔍 Heuristic Anomaly Rules

Zyphor's diagnostic engine continuously evaluates an ensemble of deterministic rules:

### 1. Memory Pressure & Thrashing Rule
* **Condition:** Physical Memory Used > 90% AND Swap Utilization > 60%
* **Severity:** `CRITICAL`
* **Diagnosis:** Kernel page daemon is actively evicting working set pages to swap disk.
* **Remediation:** Identify top RSS processes and terminate memory leak culprits.

### 2. Runaway CPU / Thread Starvation Rule
* **Condition:** Overall CPU Load > 95% for > 5 consecutive sampling ticks
* **Severity:** `WARNING` / `CRITICAL`
* **Diagnosis:** Compute pipeline saturation. Context switch latency is elevated.
* **Remediation:** Check process tree to isolate parallel build scripts or compute tasks.

### 3. Filesystem Capacity Saturation Rule
* **Condition:** Any mounted filesystem capacity > 90%
* **Severity:** `WARNING` (if > 90%), `CRITICAL` (if > 98%)
* **Diagnosis:** Partition is near capacity; risk of write failure for system logs and database journals.

### 4. Network Link Degradation Rule
* **Condition:** Active network interface down or packet drop rate > 5%
* **Severity:** `WARNING`
* **Diagnosis:** Network link negotiation failure or packet collision.

---

## 🛡️ Hysteresis & Anti-Flapping State Machine

To prevent transient CPU spikes (e.g., launching an application or compiling a file) from causing noisy alert churn, Zyphor applies an **Exponentially Weighted Moving Average (EWMA)** filter combined with state-transition hysteresis:

* An alert is only triggered when a threshold is breached across multiple consecutive frames.
* An active alert is only cleared after metrics stay below a recovery threshold for at least 3 sampling cycles.
