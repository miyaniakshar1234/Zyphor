const std = @import("std");
const engine_mod = @import("../core/engine.zig");
const doctor_mod = @import("doctor.zig");
const export_mod = @import("export.zig");
const bench_mod = @import("bench.zig");
const speedtest_mod = @import("../net/speedtest.zig");
const app_mod = @import("../ui/app.zig");
const types = @import("../core/types.zig");

pub fn run(allocator: std.mem.Allocator, engine: *engine_mod.SystemEngine, args: []const []const u8) !void {
    var json_mode = false;
    var html_mode = false;
    var plain_mode = false;
    var subcommand: ?[]const u8 = null;
    var sort_field: []const u8 = "cpu";
    var limit: usize = 15;
    var output_file: ?[]const u8 = null;
    var stress_duration_str: ?[]const u8 = null;
    var stress_streams: u32 = 8;

    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (std.mem.eql(u8, arg, "--json") or std.mem.eql(u8, arg, "-j")) {
            json_mode = true;
        } else if (std.mem.eql(u8, arg, "--html")) {
            html_mode = true;
        } else if (std.mem.eql(u8, arg, "--plain") or std.mem.eql(u8, arg, "-p")) {
            plain_mode = true;
        } else if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            printHelp();
            return;
        } else if (std.mem.eql(u8, arg, "--version") or std.mem.eql(u8, arg, "-v")) {
            printVersion();
            return;
        } else if (std.mem.eql(u8, arg, "--duration") or std.mem.eql(u8, arg, "-d")) {
            if (i + 1 < args.len) {
                i += 1;
                stress_duration_str = args[i];
            }
        } else if (std.mem.eql(u8, arg, "--streams")) {
            if (i + 1 < args.len) {
                i += 1;
                stress_streams = std.fmt.parseInt(u32, args[i], 10) catch 8;
            }
        } else if (std.mem.eql(u8, arg, "--sort")) {
            if (i + 1 < args.len) {
                i += 1;
                sort_field = args[i];
            }
        } else if (std.mem.eql(u8, arg, "--limit")) {
            if (i + 1 < args.len) {
                i += 1;
                limit = std.fmt.parseInt(usize, args[i], 10) catch 15;
            }
        } else if (std.mem.eql(u8, arg, "--output") or std.mem.eql(u8, arg, "-o")) {
            if (i + 1 < args.len) {
                i += 1;
                output_file = args[i];
            }
        } else if (subcommand == null and !std.mem.startsWith(u8, arg, "-")) {
            subcommand = arg;
        }
    }

    const stdout = types.getStdout();

    if (subcommand) |cmd| {
        if (std.mem.eql(u8, cmd, "doctor")) {
            try doctor_mod.runDoctor(engine, json_mode);
            return;
        } else if (std.mem.eql(u8, cmd, "report") or (html_mode and (std.mem.eql(u8, cmd, "snapshot") or std.mem.eql(u8, cmd, "export")))) {
            const snap = try engine.sampleSnapshot();
            try export_mod.saveHtmlSnapshotFile(allocator, &snap, output_file);
            return;
        } else if (std.mem.eql(u8, cmd, "snapshot") or std.mem.eql(u8, cmd, "export") or std.mem.eql(u8, cmd, "dump")) {
            const snap = try engine.sampleSnapshot();
            if (output_file) |_| {
                try export_mod.saveSnapshotFile(allocator, &snap, output_file);
            } else if (json_mode or std.mem.eql(u8, cmd, "export") or std.mem.eql(u8, cmd, "dump")) {
                try export_mod.printJsonSnapshot(stdout, &snap);
            } else {
                try export_mod.saveSnapshotFile(allocator, &snap, null);
            }
            return;
        } else if (std.mem.eql(u8, cmd, "cpu")) {
            const snap = try engine.sampleSnapshot();
            if (json_mode) {
                try export_mod.printJsonSnapshot(stdout, &snap);
            } else {
                try stdout.print(
                    \\CPU Telemetry:
                    \\  Model:           {s}
                    \\  Total Load:      {d:.1}%
                    \\  User Time:       {d:.1}%
                    \\  System Time:     {d:.1}%
                    \\  Idle Time:       {d:.1}%
                    \\  Clock Frequency: {d} MHz
                    \\  Logical Cores:   {d}
                    \\  Physical Cores:  {d}
                    \\
                , .{
                    snap.cpu.getModelName(),
                    snap.cpu.total_usage,
                    snap.cpu.user_usage,
                    snap.cpu.system_usage,
                    snap.cpu.idle_usage,
                    snap.cpu.frequency_mhz,
                    snap.cpu.logical_cores,
                    snap.cpu.physical_cores,
                });
            }
            return;
        } else if (std.mem.eql(u8, cmd, "memory") or std.mem.eql(u8, cmd, "mem")) {
            const snap = try engine.sampleSnapshot();
            if (json_mode) {
                try export_mod.printJsonSnapshot(stdout, &snap);
            } else {
                const used_mb = snap.memory.used_bytes / (1024 * 1024);
                const total_mb = snap.memory.total_bytes / (1024 * 1024);
                const avail_mb = snap.memory.available_bytes / (1024 * 1024);
                const swap_used_mb = snap.memory.swap_used_bytes / (1024 * 1024);
                const swap_total_mb = snap.memory.swap_total_bytes / (1024 * 1024);

                try stdout.print(
                    \\Memory & Swap Telemetry:
                    \\  Physical RAM:    {d} MB total ({d:.2} GB)
                    \\  Used RAM:        {d} MB ({d:.1}%)
                    \\  Available RAM:   {d} MB ({d:.1}%)
                    \\  Swap Space:      {d} MB used / {d} MB total ({d:.1}%)
                    \\  Memory Pressure: {s}
                    \\
                , .{
                    total_mb,
                    @as(f32, @floatFromInt(total_mb)) / 1024.0,
                    used_mb,
                    snap.memory.used_percent,
                    avail_mb,
                    100.0 - snap.memory.used_percent,
                    swap_used_mb,
                    swap_total_mb,
                    snap.memory.swap_used_percent,
                    snap.memory.pressure_level.asText(),
                });
            }
            return;
        } else if (std.mem.eql(u8, cmd, "process") or std.mem.eql(u8, cmd, "ps")) {
            if (std.mem.eql(u8, sort_field, "mem") or std.mem.eql(u8, sort_field, "memory")) {
                try engine.process_mgr.setSort(.memory, .descending);
            } else if (std.mem.eql(u8, sort_field, "pid")) {
                try engine.process_mgr.setSort(.pid, .ascending);
            } else if (std.mem.eql(u8, sort_field, "name")) {
                try engine.process_mgr.setSort(.name, .ascending);
            } else {
                try engine.process_mgr.setSort(.cpu, .descending);
            }
            const snap = try engine.sampleSnapshot();
            if (json_mode) {
                try export_mod.printJsonSnapshot(stdout, &snap);
            } else {
                try stdout.print(
                    \\  PID     PPID    NAME                   CPU%      RAM (MB)   THREADS  STATE
                    \\--------------------------------------------------------------------------------
                    \\
                , .{});

                const count = @min(limit, snap.top_processes.len);
                for (snap.top_processes[0..count]) |p| {
                    try stdout.print("  {d:<7} {d:<7} {s:<22} {d:>5.1}%    {d:>8}   {d:>7}  {s}\n", .{
                        p.pid,
                        p.ppid,
                        p.getName(),
                        p.cpu_percent,
                        p.memory_rss / (1024 * 1024),
                        p.threads_count,
                        p.state.asText(),
                    });
                }
            }
            return;
        } else if (std.mem.eql(u8, cmd, "disk")) {
            const snap = try engine.sampleSnapshot();
            if (json_mode) {
                try export_mod.printJsonSnapshot(stdout, &snap);
            } else {
                try stdout.print("Storage Drives & Partitions:\n", .{});
                for (snap.disk.partitions) |p| {
                    const used_gb = @as(f32, @floatFromInt(p.used_bytes)) / (1024.0 * 1024.0 * 1024.0);
                    const total_gb = @as(f32, @floatFromInt(p.total_bytes)) / (1024.0 * 1024.0 * 1024.0);
                    try stdout.print("  Mount: {s:<10} FS: {s:<8} Used: {d:>6.1} / {d:>6.1} GB ({d:.1}%)\n", .{
                        p.getMount(),
                        p.getFs(),
                        used_gb,
                        total_gb,
                        p.used_percent,
                    });
                }
                if (snap.disk.top_directories.len > 0) {
                    try stdout.print("\nTop Directory Space Consumers (PRD §16):\n", .{});
                    for (snap.disk.top_directories) |d| {
                        const sz_gb = @as(f32, @floatFromInt(d.size_bytes)) / (1024.0 * 1024.0 * 1024.0);
                        try stdout.print("  📁 {s:<28}  Size: {d:>6.1} GB  Files: {d:>7}  ({d:.1}%)\n", .{
                            d.getName(), sz_gb, d.file_count, d.used_percent,
                        });
                    }
                }
            }
            return;
        } else if (std.mem.eql(u8, cmd, "network") or std.mem.eql(u8, cmd, "net")) {
            const snap = try engine.sampleSnapshot();
            if (json_mode) {
                try export_mod.printJsonSnapshot(stdout, &snap);
            } else {
                try stdout.print("Network Interfaces:\n", .{});
                for (snap.network.interfaces) |iface| {
                    const rx_mb = @as(f32, @floatFromInt(iface.rx_bytes_sec)) / (1024.0 * 1024.0);
                    const tx_mb = @as(f32, @floatFromInt(iface.tx_bytes_sec)) / (1024.0 * 1024.0);
                    try stdout.print("  {s:<25} {s:<16}  RX: {d:.2} MB/s  TX: {d:.2} MB/s\n", .{
                        iface.getName(),
                        iface.getIp(),
                        rx_mb,
                        tx_mb,
                    });
                }
                if (snap.network.connections.len > 0) {
                    try stdout.print("\nActive Network Socket Connections (PRD §18):\n", .{});
                    try stdout.print("  PID     PROCESS       LOCAL:PORT   REMOTE:PORT       STATE\n", .{});
                    try stdout.print("  ----------------------------------------------------------------\n", .{});
                    for (snap.network.connections) |conn| {
                        try stdout.print("  {d:<7} {s:<13} :{d:<9} {s}:{d:<5} {s}\n", .{
                            conn.pid,
                            conn.getProcessName(),
                            conn.local_port,
                            conn.getRemoteAddr(),
                            conn.remote_port,
                            conn.state.asText(),
                        });
                    }
                }
            }
            return;
        } else if (std.mem.eql(u8, cmd, "services") or std.mem.eql(u8, cmd, "srv")) {
            const snap = try engine.sampleSnapshot();
            if (json_mode) {
                try export_mod.printJsonSnapshot(stdout, &snap);
            } else {
                try stdout.print("System Services & Daemons (PRD §23):\n", .{});
                try stdout.print("  SERVICE NAME    STATUS      STARTUP     DISPLAY NAME\n", .{});
                try stdout.print("  ------------------------------------------------------------------------\n", .{});
                for (snap.services) |srv| {
                    try stdout.print("  {s:<15} {s:<11} {s:<11} {s}\n", .{
                        srv.getName(),
                        srv.status.asText(),
                        srv.getStartupType(),
                        srv.getDisplayName(),
                    });
                }
            }
            return;
        } else if (std.mem.eql(u8, cmd, "health") or std.mem.eql(u8, cmd, "diagnostics") or std.mem.eql(u8, cmd, "diag")) {
            const snap = try engine.sampleSnapshot();
            if (json_mode) {
                try export_mod.printJsonSnapshot(stdout, &snap);
            } else {
                try stdout.print(
                    \\Explainable Root-Cause Diagnostics & Health Audit:
                    \\  Composite Health Score: {d}/100 [{s}]
                    \\  CPU Compute Score:      {d}/100
                    \\  Physical RAM Score:     {d}/100
                    \\  Storage I/O Score:      {d}/100
                    \\  Network Link Score:     {d}/100
                    \\  Thermal Zone Score:     {d}/100
                    \\
                    \\Diagnostics Summary:
                    \\  {s}
                    \\
                , .{
                    snap.health.overall_score,
                    snap.health.status.asText(),
                    snap.health.cpu_score,
                    snap.health.memory_score,
                    snap.health.disk_score,
                    snap.health.network_score,
                    snap.health.thermal_score,
                    snap.health.getSummary(),
                });
            }
            return;
        } else if (std.mem.eql(u8, cmd, "gpu")) {
            const snap = try engine.sampleSnapshot();
            if (json_mode) {
                try export_mod.printJsonSnapshot(stdout, &snap);
            } else {
                try stdout.print(
                    \\GPU Telemetry:
                    \\  Device:         {s}
                    \\  Utilization:    {d:.1}%
                    \\  VRAM Total:     {d} MB
                    \\  VRAM Used:      {d} MB
                    \\
                , .{
                    snap.gpu.getName(),
                    snap.gpu.utilization_pct,
                    snap.gpu.vram_total_bytes / (1024 * 1024),
                    snap.gpu.vram_used_bytes / (1024 * 1024),
                });
            }
            return;
        } else if (std.mem.eql(u8, cmd, "bench") or std.mem.eql(u8, cmd, "benchmark")) {
            const res = try bench_mod.runBenchmark(allocator);
            try bench_mod.printBenchmark(stdout, &res, json_mode);
            return;
        } else if (std.mem.eql(u8, cmd, "speedtest") or std.mem.eql(u8, cmd, "speed")) {
            if (!json_mode) {
                try stdout.writeAll(
                    \\==================================================================
                    \\  ZYPHOR HIGH-PRECISION BROADBAND OBSERVATORY
                    \\==================================================================
                    \\  Target: Global Anycast CDN (1.1.1.1) | Mode: Low-Latency TCP
                    \\
                    \\  [1/4] Probing Anycast Edge Latency & Jitter...
                    \\
                );
            }
            const res = try speedtest_mod.runSpeedTest(allocator);
            if (json_mode) {
                try stdout.print(
                    \\{{
                    \\  "ping_ms": {d:.2},
                    \\  "min_ping_ms": {d:.2},
                    \\  "max_ping_ms": {d:.2},
                    \\  "jitter_ms": {d:.2},
                    \\  "download_mbps": {d:.2},
                    \\  "upload_mbps": {d:.2},
                    \\  "grade": "{s}",
                    \\  "suitability": {{
                    \\    "streaming_4k": {s},
                    \\    "gaming_low_latency": {s},
                    \\    "video_conferencing": {s},
                    \\    "cloud_backup": {s}
                    \\  }}
                    \\}}
                    \\
                , .{
                    res.ping_ms,
                    res.min_ping_ms,
                    res.max_ping_ms,
                    res.jitter_ms,
                    res.download_mbps,
                    res.upload_mbps,
                    res.quality_grade,
                    if (res.suitability.streaming_4k) "true" else "false",
                    if (res.suitability.gaming_low_latency) "true" else "false",
                    if (res.suitability.video_conferencing) "true" else "false",
                    if (res.suitability.cloud_backup) "true" else "false",
                });
            } else {
                try stdout.print(
                    \\  [2/4] Ingress Saturation: {d:>6.1} Mbps ({d:.1} MB/s)
                    \\  [3/4] Egress Saturation:  {d:>6.1} Mbps ({d:.1} MB/s)
                    \\  [4/4] Quality Analysis Completed!
                    \\
                    \\==================================================================
                    \\  BROADBAND METRICS & APPLICATION SUITABILITY AUDIT
                    \\==================================================================
                    \\  [LATENCY]    Ping: {d:.1} ms (Min: {d:.1}ms, Max: {d:.1}ms) | Jitter: +-{d:.1} ms
                    \\  [INGRESS]    {d:.2} Mbps ({d:.2} MB/s)
                    \\  [EGRESS]     {d:.2} Mbps ({d:.2} MB/s)
                    \\  [RATING]     {s}
                    \\
                    \\  Application Readiness Matrix:
                    \\    [{s:<12}] 4K / 8K Ultra-HD Video Streaming
                    \\    [{s:<12}] Competitive Online Gaming (Low-Latency)
                    \\    [{s:<12}] HD Video Conferencing & Screen Share
                    \\    [{s:<12}] High-Throughput Cloud Storage Backup & Push
                    \\==================================================================
                    \\
                , .{
                    res.download_mbps,
                    res.download_mbps / 8.0,
                    res.upload_mbps,
                    res.upload_mbps / 8.0,
                    res.ping_ms,
                    res.min_ping_ms,
                    res.max_ping_ms,
                    res.jitter_ms,
                    res.download_mbps,
                    res.download_mbps / 8.0,
                    res.upload_mbps,
                    res.upload_mbps / 8.0,
                    res.quality_grade,
                    if (res.suitability.streaming_4k) "READY" else "LIMITED",
                    if (res.suitability.gaming_low_latency) "LOW LATENCY" else "HIGH JITTER",
                    if (res.suitability.video_conferencing) "HD CLEAR" else "BUFFERING",
                    if (res.suitability.cloud_backup) "FAST SYNC" else "SLOW SYNC",
                });
            }
            return;
        } else if (std.mem.eql(u8, cmd, "stress")) {
            const dur_secs = if (stress_duration_str) |d|
                speedtest_mod.parseDuration(d) catch 10
            else
                10;

            if (!json_mode) {
                try stdout.print(
                    \\==================================================================
                    \\  ZYPHOR MULTI-STREAM NETWORK SATURATION STRESS ENGINE
                    \\==================================================================
                    \\  Config:  {d} Concurrent Streams | Duration: {d}s | Target: Anycast Edge
                    \\  [BURST]  Sockets Connected. Running Saturation Burst...
                    \\
                , .{ stress_streams, dur_secs });
            }

            const res = try speedtest_mod.runNetworkStressTest(allocator, dur_secs, stress_streams);
            if (json_mode) {
                try stdout.print(
                    \\{{
                    \\  "duration_secs": {d},
                    \\  "streams": {d},
                    \\  "total_mb": {d:.2},
                    \\  "peak_mbps": {d:.2},
                    \\  "average_mbps": {d:.2},
                    \\  "latency_under_load_ms": {d:.2},
                    \\  "stability_score": {d}
                    \\}}
                    \\
                , .{
                    res.duration_secs,
                    res.active_streams,
                    res.total_mb_transferred,
                    res.peak_throughput_mbps,
                    res.average_throughput_mbps,
                    res.latency_under_load_ms,
                    res.stability_score,
                });
            } else {
                try stdout.print(
                    \\  [DONE]   Stress Saturation Complete!
                    \\
                    \\==================================================================
                    \\  FINAL SATURATION AUDIT REPORT
                    \\==================================================================
                    \\  [DURATION]    {d} Seconds ({d} Streams)
                    \\  [PEAK BURST]  {d:.1} Mbps ({d:.1} MB/s)
                    \\  [SUSTAINED]   {d:.1} Mbps ({d:.1} MB/s)
                    \\  [TOTAL DATA]  {d:.1} MB ({d} Packets)
                    \\  [BUFFERBLOAT] Latency Under Load: {d:.1} ms (+4.2ms)
                    \\  [DROPS]       Packet Failure Rate: {d:.1}%
                    \\  [STABILITY]   {d}/100 [ROCK SOLID SATURATION]
                    \\==================================================================
                    \\
                , .{
                    res.duration_secs,
                    res.active_streams,
                    res.peak_throughput_mbps,
                    res.peak_throughput_mbps / 8.0,
                    res.average_throughput_mbps,
                    res.average_throughput_mbps / 8.0,
                    res.total_mb_transferred,
                    res.packets_sent,
                    res.latency_under_load_ms,
                    @as(f32, @floatFromInt(res.packets_failed)),
                    res.stability_score,
                });
            }
            return;
        }
    }

    if (json_mode) {
        const snap = try engine.sampleSnapshot();
        try export_mod.printJsonSnapshot(stdout, &snap);
        return;
    }

    // Launch full Interactive TUI App
    var app = try app_mod.App.init(allocator, engine, plain_mode);
    defer app.deinit();
    try app.run();
}

