const std = @import("std");
const types = @import("../core/types.zig");
const manager_mod = @import("../process/manager.zig");

test "ProcessManager CPU and Memory sorting stability" {
    const allocator = std.testing.allocator;
    var mgr = manager_mod.ProcessManager.init(allocator);
    defer mgr.deinit();

    const procs = [_]types.ProcessInfo{
        .{ .pid = 10, .cpu_percent = 15.0, .memory_rss = 100 },
        .{ .pid = 20, .cpu_percent = 85.0, .memory_rss = 50 },
        .{ .pid = 30, .cpu_percent = 5.0, .memory_rss = 500 },
    };

    try mgr.update(&procs, null);
    try mgr.setSort(.cpu, .descending);
    const top_cpu = mgr.getProcessAt(0);
    try std.testing.expect(top_cpu != null);
    try std.testing.expectEqual(@as(u32, 20), top_cpu.?.pid);

    try mgr.setSort(.memory, .descending);
    const top_mem = mgr.getProcessAt(0);
    try std.testing.expect(top_mem != null);
    try std.testing.expectEqual(@as(u32, 30), top_mem.?.pid);
}
