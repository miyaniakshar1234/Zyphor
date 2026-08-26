# Zyphor Comprehensive User Manual

The User Manual details all operational features, dashboard views, process inspection workflows, and diagnostic tools available in Zyphor.

---

## 🖥️ Dashboard Views & Panels

Zyphor is organized into five primary panels accessible via <kbd>Tab</kbd> or numeric shortcuts (<kbd>1</kbd>–<kbd>5</kbd>).

### 1. Overview Panel (<kbd>1</kbd>)
The default bird's-eye view of your machine's health and activity:

* **System Health Badge:** Real-time health score from `0` (Critical failure) to `100` (Optimal health), computed via multi-factor subsystem analysis.
* **CPU Core Grid:** Live utilization gauges for aggregate CPU and individual logical cores, current clock frequency, and package temperature.
* **Memory Breakdown:** Real-time visual bar of Physical RAM (Used, Free, Cached, Available) and Swap / Pagefile pressure.
* **Network & Disk Throughput:** Live read/write and download/upload speedometers with micro sparklines.
* **Top Resource Consumers:** Live ranking of the highest CPU- and memory-consuming processes.

---

### 2. Process Explorer & Tree Panel (<kbd>2</kbd>)

The Process Explorer provides two complementary viewing modes:

#### A. Flat Table Mode
A high-density tabular view showing:
* **PID:** Process Identifier
* **PPID:** Parent Process Identifier
* **Name / Command:** Executable name or truncated command line
* **CPU%:** Normalized CPU consumption percentage
* **RAM / RSS:** Resident Set Size in human-readable bytes (MB/GB)
* **Disk R/W:** Active disk read/write bandwidth
* **Network I/O:** Current network throughput
* **Threads:** Number of active threads spawned by the process
* **User:** Owning username or UID

#### B. Hierarchical Tree Mode (<kbd>t</kbd>)
Renders the complete process lineage (e.g. `init` -> `systemd` -> `sshd` -> `bash` -> `vim`):
* Subtrees can be expanded and collapsed with <kbd>Space</kbd> or <kbd>Enter</kbd>.
* Aggregated resource rollups sum child CPU and memory into the parent branch.

---

### 3. Deep Process Inspector (<kbd>Enter</kbd> on any process)
Pressing <kbd>Enter</kbd> opens a dedicated overlay with deep metadata:

1. **General:** PID, PPID, executable path, start timestamp, uptime, running user, state (Running, Sleeping, Zombie, Stopped).
2. **CPU Affinity & Threads:** Individual thread IDs, thread states, thread CPU time, core affinity masks.
3. **Memory Details:** Virtual memory size, Resident Set Size (RSS), Shared memory, Private memory, Page fault counters.
4. **Open File Descriptors & Handles:** Open files, sockets, and pipes held by the process.
5. **Network Sockets:** Local address/port, remote address/port, protocol (TCP/UDP), socket state (`ESTABLISHED`, `LISTEN`).

---

### 4. Storage & Filesystem Panel (<kbd>3</kbd>)
* Lists all mounted partitions, physical drives, filesystem types (`ext4`, `btrfs`, `NTFS`, `APFS`, `ZFS`).
* Displays total, used, and free capacity with color-coded capacity thresholds (Green < 75%, Yellow < 90%, Red >= 90%).
* Real-time read/write IOPS and throughput meters.

---

### 5. Network Explorer Panel (<kbd>4</kbd>)
* Per-interface metrics: Wi-Fi, Ethernet, VPN, Loopback, Docker/Virtual bridges.
* Real-time RX/TX rates, total transferred bytes, packet error counters, dropped packet telemetry.
* Socket connection mapping: Identifies which process is communicating with specific remote IPs.

---

### 6. Diagnostics & Alerts Panel (<kbd>5</kbd>)
* **Active Alerts:** Triggered system alerts (e.g., *“High Memory Pressure detected: Swap usage > 15% and RAM > 90%”*).
* **Diagnostic Explanations:** Plain-English explanations of system bottlenecks and recommended user remediation.
* **Timeline Log:** Chronological log of recent significant system events (process spikes, service launches, anomalous behavior).

---

## ⌨️ Complete Keybindings Reference

### Global Navigation
| Key | Action |
| :--- | :--- |
| <kbd>Tab</kbd> | Switch to next panel |
| <kbd>Shift + Tab</kbd> | Switch to previous panel |
| <kbd>1</kbd> – <kbd>5</kbd> | Jump directly to panel (1: Overview, 2: Processes, 3: Storage, 4: Network, 5: Diagnostics) |
| <kbd>?</kbd> | Toggle in-app help modal |
| <kbd>q</kbd> or <kbd>Ctrl + C</kbd> | Quit application |
| <kbd>T</kbd> | Cycle color themes (Midnight -> Cyber -> Aurora -> Nord -> Solarized -> High Contrast) |
| <kbd>Space</kbd> | Pause / Resume real-time metric sampling |
| <kbd>r</kbd> | Force instant screen refresh |

### Process Table Controls
| Key | Action |
| :--- | :--- |
| <kbd>↑</kbd> / <kbd>k</kbd> | Move selection up |
| <kbd>↓</kbd> / <kbd>j</kbd> | Move selection down |
| <kbd>Page Up</kbd> / <kbd>Ctrl + U</kbd> | Scroll up one page |
| <kbd>Page Down</kbd> / <kbd>Ctrl + D</kbd> | Scroll down one page |
| <kbd>Home</kbd> / <kbd>g</kbd> | Jump to first process |
| <kbd>End</kbd> / <kbd>G</kbd> | Jump to last process |
| <kbd>t</kbd> | Toggle Process Tree view |
| <kbd>/</kbd> | Open live fuzzy search filter |
| <kbd>Esc</kbd> | Clear search filter or close modal |
| <kbd>c</kbd> | Sort table by CPU % |
| <kbd>m</kbd> | Sort table by Memory (RSS) |
| <kbd>p</kbd> | Sort table by PID |
| <kbd>n</kbd> | Sort table by Process Name |
| <kbd>s</kbd> | Suspend selected process (`SIGSTOP` / `NtSuspendProcess`) |
| <kbd>u</kbd> | Resume selected process (`SIGCONT` / `NtResumeProcess`) |
| <kbd>x</kbd> or <kbd>k</kbd> | Terminate / Kill selected process (prompts confirmation) |

---

## 🖱️ Mouse Support
Where supported by your terminal emulator:
* **Click on Tab Headers:** Switch active panel.
* **Click on Process Row:** Select process for inspection.
* **Mouse Wheel:** Scroll process tables and diagnostic timelines.
