# Alerts & Diagnostics Engine

Zyphor doesn't just show you numbers; it interprets them.

## The AI Heuristic Pipeline
Located in src/core/ai.zig, the heuristic engine continuously ingests the SystemSnapshot. It evaluates:
- **Thermal Velocity:** Is the CPU clock dropping while load is high? (Thermal throttling).
- **VMM Thrashing:** Is the system pagefile/swap activity spiking alongside high memory pressure? (RAM saturation).
- **Disk I/O Wait:** Are processes stalling due to disk read queues?

When thresholds are breached, the engine emits localized ACTION playbooks to the Health panel (Tab 5), guiding the user on how to resolve the bottleneck.
