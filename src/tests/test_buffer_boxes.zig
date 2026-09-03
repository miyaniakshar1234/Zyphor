const std = @import("std");
const buffer_mod = @import("../ui/buffer.zig");
const Color = buffer_mod.Color;

test "ScreenBuffer drawBox single line corners" {
    const allocator = std.testing.allocator;
    var buf = try buffer_mod.ScreenBuffer.init(allocator, 30, 10);
    defer buf.deinit();

    buf.drawBox(2, 2, 10, 5, "TEST", Color.rgb(100, 100, 100), Color.rgb(255, 255, 255), Color.rgb(0, 0, 0), false);
    const tl = buf.getCell(2, 2);
    try std.testing.expectEqualStrings("╭", tl.char[0..tl.char_len]);

    const tr = buf.getCell(11, 2);
    try std.testing.expectEqualStrings("╮", tr.char[0..tr.char_len]);
}
