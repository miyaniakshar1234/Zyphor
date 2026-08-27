const std = @import("std");
const types = @import("../core/types.zig");

pub fn writeJsonEscapedString(writer: anytype, str: []const u8) !void {
    try writer.writeAll("\"");
    var span_start: usize = 0;
    for (str, 0..) |c, idx| {
        switch (c) {
            '"', '\\', '\n', '\r', '\t' => {
                if (idx > span_start) {
                    try writer.writeAll(str[span_start..idx]);
                }
                switch (c) {
                    '"' => try writer.writeAll("\\\""),
                    '\\' => try writer.writeAll("\\\\"),
                    '\n' => try writer.writeAll("\\n"),
                    '\r' => try writer.writeAll("\\r"),
                    '\t' => try writer.writeAll("\\t"),
                    else => unreachable,
                }
                span_start = idx + 1;
            },
            else => {
                if (c < 0x20) {
                    if (idx > span_start) {
                        try writer.writeAll(str[span_start..idx]);
                    }
                    var hex_buf: [6]u8 = undefined;
                    _ = std.fmt.bufPrint(&hex_buf, "\\u{x:0>4}", .{c}) catch unreachable;
                    try writer.writeAll(&hex_buf);
                    span_start = idx + 1;
                }
            },
        }
    }
    if (span_start < str.len) {
        try writer.writeAll(str[span_start..]);
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

pub fn printHtmlSnapshot(writer: anytype, snap: *const types.SystemSnapshot) !void {
    const ts = snap.timestamp_ms;
    const used_ram_gb = @as(f32, @floatFromInt(snap.memory.used_bytes)) / (1024.0 * 1024.0 * 1024.0);
    const total_ram_gb = @as(f32, @floatFromInt(snap.memory.total_bytes)) / (1024.0 * 1024.0 * 1024.0);
    const rx_mb = @as(f32, @floatFromInt(snap.network.total_rx_sec)) / (1024.0 * 1024.0);
    const tx_mb = @as(f32, @floatFromInt(snap.network.total_tx_sec)) / (1024.0 * 1024.0);
    const disk_r_mb = @as(f32, @floatFromInt(snap.disk.read_bytes_sec)) / (1024.0 * 1024.0);
    const disk_w_mb = @as(f32, @floatFromInt(snap.disk.write_bytes_sec)) / (1024.0 * 1024.0);

    try writer.print(
        \\<!DOCTYPE html>
        \\<html lang="en">
        \\<head>
        \\<meta charset="UTF-8">
        \\<meta name="viewport" content="width=device-width, initial-scale=1.0">
        \\<title>Zyphor System Observatory Report</title>
        \\<style>
        \\:root {{
        \\  --bg: #0c0e14;
        \\  --card: #151822;
        \\  --border: #232936;
        \\  --accent: #d97706;
        \\  --secondary: #06b6d4;
        \\  --success: #10b981;
        \\  --warning: #f59e0b;
        \\  --critical: #ef4444;
        \\  --text: #f3f4f6;
        \\  --muted: #9ca3af;
        \\}}
        \\* {{ box-sizing: border-box; margin: 0; padding: 0; }}
        \\body {{ background: var(--bg); color: var(--text); font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, monospace; padding: 24px; }}
        \\.header {{ display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid var(--border); padding-bottom: 16px; margin-bottom: 24px; }}
        \\.logo {{ font-size: 24px; font-weight: bold; color: var(--accent); }}
        \\.badge {{ padding: 6px 12px; border-radius: 6px; font-weight: bold; font-size: 14px; background: rgba(16,185,129,0.15); color: var(--success); border: 1px solid var(--success); }}
        \\.grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 20px; margin-bottom: 24px; }}
        \\.card {{ background: var(--card); border: 1px solid var(--border); border-radius: 12px; padding: 20px; }}
        \\.card-title {{ font-size: 14px; color: var(--muted); text-transform: uppercase; letter-spacing: 1px; margin-bottom: 12px; font-weight: 600; }}
        \\.stat-huge {{ font-size: 32px; font-weight: bold; margin-bottom: 8px; }}
        \\.progress-bar {{ background: var(--border); border-radius: 6px; height: 10px; overflow: hidden; margin-top: 10px; }}
        \\.progress-fill {{ height: 100%; border-radius: 6px; }}
        \\table {{ width: 100%; border-collapse: collapse; margin-top: 12px; }}
        \\th, td {{ padding: 10px 12px; text-align: left; border-bottom: 1px solid var(--border); font-size: 13px; }}
        \\th {{ color: var(--muted); font-weight: 600; }}
        \\tr:hover {{ background: rgba(255,255,255,0.02); }}
        \\.core-grid {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(65px, 1fr)); gap: 8px; margin-top: 12px; }}
        \\.core-box {{ background: var(--bg); border: 1px solid var(--border); border-radius: 6px; padding: 6px; text-align: center; font-size: 11px; }}
        \\</style>
        \\</head>
        \\<body>
        \\<div class="header">
        \\  <div>
        \\    <div class="logo">◈ ZYPHOR SYSTEM OBSERVATORY</div>
        \\    <div style="color: var(--muted); font-size: 12px; margin-top: 4px;">Timestamp: {d} | High-Precision Hardware Diagnostics</div>
        \\  </div>
        \\  <div class="badge">HEALTH SCORE: {d}/100 [{s}]</div>
        \\</div>
        \\
        \\<div class="grid">
        \\  <div class="card">
        \\    <div class="card-title">CPU Compute Engine</div>
        \\    <div class="stat-huge" style="color: var(--accent);">{d:.1}%</div>
        \\    <div style="font-size: 13px; color: var(--muted);">{s}</div>
        \\    <div style="font-size: 13px; color: var(--muted); margin-top: 4px;">{d} Physical Cores / {d} Threads @ {d} MHz</div>
        \\    <div class="progress-bar"><div class="progress-fill" style="width: {d:.1}%; background: var(--accent);"></div></div>
        \\    <div class="core-grid">
    , .{
        ts,
        snap.health.overall_score,
        snap.health.status.asText(),
        snap.cpu.total_usage,
        snap.cpu.getModelName(),
        snap.cpu.physical_cores,
        snap.cpu.logical_cores,
        snap.cpu.frequency_mhz,
        snap.cpu.total_usage,
    });

    for (snap.cpu.core_usage, 0..) |c, c_idx| {
        try writer.print(
            \\      <div class="core-box">C{d:0>2}<br><strong>{d:.0}%</strong></div>
        , .{ c_idx, c });
    }

    try writer.print(
        \\    </div>
        \\  </div>
        \\
        \\  <div class="card">
        \\    <div class="card-title">Memory & Pagefile</div>
        \\    <div class="stat-huge" style="color: var(--secondary);">{d:.1}%</div>
        \\    <div style="font-size: 13px; color: var(--muted);">RAM Used: {d:.1} GB / {d:.1} GB</div>
        \\    <div style="font-size: 13px; color: var(--muted); margin-top: 4px;">Swap Space: {d:.1}% Used (Pressure: {s})</div>
        \\    <div class="progress-bar"><div class="progress-fill" style="width: {d:.1}%; background: var(--secondary);"></div></div>
        \\  </div>
        \\
        \\  <div class="card">
        \\    <div class="card-title">Subsystem I/O & Network</div>
        \\    <div style="display: flex; justify-content: space-between; margin-bottom: 12px;">
        \\      <div><span style="color: var(--muted); font-size: 12px;">NET RX:</span><br><strong style="color: var(--success);">{d:.2} MB/s</strong></div>
        \\      <div><span style="color: var(--muted); font-size: 12px;">NET TX:</span><br><strong style="color: var(--warning);">{d:.2} MB/s</strong></div>
        \\    </div>
        \\    <div style="display: flex; justify-content: space-between; border-top: 1px solid var(--border); padding-top: 12px;">
        \\      <div><span style="color: var(--muted); font-size: 12px;">DISK READ:</span><br><strong style="color: var(--secondary);">{d:.2} MB/s</strong></div>
        \\      <div><span style="color: var(--muted); font-size: 12px;">DISK WRITE:</span><br><strong style="color: var(--accent);">{d:.2} MB/s</strong></div>
        \\    </div>
        \\  </div>
        \\</div>
        \\
        \\<div class="card" style="margin-bottom: 24px;">
        \\  <div class="card-title">Top Active Processes</div>
        \\  <table>
        \\    <thead>
        \\      <tr><th>PID</th><th>PPID</th><th>Process Name</th><th>CPU%</th><th>RAM (MB)</th><th>Threads</th><th>State</th></tr>
        \\    </thead>
        \\    <tbody>
    , .{
        snap.memory.used_percent,
        used_ram_gb,
        total_ram_gb,
        snap.memory.swap_used_percent,
        snap.memory.pressure_level.asText(),
        snap.memory.used_percent,
        rx_mb,
        tx_mb,
        disk_r_mb,
        disk_w_mb,
    });

    const max_procs = @min(30, snap.top_processes.len);
    for (snap.top_processes[0..max_procs]) |p| {
        try writer.print(
            \\      <tr><td>{d}</td><td>{d}</td><td><strong>{s}</strong></td><td style="color: var(--accent);">{d:.1}%</td><td>{d}</td><td>{d}</td><td>{s}</td></tr>
        , .{
            p.pid,
            p.ppid,
            p.getName(),
            p.cpu_percent,
            p.memory_rss / (1024 * 1024),
            p.threads_count,
            p.state.asText(),
        });
    }

    try writer.writeAll(
        \\    </tbody>
        \\  </table>
        \\</div>
        \\</body>
        \\</html>
        \\
    );
}

