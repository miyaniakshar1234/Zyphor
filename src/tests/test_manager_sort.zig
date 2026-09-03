const std = @import("std");
const types = @import("../core/types.zig");
const manager_mod = @import("../process/manager.zig");

test "ProcessManager CPU and Memory sorting stability" {
    const allocator = std.testing.allocator;
    var mgr = manager_mod.ProcessManager.init(allocator);
    defer mgr.deinit();

    const procs = [_]types.ProcessInfo{
        .{ .pid = 10, .cpu_percent = 15.0, .memory_rss_bytes = 100 },
        .{ .pid = 20, .cpu_percent = 85.0, .memory_rss_bytes = 50 },
        .{ .pid = 30, .cpu_percent = 5.0, .memory_rss_bytes = 500 },
    };

    try mgr.updateProcesses(&procs);
    mgr.setSortField(.cpu);
    const sorted_cpu = mgr.getProcesses();
    try std.testing.expectEqual(@as(u32, 20), sorted_cpu[0].pid);

    mgr.setSortField(.memory);
    const sorted_mem = mgr.getProcesses();
    try std.testing.expectEqual(@as(u32, 30), sorted_mem[0].pid);
}