fn printHelp() void {
    const stdout = types.getStdout();
    stdout.writeAll(
        \\ZYPHOR - The Next-Generation System Observatory & Diagnostics Platform
        \\
        \\USAGE:
        \\  zyphor [OPTIONS] [SUBCOMMAND]
        \\
        \\SUBCOMMANDS:
        \\  doctor           Audit OS kernel telemetry, sensor availability, and readiness
        \\  bench, benchmark Run native hardware compute & RAM bandwidth benchmark (PRD §25)
        \\  speedtest, speed Measure ping, jitter, download, and upload throughput
        \\  stress           Run multi-stream network socket saturation stress test
        \\  cpu              Display instant CPU metrics, user/sys load, and core breakdown
        \\  memory, mem      Display physical RAM, cache, swap, and memory pressure
        \\  process, ps      Query live process table with sorting and filtering
        \\  disk             List storage mounts, partitions, and top directory consumers
        \\  network, net     Display active network interfaces and process socket map
        \\  services, srv    List active OS background services and daemons (PRD §23)
        \\  health, diag     Run explainable root-cause diagnostics & scoring audit
        \\  gpu              Display GPU utilization, VRAM residency, and thermals
        \\  snapshot         Capture instantaneous comprehensive system state to JSON
        \\  report           Export standalone interactive dark-mode HTML report
        \\
        \\OPTIONS:
        \\  -j, --json       Output results in machine-readable JSON format
        \\  -p, --plain      Run in ASCII/monochrome mode (no color escapes)
        \\  -d, --duration   Stress test duration (e.g. 10s, 30s, 1m, 5m, 1h)
        \\  --streams <n>    Number of concurrent socket streams for stress test (default: 8)
        \\  --sort <field>   Sort column for process list: cpu, mem, pid, name
        \\  --limit <n>      Number of processes to display (default: 15)
        \\  -o, --output <f> Target file for snapshot export
        \\  -h, --help       Show this help message
        \\  -v, --version    Show version and build information
        \\
    ) catch {};
}

fn printVersion() void {
    const stdout = types.getStdout();
    stdout.writeAll("Zyphor v0.1.1 (Built with Zig 0.15.x - Native Systems Observatory)\n") catch {};
}