pub fn saveHtmlSnapshotFile(allocator: std.mem.Allocator, snap: *const types.SystemSnapshot, custom_path: ?[]const u8) !void {
    var filename_buf: [128]u8 = undefined;
    const path = if (custom_path) |p| p else try std.fmt.bufPrint(&filename_buf, "zyphor-report-{d}.html", .{snap.timestamp_ms});

    _ = allocator;
    const file = try std.fs.cwd().createFile(path, .{});
    defer file.close();

    const file_writer = types.OutWriter{ .file = file };
    try printHtmlSnapshot(file_writer, snap);
    std.debug.print("✓ Standalone HTML Observatory report saved to: {s}\n", .{path});
}

test "JSON string escaping handles quotes, backslashes, and control characters" {
    var buf: [256]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buf);
    const writer = fbs.writer();

    try writeJsonEscapedString(writer, "Hello \"World\" \\ path\n");
    const result = fbs.getWritten();
    try std.testing.expectEqualStrings("\"Hello \\\"World\\\" \\\\ path\\n\"", result);

    var buf2: [256]u8 = undefined;
    var fbs2 = std.io.fixedBufferStream(&buf2);
    const writer2 = fbs2.writer();
    try writeJsonEscapedString(writer2, "line1\rline2\tend");
    try std.testing.expectEqualStrings("\"line1\\rline2\\tend\"", fbs2.getWritten());

    var buf3: [256]u8 = undefined;
    var fbs3 = std.io.fixedBufferStream(&buf3);
    const writer3 = fbs3.writer();
    try writeJsonEscapedString(writer3, "A\x01B");
    try std.testing.expectEqualStrings("\"A\\u0001B\"", fbs3.getWritten());
}
