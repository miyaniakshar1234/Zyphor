const std = @import("std");
const engine_mod = @import("core/engine.zig");
const cli_mod = @import("cli/cli.zig");

// Submodule imports for testing
pub const types = @import("core/types.zig");
pub const config = @import("core/config.zig");
pub const history = @import("core/history.zig");
pub const health = @import("alerts/health.zig");
pub const alerts = @import("alerts/engine.zig");
pub const process_mgr = @import("process/manager.zig");
pub const process_tree = @import("process/tree.zig");
pub const buffer = @import("ui/buffer.zig");
pub const theme = @import("ui/theme.zig");
pub const graphs = @import("ui/graphs.zig");
pub const widgets = @import("ui/widgets.zig");
pub const speedtest = @import("net/speedtest.zig");


pub fn main() !void {
    if (@import("builtin").os.tag == .windows) {
        const kernel32 = struct {
            extern "kernel32" fn SetConsoleOutputCP(wCodePageID: u32) callconv(.winapi) i32;
            extern "kernel32" fn SetConsoleCP(wCodePageID: u32) callconv(.winapi) i32;
        };
        _ = kernel32.SetConsoleOutputCP(65001);
        _ = kernel32.SetConsoleCP(65001);
    }

    const GPA = if (@hasDecl(std.heap, "GeneralPurposeAllocator"))
        std.heap.GeneralPurposeAllocator(.{})
    else
        std.heap.DebugAllocator(.{});

    var gpa = GPA{};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var engine = engine_mod.SystemEngine.init(allocator);
    defer engine.deinit();

    if (comptime @hasDecl(std.process, "argsAlloc")) {
        const parsed = try std.process.argsAlloc(allocator);
        defer std.process.argsFree(allocator, parsed);
        try cli_mod.run(allocator, &engine, parsed);
    } else if (comptime @hasDecl(std.process, "argsWithAllocator")) {
        var it = try std.process.argsWithAllocator(allocator);
        defer it.deinit();
        var args_list: std.ArrayList([]const u8) = .empty;
        defer args_list.deinit(allocator);
        while (it.next()) |a| try args_list.append(allocator, a);
        try cli_mod.run(allocator, &engine, args_list.items);
    } else {
        var it = std.process.args();
        var args_list: std.ArrayList([]const u8) = .empty;
        defer args_list.deinit(allocator);
        while (it.next()) |a| try args_list.append(allocator, a);
        try cli_mod.run(allocator, &engine, args_list.items);
    }
}

test "history ring buffer chronological ordering" {
    var ring = history.RingBuffer(f32, 5).init();
    ring.push(10.0);
    ring.push(20.0);
    ring.push(30.0);

    var out: [5]f32 = undefined;
    const count = ring.getChronological(&out);
    try std.testing.expectEqual(@as(usize, 3), count);
    try std.testing.expectEqual(@as(f32, 10.0), out[0]);
    try std.testing.expectEqual(@as(f32, 20.0), out[1]);
    try std.testing.expectEqual(@as(f32, 30.0), out[2]);
}

test "history ring buffer overflow wrapping" {
    var ring = history.RingBuffer(f32, 3).init();
    ring.push(1.0);
    ring.push(2.0);
    ring.push(3.0);
    ring.push(4.0); // overwrites 1.0

    var out: [3]f32 = undefined;
    const count = ring.getChronological(&out);
    try std.testing.expectEqual(@as(usize, 3), count);
    try std.testing.expectEqual(@as(f32, 2.0), out[0]);
    try std.testing.expectEqual(@as(f32, 3.0), out[1]);
    try std.testing.expectEqual(@as(f32, 4.0), out[2]);
}

test "health score computation nominal" {
    const cpu = types.CpuMetrics{ .total_usage = 10.0 };
    const mem = types.MemoryMetrics{ .used_percent = 40.0, .swap_used_percent = 0.0 };
    const disk = types.DiskMetrics{};
    const net = types.NetworkMetrics{};

    const h = health.computeHealthScore(&cpu, &mem, &disk, &net);
    try std.testing.expect(h.overall_score >= 90);
    try std.testing.expectEqual(types.HealthStatus.excellent, h.status);
}

