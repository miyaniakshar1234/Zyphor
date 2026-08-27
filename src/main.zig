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

fn mainOld() !void {
    const GPA = if (@hasDecl(std.heap, "GeneralPurposeAllocator"))
        std.heap.GeneralPurposeAllocator(.{})
    else
        std.heap.DebugAllocator(.{});

    var gpa = GPA{};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var engine = engine_mod.SystemEngine.init(allocator);
    defer engine.deinit();

    var args_list: std.ArrayList([]const u8) = .empty;
    defer args_list.deinit(allocator);

    if (comptime @hasDecl(std.process, "argsAlloc")) {
        const parsed = try std.process.argsAlloc(allocator);
        defer std.process.argsFree(allocator, parsed);
        for (parsed) |a| try args_list.append(allocator, a);
    } else if (comptime @hasDecl(std.process, "argsWithAllocator")) {
        var it = try std.process.argsWithAllocator(allocator);
        defer it.deinit();
        while (it.next()) |a| try args_list.append(allocator, a);
    } else if (comptime @hasDecl(std.process, "args")) {
        var it = std.process.args();
        while (it.next()) |a| try args_list.append(allocator, a);
    }

    try cli_mod.run(allocator, &engine, args_list.items);
}

fn mainNew(init: if (@hasDecl(std.process, "Init")) std.process.Init else void) !void {
    if (comptime @hasDecl(std.process, "Init")) {
        const info = @typeInfo(std.process.Init).Struct;
        var msg: []const u8 = "Init fields: ";
        for (info.fields) |f| {
            msg = msg ++ f.name ++ ", ";
        }
        @compileError(msg);
    }
}

pub const main = if (@hasDecl(std.process, "Init")) mainNew else mainOld;

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
