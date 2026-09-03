const std = @import("std");
const history = @import("../core/history.zig");

test "RingBuffer getChronological ordering stability" {
    var ring = history.RingBuffer(f32, 4).init();
    ring.push(10.0);
    ring.push(20.0);
    ring.push(30.0);
    ring.push(40.0);
    ring.push(50.0); // over capacity: elements are now [20, 30, 40, 50]

    var out: [8]f32 = undefined;
    const n = ring.getChronological(&out);
    try std.testing.expectEqual(@as(usize, 4), n);
    try std.testing.expectEqual(@as(f32, 20.0), out[0]);
    try std.testing.expectEqual(@as(f32, 50.0), out[3]);
}
