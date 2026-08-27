const std = @import("std");
const types = @import("../core/types.zig");

pub fn writeJsonEscapedString(writer: anytype, str: []const u8) !void {
    try writer.writeAll("\"");
    for (str) |c| {
        switch (c) {
            '"' => try writer.writeAll("\\\""),
            '\\' => try writer.writeAll("\\\\"),
            '\n' => try writer.writeAll("\\n"),
            '\r' => try writer.writeAll("\\r"),
            '\t' => try writer.writeAll("\\t"),
            else => {
                if (c < 0x20) {
                    var hex_buf: [6]u8 = undefined;
                    _ = std.fmt.bufPrint(&hex_buf, "\\u{x:0>4}", .{c}) catch unreachable;
                    try writer.writeAll(&hex_buf);
                } else {
                    const char_slice = [_]u8{c};
                    try writer.writeAll(&char_slice);
                }
            },
        }
    }
    try writer.writeAll("\"");
}

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
        try writer.writeAll("      { \"mount\": ");
        try writeJsonEscapedString(writer, part.getMount());
        try writer.writeAll(", \"fs\": ");
        try writeJsonEscapedString(writer, part.getFs());
        try writer.print(", \"total_bytes\": {d}, \"used_bytes\": {d}, \"used_pct\": {d:.2} ", .{
            part.total_bytes,
            part.used_bytes,
            part.used_percent,
        });
        if (idx + 1 < snap.disk.partitions.len) {
            try writer.writeAll("},\n");
        } else {
            try writer.writeAll("}\n");
        }
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
        \\    "name": 
    , .{
        snap.network.total_rx_sec,
        snap.network.total_tx_sec,
        if (snap.gpu.available) "true" else "false",
    });

    try writeJsonEscapedString(writer, snap.gpu.getName());

    try writer.print(
        \\,
        \\    "utilization_pct": {d:.2},
        \\    "vram_total_bytes": {d},
        \\    "vram_used_bytes": {d}
        \\  }},
        \\  "health": {{
        \\    "score": {d},
        \\    "status": "{s}",
        \\    "summary": 
    , .{
        snap.gpu.utilization_pct,
        snap.gpu.vram_total_bytes,
        snap.gpu.vram_used_bytes,
        snap.health.overall_score,
        snap.health.status.asText(),
    });

    try writeJsonEscapedString(writer, snap.health.getSummary());

    try writer.writeAll(
        \\
        \\  },
        \\  "top_processes": [
        \\
    );

    for (snap.top_processes, 0..) |p, idx| {
        try writer.print("      {{ \"pid\": {d}, \"ppid\": {d}, \"name\": ", .{ p.pid, p.ppid });
        try writeJsonEscapedString(writer, p.getName());
        try writer.print(", \"cpu_pct\": {d:.2}, \"rss_bytes\": {d}, \"threads\": {d}, \"state\": \"{s}\" }}", .{
            p.cpu_percent,
            p.memory_rss,
            p.threads_count,
            p.state.asText(),
        });
        if (idx + 1 < snap.top_processes.len) {
            try writer.writeAll(",\n");
        } else {
            try writer.writeAll("\n");
        }
    }

    try writer.print(
        \\    ],
        \\  "boot": {{
        \\    "total_boot_sec": {d:.2},
        \\    "kernel_time_sec": {d:.2},
        \\    "services_time_sec": {d:.2},
        \\    "user_session_sec": {d:.2}
        \\  }},
        \\  "services": [
        \\
    , .{
        snap.boot.total_boot_s,
        snap.boot.kernel_time_s,
        snap.boot.services_time_s,
        snap.boot.user_session_s,
    });

    for (snap.services, 0..) |srv, idx| {
        try writer.writeAll("      { \"name\": ");
        try writeJsonEscapedString(writer, srv.getName());
        try writer.writeAll(", \"display_name\": ");
        try writeJsonEscapedString(writer, srv.getDisplayName());
        try writer.print(", \"status\": \"{s}\", \"startup\": ", .{srv.status.asText()});
        try writeJsonEscapedString(writer, srv.getStartupType());
        if (idx + 1 < snap.services.len) {
            try writer.writeAll(" },\n");
        } else {
            try writer.writeAll(" }\n");
        }
    }

    try writer.writeAll(
        \\    ]
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

test "JSON string escaping handles quotes, backslashes, and control characters" {
    var buf: [256]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buf);
    const writer = fbs.writer();

    try writeJsonEscapedString(writer, "Hello \"World\" \\ path\n");
    const result = fbs.getWritten();
    try std.testing.expectEqualStrings("\"Hello \\\"World\\\" \\\\ path\\n\"", result);
}
