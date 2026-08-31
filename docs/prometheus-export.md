# Zyphor Prometheus & OpenMetrics Scrape Protocol

## Overview
Zyphor supports running in headless daemon mode (`zyphor daemon --port 9100`) to expose native Prometheus / OpenMetrics scrape endpoints for Grafana, Datadog, and VictoriaMetrics ingestion.

## Standard Metrics Exposed

```prometheus
# HELP zyphor_cpu_utilization_percent Total CPU utilization percentage
# TYPE zyphor_cpu_utilization_percent gauge
zyphor_cpu_utilization_percent 24.5

# HELP zyphor_memory_used_bytes Allocated physical memory in bytes
# TYPE zyphor_memory_used_bytes gauge
zyphor_memory_used_bytes 17179869184

# HELP zyphor_memory_total_bytes Total physical memory in bytes
# TYPE zyphor_memory_total_bytes gauge
zyphor_memory_total_bytes 34359738368

# HELP zyphor_disk_read_bytes_total Cumulative bytes read from storage
# TYPE zyphor_disk_read_bytes_total counter
zyphor_disk_read_bytes_total 1048576000

# HELP zyphor_system_health_score Composite health diagnostics score (0-100)
# TYPE zyphor_system_health_score gauge
zyphor_system_health_score 98
```

## CLI Ingestion Usage
```bash
# Start background metric scraper on port 9100
zyphor daemon --port 9100 --interval 1s

# Query live metrics snapshot via curl
curl http://localhost:9100/metrics
```
