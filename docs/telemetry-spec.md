# Zyphor Telemetry Protocol & Data Specification

## Architecture
Zyphor polls platform telemetry providers at user-configured frequencies (default 1000ms) with zero heap fragmentation.

## Core Schema Definitions

### CPU Metrics (`types.CpuMetrics`)
- `total_usage`: Global percentage (0.0 to 100.0)
- `user_usage`: User-space computation percentage
- `system_usage`: Kernel execution percentage
- `idle_usage`: Idle percentage
- `frequency_mhz`: Core clock frequency
- `physical_cores`: Core count
- `logical_cores`: Hardware thread count
- `core_usage`: Sliced per-core utilization array

### Memory Metrics (`types.MemoryMetrics`)
- `total_bytes`: Installed physical RAM
- `used_bytes`: Allocated memory
- `available_bytes`: Freely allocatable memory
- `cached_bytes`: File system cache
- `swap_total_bytes`: Virtual swap memory capacity
- `swap_used_bytes`: Active swap allocation
- `pressure_level`: PSI pressure indicator (`.low`, `.medium`, `.high`, `.critical`)

### Disk Metrics (`types.DiskMetrics`)
- `partitions`: Slices of mounted block devices with mount point, filesystem, and usage
- `read_bytes_sec` & `write_bytes_sec`: Real-time block transfer rates
- `read_iops` & `write_iops`: I/O operations per second
- `avg_latency_ms`: Queue depth latency
