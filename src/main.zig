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

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var engine = engine_mod.SystemEngine.init(allocator);
    defer engine.deinit();

    try cli_mod.run(allocator, &engine);
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

test "health score computation" {
    const cpu = types.CpuMetrics{ .total_usage = 10.0 };
    const mem = types.MemoryMetrics{ .used_percent = 40.0, .swap_used_percent = 0.0 };
    const disk = types.DiskMetrics{};
    const net = types.NetworkMetrics{};

    const h = health.computeHealthScore(&cpu, &mem, &disk, &net);
    try std.testing.expect(h.overall_score >= 90);
    try std.testing.expectEqual(types.HealthStatus.excellent, h.status);
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
