# Troubleshooting & FAQ

This guide resolves common issues related to terminal rendering, character encoding, permissions, GPU sensors, and platform-specific quirks.

---

## 🖥️ Terminal & Display Issues

### 1. Garbled Characters or Mojibake (`Γöé`, `Γöê`, `ΓòÉ`) on Windows

**Cause:** The active Windows console code page is configured to CP437 or Windows-1252 instead of UTF-8 (`CP_UTF8` / 65001).

**Solution:**
* Zyphor automatically negotiates UTF-8 code page (`SetConsoleOutputCP(65001)`) upon startup. Ensure you are running the latest version of Zyphor (`zyphor -v`).
* For the best visual experience on Windows, use **Windows Terminal** (default in Windows 11) or modern terminal emulators (Alacritty, WezTerm).
* If running inside legacy `cmd.exe` or third-party shells, you can manually set your console to UTF-8 before launching:
  ```powershell
  chcp 65001
  zyphor
  ```
* Alternatively, run in plain ASCII mode:
  ```powershell
  zyphor --plain
  ```

---

### 2. Colors Look Washed Out or Inverted

**Cause:** Your terminal emulator does not advertise 24-bit TrueColor support or has a conflicting color profile.

**Solution:**
* Set the `COLORTERM` environment variable in your shell profile:
  ```bash
  export COLORTERM=truecolor
  ```
* Cycle to a different built-in theme by pressing <kbd>T</kbd> inside the TUI.
* For pure monochrome terminals, use `zyphor --plain`.

---

## 🔒 Permission & Privilege Boundaries

### 1. Process List Shows Blank Process Names or Missing Working Sets

**Cause:** Modern operating systems protect kernel tasks and processes owned by other user accounts from unprivileged inspection.

**Solution:**
* On **Windows:** Run PowerShell or Windows Terminal as **Administrator** to inspect elevated system services and anti-cheat protected binaries.
* On **Linux:** Run with `sudo` or grant `CAP_SYS_PTRACE` capability to the binary:
  ```bash
  sudo setcap cap_sys_ptrace=ep /usr/local/bin/zyphor
  ```
* On **macOS:** Grant Terminal or iTerm **Full Disk Access** in *System Settings → Privacy & Security*.

---

## 🎮 GPU & Hardware Sensor Probes

### 1. "No discrete GPU detected" in Overview / GPU Subsystem

**Cause:**
* The machine utilizes integrated graphics (e.g., Intel UHD/Iris) without dedicated VRAM reporting hooks.
* On Linux: Proprietary NVIDIA drivers (`libnvidia-ml.so`) or AMD `amdgpu` sysfs interfaces are not loaded.
* Inside Virtual Machines / WSL2: GPU passthrough is not enabled in the hypervisor.

**Status:**
* Zyphor gracefully falls back to CPU/RAM/Storage/Network monitoring when dedicated GPU telemetry is unavailable.

---

## ❓ Frequently Asked Questions (FAQ)

### Q: How much CPU does Zyphor consume while running?
**A:** Less than 0.4% on modern multi-core systems. Zyphor uses differential cell diffing, zero-allocation memory arenas, and efficient single-pass kernel snapshotting.

### Q: Can I pipe Zyphor output into monitoring scripts?
**A:** Yes! Use subcommands with the `--json` flag:
```bash
zyphor memory --json | jq .used_pct
zyphor cpu --json
zyphor snapshot -o daily-audit.json
```

### Q: How do I run an environment self-audit?
**A:** Run `zyphor doctor` to check kernel probe readiness, privilege level, and sensor availability.
