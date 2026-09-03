# Landlock & seccomp-bpf Daemon Sandboxing Specification

## 1. Principle of Least Privilege
When operating in daemon mode (`zyphor daemon`), Zyphor restricts its execution environment using Linux kernel sandboxing primitives:

1. **Filesystem Isolation via Landlock:**
   - Denies read access to sensitive directories (`/home`, `/root`, `/etc/shadow`).
   - Grants read-only access to `/proc`, `/sys`, `/dev`.
   - Grants append-only write access to `/var/log/zyphor/` or standard stdout pipe.

2. **System Call Filtering via seccomp-bpf:**
   - Filters out forbidden system calls:
     - `execve`, `execveat` (prevention of arbitrary code execution)
     - `ptrace` (prevention of process inspection attacks)
     - `chown`, `chmod`, `mount` (prevention of privilege escalation)

## 2. Windows Integrity Levels
On Windows, daemon mode runs under the `SECURITY_MANDATORY_LOW_RID` token with restricted write privileges across system objects.
