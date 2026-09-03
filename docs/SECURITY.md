# Zyphor Security Architecture

## Principle of Least Privilege
Zyphor is strictly engineered to operate safely under **standard user privileges (non-elevated)**.

1. **No Kernel Drivers Required**:
   Zyphor does not load unsigned or third-party Ring 0 drivers. All telemetry queries are performed via safe, documented Win32 user-mode APIs.
2. **Safe Registry Reads**:
   Processor identity (`ProcessorNameString`) and frequency (`~MHz`) are queried under read-only access (`KEY_QUERY_VALUE`) from `HKLM\HARDWARE\DESCRIPTION`.
3. **Protected Process Boundaries**:
   Process queries use `PROCESS_QUERY_LIMITED_INFORMATION`. Zyphor gracefully handles access-denied responses when encountering protected system processes without crashing.
4. **Transparent Privilege Disclosure**:
   The top header clearly indicates current authorization (`[USER]` vs `[ROOT]`). Features requiring elevation disclose requirements honestly rather than fabricating data.
