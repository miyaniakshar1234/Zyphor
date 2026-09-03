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

    try tree.build(&procs);
    try std.testing.expectEqual(@as(usize, 1), tree.roots.items.len);
    try std.testing.expectEqual(@as(usize, 0), tree.roots.items[0].depth);
    try std.testing.expectEqual(@as(usize, 1), tree.roots.items[0].children.items.len);
    try std.testing.expectEqual(@as(usize, 1), tree.roots.items[0].children.items[0].depth);
}
