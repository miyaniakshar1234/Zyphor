# Zyphor Keyboard Navigation & Shortcuts

Zyphor features intuitive, vim-inspired and btop++-style keybindings for rapid system diagnosis.

## Screen Navigation
| Key | Action |
|---|---|
| `1` | Jump to **Overview Matrix** (CPU, RAM, Disks, Network, GPU) |
| `2` | Jump to **Process Explorer** (Process lineage tree, threads, RSS) |
| `3` | Jump to **Storage Observatory** (Partitions, I/O rates, capacity) |
| `4` | Jump to **Network Observatory** (Interfaces, live TCP sockets, speed test) |
| `5` | Jump to **Hardware Diagnostics** (CPU topology, 28-thread matrix, GPU) |
| `6` | Jump to **Services & Daemons** (Win32 background service controller) |
| `Tab` | Cycle to next screen |
| `q` / `Ctrl+C` | Graceful exit |

## Process Explorer Controls
| Key | Action |
|---|---|
| `↑` / `k` | Move selection up |
| `↓` / `j` | Move selection down |
| `t` | Toggle Process Lineage Tree vs Flat Mode |
| `c` | Sort processes by CPU usage descending |
| `m` | Sort processes by Memory RSS descending |
| `/` | Open interactive process search filter |
| `Enter` | Open deep process inspector modal |
| `x` | Kill / terminate selected process |

## Global Modals
| Key | Action |
|---|---|
| `F` | Open Defensive Remediation & Self-Healing Modal |
| `T` | Cycle through 10 built-in color themes |
| `p` | Pause / Freeze telemetry updates |
| `?` | Toggle Help & Keybinding Overlay |
| `Esc` | Close active modal / clear search filter |