test "health score degradation on high load" {
    const cpu = types.CpuMetrics{ .total_usage = 99.0 };
    const mem = types.MemoryMetrics{ .used_percent = 98.0, .swap_used_percent = 85.0, .pressure_level = .critical };
    const disk = types.DiskMetrics{};
    const net = types.NetworkMetrics{};

    const h = health.computeHealthScore(&cpu, &mem, &disk, &net);
    try std.testing.expect(h.overall_score < 60);
    try std.testing.expect(h.status == .fair or h.status == .poor or h.status == .critical);
}

test "process manager sorting by cpu" {
    const allocator = std.testing.allocator;
    var mgr = process_mgr.ProcessManager.init(allocator);
    defer mgr.deinit();

    const p1 = types.ProcessInfo{ .pid = 100, .cpu_percent = 5.0 };
    const p2 = types.ProcessInfo{ .pid = 200, .cpu_percent = 85.0 };
    const p3 = types.ProcessInfo{ .pid = 300, .cpu_percent = 25.0 };

    const procs = [_]types.ProcessInfo{ p1, p2, p3 };
    try mgr.update(&procs, null);

    try mgr.setSort(.cpu, .descending);
    try std.testing.expectEqual(@as(usize, 3), mgr.getFilteredCount());
    try std.testing.expectEqual(@as(u32, 200), (mgr.getProcessAt(0) orelse unreachable).pid);
    try std.testing.expectEqual(@as(u32, 300), (mgr.getProcessAt(1) orelse unreachable).pid);
    try std.testing.expectEqual(@as(u32, 100), (mgr.getProcessAt(2) orelse unreachable).pid);
}

test "process manager sorting by memory rss" {
    const allocator = std.testing.allocator;
    var mgr = process_mgr.ProcessManager.init(allocator);
    defer mgr.deinit();

    const p1 = types.ProcessInfo{ .pid = 10, .memory_rss = 1024 * 1024 * 50 };
    const p2 = types.ProcessInfo{ .pid = 20, .memory_rss = 1024 * 1024 * 500 };
    const p3 = types.ProcessInfo{ .pid = 30, .memory_rss = 1024 * 1024 * 120 };

    const procs = [_]types.ProcessInfo{ p1, p2, p3 };
    try mgr.update(&procs, null);

    try mgr.setSort(.memory, .descending);
    try std.testing.expectEqual(@as(u32, 20), (mgr.getProcessAt(0) orelse unreachable).pid);
    try std.testing.expectEqual(@as(u32, 30), (mgr.getProcessAt(1) orelse unreachable).pid);
    try std.testing.expectEqual(@as(u32, 10), (mgr.getProcessAt(2) orelse unreachable).pid);
}

test "process manager interactive filtering" {
    const allocator = std.testing.allocator;
    var mgr = process_mgr.ProcessManager.init(allocator);
    defer mgr.deinit();

    var p1 = types.ProcessInfo{ .pid = 1001, .cpu_percent = 5.0 };
    @memcpy(p1.name[0..6], "chrome");
    p1.name_len = 6;

    var p2 = types.ProcessInfo{ .pid = 2002, .cpu_percent = 15.0 };
    @memcpy(p2.name[0..4], "code");
    p2.name_len = 4;

    var p3 = types.ProcessInfo{ .pid = 3003, .cpu_percent = 2.0 };
    @memcpy(p3.name[0..11], "chrome_proc");
    p3.name_len = 11;

    const procs = [_]types.ProcessInfo{ p1, p2, p3 };
    try mgr.update(&procs, null);
    try std.testing.expectEqual(@as(usize, 3), mgr.getFilteredCount());

    // Filter by "chrome"
    try mgr.setFilter("chrome");
    try std.testing.expectEqual(@as(usize, 2), mgr.getFilteredCount());

    // Filter by PID "2002"
    try mgr.setFilter("2002");
    try std.testing.expectEqual(@as(usize, 1), mgr.getFilteredCount());
    try std.testing.expectEqual(@as(u32, 2002), (mgr.getProcessAt(0) orelse unreachable).pid);

    // Clear filter
    try mgr.setFilter(null);
    try std.testing.expectEqual(@as(usize, 3), mgr.getFilteredCount());
}

