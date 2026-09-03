const std = @import("std");
const buffer_mod = @import("../ui/buffer.zig");
const Color = buffer_mod.Color;

test "ScreenBuffer drawCyberBox rounded borders" {
    const allocator = std.testing.allocator;
    var buf = try buffer_mod.ScreenBuffer.init(allocator, 40, 15);
    defer buf.deinit();

    buf.drawCyberBox(1, 1, 20, 8, "CPU", Color.rgb(100, 150, 200), Color.rgb(255, 255, 255), Color.rgb(0, 0, 0), false);
    const bl = buf.getCell(1, 8);
    try std.testing.expectEqualStrings("╰", bl.char[0..bl.char_len]);

    const br = buf.getCell(20, 8);
    try std.testing.expectEqualStrings("╯", br.char[0..br.char_len]);
}
