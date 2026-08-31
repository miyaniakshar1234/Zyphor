# Zyphor Complete Keyboard & Hotkey Reference Matrix

## Tab & Panel Navigation

| Hotkey | Target Panel Viewport | Description |
| :--- | :--- | :--- |
| `1` | `⬡ 1: Overview` | Panoramic System Matrix & Radial Gauges |
| `2` | `◈ 2: Processes` | Interactive Process Explorer & Lineage Trees |
| `3` | `⬢ 3: Storage` | Physical Disks, Partitions & Directory Tree |
| `4` | `◉ 4: Network` | Interfaces, Sockets & Speed/Stress Benchmark |
| `5` | `❤ 5: Health & Alerts` | System Health Score, Anomalies & Self-Healing |
| `6` | `⛯ 6: Services` | System Daemons & Service Control Manager |
| `7` | `⬖ 7: Containers` | Docker, Podman & Containerd Sandbox Engine |
| `8` | `⚡ 8: Hardware & GPU` | Dedicated GPU, VRAM, Clocks & Thermals |
| `9` | `📋 9: Kernel Logs` | Real-Time Kernel Events & System Log Stream |
| `Tab` | Next Tab | Cyclic forward navigation across all 9 tabs |
| `Shift+Tab` | Previous Tab | Cyclic backward navigation across all 9 tabs |

## Process Explorer Controls
| Hotkey | Action |
| :--- | :--- |
| `j` / `↓` | Move selection down |
| `k` / `↑` | Move selection up |
| `Enter` | Open Process Deep Inspector Modal |
| `x` / `K` | Open Multi-Signal Termination Modal (`SIGKILL`, `SIGTERM`, `SIGSTOP`) |
| `t` | Toggle Process Lineage Tree Hierarchy (DFS) |
| `c` | Sort by CPU % load (descending) |
| `m` | Sort by Memory RSS footprint (descending) |
| `p` | Sort by Process ID (PID) |
| `n` | Sort by Process Executable Name (alphabetical) |
| `/` | Open live interactive search filter |
| `Esc` | Clear search filter or close modal |

## Global Diagnostics & Remediation
| Hotkey | Action |
| :--- | :--- |
| `F` | Execute Defensive Self-Healing Remediation |
| `R` | Toggle 60-second Flight Recorder Replay Mode |
| `<` / `>` | Scrub historical telemetry backward / forward in time |
| `Space` | Freeze / Resume live telemetry feed |
| `T` / `]` | Cycle through 10 TrueColor cyberpunk themes |
| `:` / `Ctrl+P` | Open Interactive Command Palette |
| `?` | Open Help & Keybinding Modal |
| `q` / `Ctrl+C` | Graceful exit with terminal state restoration |
