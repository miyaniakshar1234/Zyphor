# Zyphor Linux cgroup v2 Unified Resource Controller

## Overview
On Linux kernels 4.15+, Zyphor interfaces directly with `/sys/fs/cgroup` to monitor hierarchical resource limits, memory protection levels, and CPU bandwidth throttling.

## Controller Mappings

| Cgroup Controller | Sysfs File Path | Telemetry Exposed |
| :--- | :--- | :--- |
| **CPU** | `cpu.stat`, `cpu.max` | Throttled periods, burst capacity, CFS quota |
| **Memory** | `memory.current`, `memory.high` | Working set, slab cache, OOM kill count |
| **I/O** | `io.stat`, `io.weight` | Read/Write IOPS, queue latency, throttling |
| **PSI** | `memory.pressure`, `cpu.pressure` | Some / Full stall percentages (10s, 60s, 300s) |

## Container Discovery Engine
Zyphor auto-detects container runtimes (Docker, Podman, containerd, Kubernetes Kubelet) by scanning `/sys/fs/cgroup/system.slice` and `/sys/fs/cgroup/docker.slice`.
