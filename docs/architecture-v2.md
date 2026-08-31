# Zyphor V2 Architecture & Future Roadmap

## V2 High-Level Objectives

1. **eBPF Kernel Socket Lifecycle & Tracing:** Low-overhead live TCP retransmissions, socket connect/accept latency, and packet drops via BPF CO-RE on Linux.
2. **Distributed Remote Daemon Cluster Mode:** Connect multiple remote Zyphor agents to a central aggregation dashboard over TLS gRPC/WebSocket streams.
3. **Automated Root-Cause Correlation:** AI-assisted anomaly attribution pinpointing exact PID, thread, and memory leak culprit for system slowdowns.
