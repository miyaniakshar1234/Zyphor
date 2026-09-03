const std = @import("std");
const history = @import("../core/history.zig");

test "RingBuffer capacity push wrapping" {
    var ring = history.RingBuffer(f32, 5).init();
    try std.testing.expectEqual(@as(usize, 0), ring.count);

    ring.push(1.0);
    ring.push(2.0);
    ring.push(3.0);
    ring.push(4.0);
    ring.push(5.0);
    ring.push(6.0); // should wrap

    try std.testing.expectEqual(@as(usize, 5), ring.count);
    try std.testing.expectEqual(@as(f32, 6.0), ring.latest() orelse 0.0);
}