test "screen buffer cell equality" {
    const c1 = buffer.Cell{
        .char = .{ 'A', 0, 0, 0 },
        .char_len = 1,
        .fg = theme.Color.rgb(255, 0, 0),
        .bg = theme.Color.rgb(0, 0, 0),
    };
    const c2 = buffer.Cell{
        .char = .{ 'A', 0, 0, 0 },
        .char_len = 1,
        .fg = theme.Color.rgb(255, 0, 0),
        .bg = theme.Color.rgb(0, 0, 0),
    };
    const c3 = buffer.Cell{
        .char = .{ 'B', 0, 0, 0 },
        .char_len = 1,
        .fg = theme.Color.rgb(255, 0, 0),
        .bg = theme.Color.rgb(0, 0, 0),
    };

    try std.testing.expect(c1.eql(c2));
    try std.testing.expect(!c1.eql(c3));
}

test "graphs safeClampPct handles NaN, Inf, and negative values" {
    try std.testing.expectEqual(@as(f32, 0.0), graphs.safeClampPct(-10.0));
    try std.testing.expectEqual(@as(f32, 0.0), graphs.safeClampPct(std.math.nan(f32)));
    try std.testing.expectEqual(@as(f32, 0.0), graphs.safeClampPct(std.math.inf(f32)));
    try std.testing.expectEqual(@as(f32, 100.0), graphs.safeClampPct(150.0));
    try std.testing.expectEqual(@as(f32, 42.5), graphs.safeClampPct(42.5));
}

test "graphs renderGaugeBar handles extreme and boundary inputs" {
    const allocator = std.testing.allocator;
    var buf = try buffer.ScreenBuffer.init(allocator, 80, 24);
    defer buf.deinit();

    const t = theme.BuiltinThemes.anthropic;
    // 0%, 100%, >100%, <0%, NaN, Inf
    graphs.renderGaugeBar(&buf, 0, 0, 20, 0.0, t.accent, t.muted, t.bg, false);
    graphs.renderGaugeBar(&buf, 0, 1, 20, 100.0, t.accent, t.muted, t.bg, false);
    graphs.renderGaugeBar(&buf, 0, 2, 20, 999.0, t.accent, t.muted, t.bg, false);
    graphs.renderGaugeBar(&buf, 0, 3, 20, -50.0, t.accent, t.muted, t.bg, false);
    graphs.renderGaugeBar(&buf, 0, 4, 20, std.math.nan(f32), t.accent, t.muted, t.bg, false);
    graphs.renderGaugeBar(&buf, 0, 5, 20, std.math.inf(f32), t.accent, t.muted, t.bg, false);
    graphs.renderGaugeBar(&buf, 0, 6, 2, 50.0, t.accent, t.muted, t.bg, false); // tiny width
}

test "graphs renderBrailleGraph handles NaNs and extreme inputs without panic" {
    const allocator = std.testing.allocator;
    var buf = try buffer.ScreenBuffer.init(allocator, 40, 10);
    defer buf.deinit();

    const data = [_]f32{ 10.0, std.math.nan(f32), 85.0, std.math.inf(f32), -20.0, 120.0, 0.0 };
    graphs.renderBrailleGraph(&buf, 0, 0, 40, 5, &data, null, theme.Color.rgb(0, 0, 0), false);
    graphs.renderBrailleGraph(&buf, 0, 0, 40, 5, &data, null, theme.Color.rgb(0, 0, 0), true); // plain mode
    graphs.renderBrailleGraph(&buf, 0, 0, 0, 0, &data, null, theme.Color.rgb(0, 0, 0), false); // zero dims
    graphs.renderBrailleGraph(&buf, 0, 0, 40, 5, &[_]f32{}, null, theme.Color.rgb(0, 0, 0), false); // empty data
}

