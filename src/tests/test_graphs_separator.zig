const std = @import("std");
const buffer_mod = @import("../ui/buffer.zig");
const graphs = @import("../ui/graphs.zig");

test "graphs renderSeparator and renderLabel" {
    const allocator = std.testing.allocator;
    var buf = try buffer_mod.ScreenBuffer.init(allocator, 30, 5);
    defer buf.deinit();

    const col = buffer_mod.Color.rgb(100, 100, 100);
    const bg = buffer_mod.Color.rgb(0, 0, 0);

    graphs.renderSeparator(&buf, 0, 1, 20, col, bg, false);
    const sep = buf.getCell(5, 1);
    try std.testing.expectEqualStrings("─", sep.char[0..sep.char_len]);

    graphs.renderLabel(&buf, 0, 2, "CPU: ", "99%", col, col, bg);
    const val = buf.getCell(5, 2);
    try std.testing.expectEqualStrings("9", val.char[0..val.char_len]);
}
