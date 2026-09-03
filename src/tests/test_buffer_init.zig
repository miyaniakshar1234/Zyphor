const std = @import("std");
const buffer_mod = @import("../ui/buffer.zig");

test "ScreenBuffer initialization dimensions" {
    const allocator = std.testing.allocator;
    var buf = try buffer_mod.ScreenBuffer.init(allocator, 80, 24);
    defer buf.deinit();

    try std.testing.expectEqual(@as(u16, 80), buf.width);
    try std.testing.expectEqual(@as(u16, 24), buf.height);
}
