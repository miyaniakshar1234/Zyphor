# Troubleshooting & FAQ

This guide helps resolve common issues related to permissions, terminal capabilities, and metric availability.

---

## 🔍 First Step: Run `zyphor doctor`

Always run `zyphor doctor` first. It performs an automated audit of your operating system APIs, permission level, and terminal capabilities:

```bash
zyphor doctor
```

---

## ⚠️ Common Issues & Solutions

### 1. "Permission Denied" / Limited Process Information
* **Symptom:** Some process names, open files, or network sockets show as `[Access Denied]` or `N/A`.
* **Cause:** Operating systems restrict unprivileged standard users from reading the memory layout, open handles, or environment of processes owned by other users or system services (like `svchost.exe` on Windows or `root` daemons on Linux).
* **Solution:**
  * To inspect system-wide protected processes, run with elevated privileges:
    * **Linux / macOS:** `sudo zyphor`
    * **Windows:** Run PowerShell / Windows Terminal as **Administrator**.
  * Zyphor operates normally without root/Admin for all standard user processes.

---

### 2. Terminal UI Visual Glitches / Garbled Characters
* **Symptom:** Borders or gauge bars appear as `âââ` or strange glyphs.
* **Cause:** Your terminal emulator does not have UTF-8 / Unicode enabled or is using a legacy font that lacks box-drawing characters.
* **Solution:**
  * Use a modern terminal emulator:
    * **Windows:** Windows Terminal, WezTerm, Alacritty.
    * **Linux:** Alacritty, Kitty, GNOME Terminal, Foot.
    * **macOS:** iTerm2, Kitty, Alacritty, Terminal.app.
  * Alternatively, launch Zyphor in ASCII fallback mode:
    ```bash
    zyphor --plain
    ```

---

### 3. GPU Metrics Missing or "Unavailable"
* **Symptom:** GPU gauge shows `N/A` or `GPU Telemetry Unavailable`.
* **Cause:**
  * **NVIDIA:** NVIDIA drivers / NVML library (`nvml.dll` or `libnvidia-ml.so`) are not installed or in system library paths.
  * **Virtual Machines:** Standard VMs without GPU passthrough do not expose GPU hardware telemetry to the guest OS.
* **Solution:** Ensure proprietary GPU drivers are installed or run `zyphor doctor` to check driver detection status.

---

### 4. High CPU Usage by Zyphor Itself
* **Symptom:** Zyphor consumes >3% CPU while monitoring.
* **Cause:** Refresh rate set too aggressively on machines with thousands of active processes.
* **Solution:** Increase the refresh interval:
  ```bash
  zyphor --refresh 2000
  ```
