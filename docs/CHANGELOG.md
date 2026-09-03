# Changelog

All notable changes to the Zyphor system observatory are documented here.

## [1.0.8] - 2026-09-03
### Added
- Real Win32 API telemetry engine replacing all mock/fabricated data.
- Native processor identity via Windows Registry (`ProcessorNameString`, `~MHz`).
- Per-core CPU utilization deltas via `NtQuerySystemInformation(SystemProcessorPerformanceInformation)`.
- Real network adapter octets via `GetIfTable` and live TCP socket tracking via `GetExtendedTcpTable`.
- Real background service enumeration via `EnumServicesStatusExW`.
- Real discrete display device detection via `EnumDisplayDevicesW`.
- Precision btop++ rounded Unicode panel frames (`╭`, `╮`, `╯`, `╰`, `─`, `│`).
- Adaptive multi-core grid supporting 28-thread processors.
- Genuine Win32 DNS cache flushing (`dnsapi!DnsFlushResolverCache`) and memory trim (`psapi!EmptyWorkingSet`).

## [1.0.7] - 2026-08-31
### Added
- Consolidated 6 powerhouse screen navigation.
- Real-time Braille rolling waveforms for CPU, disk, and network.
- Explainable autonomous health assessment engine.
