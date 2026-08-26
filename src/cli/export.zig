const std = @import("std");
const types = @import("../core/types.zig");

pub fn printJsonSnapshot(writer: anytype, snap: *const types.SystemSnapshot) !void {
    try writer.print(
        \\{{
        \\  "timestamp_ms": {d},
        \\  "cpu": {{
        \\    "total_usage_pct": {d:.2},
        \\    "user_pct": {d:.2},
        \\    "system_pct": {d:.2},
        \\    "idle_pct": {d:.2},
        \\    "frequency_mhz": {d},
        \\    "logical_cores": {d},
        \\    "physical_cores": {d}
        \\  }},
        \\  "memory": {{
        \\    "total_bytes": {d},
        \\    "used_bytes": {d},
        \\    "free_bytes": {d},
        \\    "available_bytes": {d},
        \\    "used_pct": {d:.2},
        \\    "swap_total_bytes": {d},
        \\    "swap_used_bytes": {d},
        \\    "swap_used_pct": {d:.2},
        \\    "pressure_level": "{s}"
        \\  }},
        \\  "disk": {{
        \\    "read_bytes_sec": {d},
        \\    "write_bytes_sec": {d},
        \\    "partitions": [
        \\
    , .{
        snap.timestamp_ms,
        snap.cpu.total_usage,
        snap.cpu.user_usage,
        snap.cpu.system_usage,
        snap.cpu.idle_usage,
        snap.cpu.frequency_mhz,
        snap.cpu.logical_cores,
        snap.cpu.physical_cores,
        snap.memory.total_bytes,
        snap.memory.used_bytes,
        snap.memory.free_bytes,
        snap.memory.available_bytes,
        snap.memory.used_percent,
        snap.memory.swap_total_bytes,
        snap.memory.swap_used_bytes,
        snap.memory.swap_used_percent,
        snap.memory.pressure_level.asText(),
        snap.disk.read_bytes_sec,
        snap.disk.write_bytes_sec,
    });

    for (snap.disk.partitions, 0..) |part, idx| {
        try writer.print(
            \\      {{ "mount": "{s}", "fs": "{s}", "total_bytes": {d}, "used_bytes": {d}, "used_pct": {d:.2} }}{s}
            \\
        , .{
            part.getMount(),
            part.getFs(),
            part.total_bytes,
            part.used_bytes,
            part.used_percent,
            if (idx + 1 < snap.disk.partitions.len) "," else "",
        });
    }

    try writer.print(
        \\    ]
        \\  }},
        \\  "network": {{
        \\    "total_rx_sec": {d},
        \\    "total_tx_sec": {d}
        \\  }},
        \\  "gpu": {{
        \\    "available": {s},
        \\    "name": "{s}",
        \\    "utilization_pct": {d:.2},
        \\    "vram_total_bytes": {d},
        \\    "vram_used_bytes": {d}
        \\  }},
        \\  "health": {{
        \\    "score": {d},
        \\    "status": "{s}",
        \\    "summary": "{s}"
        \\  }},
        \\  "top_processes": [
        \\
    , .{
        snap.network.total_rx_sec,
        snap.network.total_tx_sec,
        if (snap.gpu.available) "true" else "false",
        snap.gpu.getName(),
        snap.gpu.utilization_pct,
        snap.gpu.vram_total_bytes,
        snap.gpu.vram_used_bytes,
        snap.health.overall_score,
        snap.health.status.asText(),
        snap.health.getSummary(),
    });

    for (snap.top_processes, 0..) |p, idx| {
        try writer.print(
            \\      {{ "pid": {d}, "ppid": {d}, "name": "{s}", "cpu_pct": {d:.2}, "rss_bytes": {d}, "threads": {d}, "state": "{s}" }}{s}
            \\
        , .{
            p.pid,
            p.ppid,
            p.getName(),
            p.cpu_percent,
            p.memory_rss,
            p.threads_count,
            p.state.asText(),
            if (idx + 1 < snap.top_processes.len) "," else "",
        });
    }

    try writer.writeAll(
        \\    ]
        \\  }
        \\}
        \\
    );
}

pub fn saveSnapshotFile(allocator: std.mem.Allocator, snap: *const types.SystemSnapshot, custom_path: ?[]const u8) !void {
    var filename_buf: [128]u8 = undefined;
    const path = if (custom_path) |p| p else try std.fmt.bufPrint(&filename_buf, "zyphor-snapshot-{d}.json", .{snap.timestamp_ms});

    _ = allocator;
    const file = try std.fs.cwd().createFile(path, .{});
    defer file.close();

    const file_writer = types.OutWriter{ .file = file };
    try printJsonSnapshot(file_writer, snap);
    std.debug.print("✓ System snapshot saved to: {s}\n", .{path});
}
