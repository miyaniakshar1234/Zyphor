# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

The Zyphor development team is dedicated to maintaining native memory safety, zero-panic execution, and bulletproof privilege isolation.

If you discover a security vulnerability, buffer overflow, or potential denial-of-service in Zyphor:

1. **Do NOT open a public GitHub issue.**
2. Send a detailed report directly to the lead maintainer:
   - **Lead Developer:** Akshar Miyani ([@miyaniakshar1234](https://github.com/miyaniakshar1234))
   - **GitHub Security Advisories:** Use the private vulnerability reporting feature on GitHub.

### What to Include in Your Report
- Detailed steps to reproduce the issue.
- Target platform (Windows 10/11 x86_64, Linux kernel version, or macOS Darwin).
- Terminal dimensions or input payload that triggered the issue.
- Stack trace or crash dump if applicable.

### Security Guarantees
- **Zero-Allocation Hot-Loop:** Telemetry sampling frames avoid unbounded heap allocations.
- **Process Isolation:** Process termination (`SIGKILL`, `SIGTERM`, `SIGSTOP`) requires appropriate OS privileges and validates target PID existence.
- **HTML Sanitization:** HTML diagnostic reports strictly escape all entity characters to prevent XSS injection.
- **Safe Floating-Point Arithmetic:** All sensor calculations and chart renderers are hardened against `NaN`, `+Inf`, and negative boundaries.

### Response Time
We aim to acknowledge reports within **24 hours** and provide a patched hotfix release within **72 hours**.