test "screen buffer clipping and out-of-bounds safety" {
    const allocator = std.testing.allocator;
    var buf = try buffer.ScreenBuffer.init(allocator, 10, 5);
    defer buf.deinit();

    // Coordinates out of bounds
    buf.setCell(100, 100, "X", theme.Color.rgb(255, 255, 255), theme.Color.rgb(0, 0, 0), false);
    buf.writeString(50, 50, "Hello World", theme.Color.rgb(255, 255, 255), theme.Color.rgb(0, 0, 0), false);
    buf.writeStringMax(8, 0, "Long String That Clips", 20, theme.Color.rgb(255, 255, 255), theme.Color.rgb(0, 0, 0), false);
    buf.fillRect(5, 2, 50, 50, theme.Color.rgb(0, 0, 0));
    buf.drawCyberBox(0, 0, 10, 5, "Very Long Title That Exceeds Box Width", theme.Color.rgb(255, 0, 0), theme.Color.rgb(0, 255, 0), theme.Color.rgb(0, 0, 0), false);
    buf.drawBox(0, 0, 10, 5, "Long Title", theme.Color.rgb(255, 0, 0), theme.Color.rgb(0, 255, 0), theme.Color.rgb(0, 0, 0), true);
}

test "process tree handles cyclic PPID loops gracefully" {
    const allocator = std.testing.allocator;
    var tree = process_tree.ProcessTree.init(allocator);
    defer tree.deinit();

    // Create cyclic processes: PID 10 -> PPID 20, PID 20 -> PPID 10
    const p1 = types.ProcessInfo{ .pid = 10, .ppid = 20, .cpu_percent = 10.0, .memory_rss = 1024 * 1024 * 100 };
    const p2 = types.ProcessInfo{ .pid = 20, .ppid = 10, .cpu_percent = 20.0, .memory_rss = 1024 * 1024 * 200 };
    const p3 = types.ProcessInfo{ .pid = 30, .ppid = 30, .cpu_percent = 5.0, .memory_rss = 1024 * 1024 * 50 }; // self-parent

    const procs = [_]types.ProcessInfo{ p1, p2, p3 };
    try tree.build(&procs);

    var flattened: std.ArrayList(types.ProcessInfo) = .empty;
    defer flattened.deinit(allocator);
    try tree.flatten(&flattened);

    // All 3 processes must be present in the flattened tree without infinite recursion
    try std.testing.expectEqual(@as(usize, 3), flattened.items.len);
}

test "process manager sorting with NaN cpu values preserves stability" {
    const allocator = std.testing.allocator;
    var mgr = process_mgr.ProcessManager.init(allocator);
    defer mgr.deinit();

    const p1 = types.ProcessInfo{ .pid = 1, .cpu_percent = std.math.nan(f32) };
    const p2 = types.ProcessInfo{ .pid = 2, .cpu_percent = 50.0 };
    const p3 = types.ProcessInfo{ .pid = 3, .cpu_percent = std.math.nan(f32) };
    const p4 = types.ProcessInfo{ .pid = 4, .cpu_percent = 90.0 };

    const procs = [_]types.ProcessInfo{ p1, p2, p3, p4 };
    try mgr.update(&procs, null);

    try mgr.setSort(.cpu, .descending);
    try std.testing.expectEqual(@as(usize, 4), mgr.getFilteredCount());
    try std.testing.expectEqual(@as(u32, 4), (mgr.getProcessAt(0) orelse unreachable).pid);
    try std.testing.expectEqual(@as(u32, 2), (mgr.getProcessAt(1) orelse unreachable).pid);
}

test "health computation with NaN and Inf metrics remains stable" {
    const cpu = types.CpuMetrics{ .total_usage = std.math.nan(f32) };
    const mem = types.MemoryMetrics{ .used_percent = std.math.inf(f32), .swap_used_percent = std.math.nan(f32) };
    const disk = types.DiskMetrics{};
    const net = types.NetworkMetrics{};

    const h = health.computeHealthScore(&cpu, &mem, &disk, &net);
    try std.testing.expect(h.overall_score <= 100);
}

