# Zyphor Command Line Interface Manual

Zyphor supports non-interactive CLI subcommands for headless environments, automated audits, and pipeline scripting.

## Commands

### `zyphor doctor`
Performs comprehensive diagnostic audit of host platform capabilities, native CPU features, RAM limits, GPU detection, and privilege level:
```bash
zyphor doctor
```

### `zyphor cpu`
Dumps live CPU model, clock speed, core topology, and load metrics:
```bash
zyphor cpu
```

### `zyphor memory`
Dumps physical RAM allocation, swap/pagefile status, and memory pressure:
```bash
zyphor memory
```

### `zyphor disk`
Displays volume partition table, filesystem formats, capacity, and usage:
```bash
zyphor disk
```

### `zyphor --json`
Outputs a complete, machine-readable JSON snapshot of all system telemetry:
```bash
zyphor --json
```
