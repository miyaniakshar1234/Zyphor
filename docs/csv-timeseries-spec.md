# Native CSV Time-Series Telemetry Specification

## 1. File Structure
The CSV telemetry exporter streams structured performance metrics directly to disk:

```csv
timestamp_iso8601,cpu_total_pct,cpu_user_pct,cpu_sys_pct,cpu_iowait_pct,ram_used_bytes,ram_total_bytes,swap_used_bytes,disk_read_bytes_sec,disk_write_bytes_sec,net_rx_bytes_sec,net_tx_bytes_sec,gpu_util_pct,gpu_temp_c,health_score
```

## 2. Ingestion Guarantees
- **Encoding:** Strict UTF-8 with RFC 4180 newline separators (`\r\n` on Windows, `\n` on POSIX).
- **Buffer Flush:** Uses a 4 KB in-memory ring buffer flushed every 10 samples or immediately on SIGINT/SIGTERM.
- **Precision:** Floats are formatted with a maximum of 2 decimal places to minimize file size.
