# Zyphor Systemd Service & Unit Hierarchy Engine

## Overview
Zyphor Tab 6 (`⛯ 6: Services`) maps the entire system service ecosystem across Linux and Windows systems.

## Subsystem Architecture

### Linux D-Bus & Unit File Parser
- Discovers active `.service`, `.socket`, `.target`, and `.mount` units.
- Evaluates unit states: `active (running)`, `inactive (dead)`, `activating`, `failed`.
- Traces unit dependency trees (`Requires=`, `Wants=`, `After=`, `Before=`).

### Windows Service Control Manager (SCM)
- Direct Win32 `EnumServicesStatusExW` integration.
- Telemetry: Service name, display description, PID, start type (`Auto`, `Manual`, `Disabled`), and current status (`SERVICE_RUNNING`, `SERVICE_STOPPED`).
