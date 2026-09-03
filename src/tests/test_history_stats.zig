const std = @import("std");
const history = @import("../core/history.zig");

test "RingBuffer minMaxAvg calculation" {
    var ring = history.RingBuffer(f32, 10).init();
    ring.push(10.0);
    ring.push(20.0);
    ring.push(30.0);

    const stats = ring.minMaxAvg();
    try std.testing.expectEqual(@as(f32, 10.0), stats.min);
    try std.testing.expectEqual(@as(f32, 30.0), stats.max);
    try std.testing.expectEqual(@as(f32, 20.0), stats.avg);
}
