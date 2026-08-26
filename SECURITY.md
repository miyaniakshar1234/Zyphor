# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

The Zyphor team takes security vulnerabilities seriously.

If you believe you have discovered a security vulnerability in Zyphor:

1. **Do not create a public GitHub issue.**
2. Send a detailed report to security@zyphor.dev (or via GitHub Private Vulnerability Reporting).
3. Include:
   - Steps to reproduce
   - Operating system and architecture
   - Potential impact
   - Any proof of concept or sample configuration

## Security Architecture Guarantees
- **No Telemetry by Default:** Zyphor does not transmit metrics, process names, or system logs over the network unless explicitly running in remote agent mode.
- **Principle of Least Privilege:** Zyphor avoids requiring root/Administrator privileges where standard OS performance APIs are available.
- **Safe Process Actions:** Destructive process signals (`SIGKILL`, `TerminateProcess`) require explicit user confirmation.
