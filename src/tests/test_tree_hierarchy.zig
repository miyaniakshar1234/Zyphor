const std = @import("std");
const types = @import("../core/types.zig");
const tree_mod = @import("../process/tree.zig");

test "ProcessTree child hierarchy and depth" {
    const allocator = std.testing.allocator;
    var tree = tree_mod.ProcessTree.init(allocator);
    defer tree.deinit();

    const procs = [_]types.ProcessInfo{
        .{ .pid = 1, .ppid = 0, .cpu_percent = 1.0 },
        .{ .pid = 10, .ppid = 1, .cpu_percent = 2.0 },
        .{ .pid = 100, .ppid = 10, .cpu_percent = 3.0 },
    };

    try tree.buildTree(&procs);
    try std.testing.expectEqual(@as(usize, 3), tree.flattened.items.len);
    try std.testing.expectEqual(@as(u16, 0), tree.flattened.items[0].tree_depth);
    try std.testing.expectEqual(@as(u16, 1), tree.flattened.items[1].tree_depth);
    try std.testing.expectEqual(@as(u16, 2), tree.flattened.items[2].tree_depth);
}
