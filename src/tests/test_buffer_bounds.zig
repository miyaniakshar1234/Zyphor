const std = @import("std");
const buffer_mod = @import("../ui/buffer.zig");
const Color = buffer_mod.Color;

test "ScreenBuffer setCell out of bounds does not crash" {
    const allocator = std.testing.allocator;
    var buf = try buffer_mod.ScreenBuffer.init(allocator, 40, 20);
    defer buf.deinit();

    // Out of bounds writes should be safely ignored
    buf.setCell(100, 100, "X", Color.rgb(255, 255, 255), Color.rgb(0, 0, 0), false);
    buf.setCell(40, 20, "Y", Color.rgb(255, 255, 255), Color.rgb(0, 0, 0), false);

    // In-bounds write should succeed
    buf.setCell(0, 0, "A", Color.rgb(255, 255, 255), Color.rgb(0, 0, 0), false);
    const cell = buf.getCell(0, 0);
    try std.testing.expectEqualStrings("A", cell.char[0..cell.char_len]);
}
