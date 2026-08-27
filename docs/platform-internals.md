# Platform Internals & Probes

Zyphor is a native binary. It completely avoids WMI (Windows Management Instrumentation) due to its extreme overhead.

## Windows Integration
- We hook directly into 
tdll.dll and dvapi32.dll.
- Process iteration uses NtQuerySystemInformation with the SystemProcessInformation class for near-instantaneous polling of all user and kernel threads.
- Root elevation is verified by checking the Process Token against DOMAIN_ALIAS_RID_ADMINS.

## Linux Integration (In Progress)
- Zero-copy reads of /proc/stat and /proc/meminfo.
- Netlink sockets for instantaneous network traffic deltas.
