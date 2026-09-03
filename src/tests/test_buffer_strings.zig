const std = @import("std");
const buffer_mod = @import("../ui/buffer.zig");
const Color = buffer_mod.Color;

test "ScreenBuffer writeString and writeStringMax" {
    const allocator = std.testing.allocator;
    var buf = try buffer_mod.ScreenBuffer.init(allocator, 50, 10);
    defer buf.deinit();

    buf.writeString(5, 2, "ZYPHOR", Color.rgb(255, 200, 0), Color.rgb(0, 0, 0), true);
    const c0 = buf.getCell(5, 2);
    try std.testing.expectEqualStrings("Z", c0.char[0..c0.char_len]);
    try std.testing.expect(c0.bold);

    buf.writeStringMax(10, 3, "TOOLONGSTRING", 4, Color.rgb(255, 255, 255), Color.rgb(0, 0, 0), false);
    const c4 = buf.getCell(13, 3);
    try std.testing.expectEqualStrings("L", c4.char[0..c4.char_len]);
}
