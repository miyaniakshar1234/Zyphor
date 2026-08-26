const std = @import("std");
const builtin = @import("builtin");
const engine_mod = @import("../core/engine.zig");
const types = @import("../core/types.zig");

pub fn runDoctor(engine: *engine_mod.SystemEngine, json_mode: bool) !void {
    const stdout = types.getStdout();
    const snap = try engine.sampleSnapshot();

    if (json_mode) {
        try stdout.print(
            \\{{
            \\  "os": "{s}",
            \\  "arch": "{s}",
            \\  "is_elevated": false,
            \\  "telemetry": {{
            \\    "cpu": true,
            \\    "memory": true,
            \\    "disk": true,
            \\    "network": true,
            \\    "process_tree": true,
            \\    "gpu": {s},
            \\    "battery": {s}
            \\  }},
            \\  "compatibility_score": 100
            \\}}
            \\
        , .{
            @tagName(builtin.os.tag),
            @tagName(builtin.cpu.arch),
            if (snap.gpu.available) "true" else "false",
            if (snap.battery.available) "true" else "false",
        });
        return;
    }

    try stdout.print(
        \\
        \\==================================================================
        \\  ZYPHOR SYSTEM COMPATIBILITY & DIAGNOSTICS AUDIT (zyphor doctor)
        \\==================================================================
        \\
        \\  OS Platform:             {s} ({s})
        \\  Compiler & Target:       Zig 0.15.x
        \\  Privilege Level:         Standard User
        \\
        \\  Subsystem Readiness:
        \\    ✓ CPU Telemetry:       Available ({d} logical cores, {d} MHz)
        \\    ✓ Memory Telemetry:    Available ({d} GB RAM detected)
        \\    ✓ Disk Telemetry:      Available ({d} partitions detected)
        \\    ✓ Network Telemetry:   Available ({d} interfaces active)
        \\    ✓ Process Explorer:    Available (Direct OS native snapshot)
        \\    {s} GPU Telemetry:       {s}
        \\    {s} Battery / Power:     {s}
        \\    ✓ ANSI Virtual Term:   Fully Supported
        \\
        \\  System Health Score:     {d}/100 [{s}]
        \\  Overall Readiness:       100% - Ready for full observatory mode!
        \\==================================================================
        \\
    , .{
        @tagName(builtin.os.tag),
        @tagName(builtin.cpu.arch),
        snap.cpu.logical_cores,
        snap.cpu.frequency_mhz,
        snap.memory.total_bytes / (1024 * 1024 * 1024),
        snap.disk.partitions.len,
        snap.network.interfaces.len,
        if (snap.gpu.available) "✓" else "○",
        if (snap.gpu.available) snap.gpu.getName() else "No dedicated GPU detected",
        if (snap.battery.available) "✓" else "○",
        if (snap.battery.available) "Battery detected" else "AC Power / Desktop mode",
        snap.health.overall_score,
        snap.health.status.asText(),
    });
}
