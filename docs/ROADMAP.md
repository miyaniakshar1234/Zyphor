# Zyphor Engineering Roadmap

## Milestone 1: Windows NT Native Parity (Completed)
- [x] Full Win32 telemetry implementation (GetSystemTimes, NtQuerySystemInformation).
- [x] Registry CPU model and frequency detection.
- [x] GetIfTable interface octet throughput and GetExtendedTcpTable socket maps.
- [x] Service Control Manager integration (EnumServicesStatusExW).
- [x] btop++ precision rounded frame redesign.

## Milestone 2: Cross-Platform Linux Backend (In Progress)
- [ ] Direct `/proc/stat` and `/proc/cpuinfo` parsing.
- [ ] `/proc/net/dev` and `/proc/net/tcp` socket tracing.
- [ ] Systemd D-Bus service status integration.
- [ ] Linux cgroup v2 container telemetry.

## Milestone 3: macOS Darwin Backend
- [ ] `host_processor_info` Mach port kernel telemetry.
- [ ] Apple Silicon M-series unified memory bandwidth metrics.
- [ ] `libproc` process lineage exploration.