test "flight recorder ring buffer 60-frame overflow wrapping" {
    var recorder = engine_mod.FlightRecorder{};
    try std.testing.expectEqual(@as(usize, 0), recorder.count);

    // Record 100 snapshots (exceeds 60-frame capacity)
    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const snap = types.SystemSnapshot{ .timestamp_ms = @as(i64, @intCast(i * 1000)) };
        recorder.record(snap);
    }

    try std.testing.expectEqual(@as(usize, 60), recorder.count);
    // Index 0 back should be the latest snapshot (99)
    const latest = recorder.getFrame(0) orelse unreachable;
    try std.testing.expectEqual(@as(i64, 99000), latest.timestamp_ms);

    // Index 59 back should be the oldest snapshot in buffer (40)
    const oldest = recorder.getFrame(59) orelse unreachable;
    try std.testing.expectEqual(@as(i64, 40000), oldest.timestamp_ms);

    // Out of bounds index should return null safely
    try std.testing.expect(recorder.getFrame(60) == null);
    try std.testing.expect(recorder.getFrame(999) == null);
}

test "json snapshot serialization handles extreme and boundary values" {
    const allocator = std.testing.allocator;
    const snap = types.SystemSnapshot{
        .timestamp_ms = 1788000000000,
        .is_admin = true,
        .cpu = .{ .total_usage = 100.0, .frequency_mhz = 5800 },
        .memory = .{ .total_bytes = 64 * 1024 * 1024 * 1024, .used_bytes = 32 * 1024 * 1024 * 1024 },
        .gpu = .{ .utilization_pct = 99.5, .vram_total_bytes = 16 * 1024 * 1024 * 1024, .vram_used_bytes = 12 * 1024 * 1024 * 1024 },
    };

    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(allocator);

    const export_mod = @import("cli/export.zig");
    try export_mod.printJsonSnapshot(list.writer(allocator), &snap);
    try std.testing.expect(list.items.len > 100);
}

test "html snapshot serialization generates well-formed diagnostics page" {
    const allocator = std.testing.allocator;
    const snap = types.SystemSnapshot{
        .timestamp_ms = 1788000000000,
        .is_admin = false,
        .cpu = .{ .total_usage = 42.0, .physical_cores = 8, .logical_cores = 16 },
    };

    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(allocator);

    const export_mod = @import("cli/export.zig");
    try export_mod.printHtmlSnapshot(list.writer(allocator), &snap);
    try std.testing.expect(list.items.len > 500);
    try std.testing.expect(std.mem.indexOf(u8, list.items, "Akshar Miyani") != null);
}

test "HTML string escaping handles XSS characters correctly" {
    const allocator = std.testing.allocator;
    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(allocator);

    const export_mod = @import("cli/export.zig");
    try export_mod.writeHtmlEscapedString(list.writer(allocator), "<div>\"Dangerous & Malicious\"</div>");
    try std.testing.expectEqualStrings("&lt;div&gt;&quot;Dangerous &amp; Malicious&quot;&lt;/div&gt;", list.items);
}

test "compact overview panel renders on narrow buffers without crashing" {
    const allocator = std.testing.allocator;
    var buf = try buffer.ScreenBuffer.init(allocator, 30, 15);
    defer buf.deinit();

    const t = theme.BuiltinThemes.anthropic;
    const snap = types.SystemSnapshot{
        .timestamp_ms = 1788000000000,
        .cpu = .{ .total_usage = 75.0 },
        .memory = .{ .used_percent = 60.0 },
    };

    widgets.renderCompactOverviewPanel(&buf, &snap, &t, false);
    widgets.renderCompactOverviewPanel(&buf, &snap, &t, true); // plain mode
}

test "doctor and bench print formatting functions remain stable" {
    const bench_mod = @import("cli/bench.zig");
    const res = bench_mod.BenchmarkResult{
        .cpu_single_mops = 450.5,
        .cpu_multi_gflops = 85.2,
        .ram_seq_read_gb_s = 48.5,
        .ram_seq_write_gb_s = 32.1,
        .ram_latency_ns = 58.4,
        .composite_index = 28500,
    };

    const allocator = std.testing.allocator;
    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(allocator);

    try bench_mod.printBenchmark(list.writer(allocator), &res, false);
    try std.testing.expect(list.items.len > 100);

    list.clearRetainingCapacity();
    try bench_mod.printBenchmark(list.writer(allocator), &res, true); // JSON mode
    try std.testing.expect(list.items.len > 50);
}






