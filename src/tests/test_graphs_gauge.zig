const std = @import("std");
const buffer_mod = @import("../ui/buffer.zig");
const graphs = @import("../ui/graphs.zig");

test "graphs renderGaugeBar boundary percentages" {
    const allocator = std.testing.allocator;
    var buf = try buffer_mod.ScreenBuffer.init(allocator, 40, 5);
    defer buf.deinit();

    const fg = buffer_mod.Color.rgb(0, 255, 100);
    const empty_fg = buffer_mod.Color.rgb(50, 50, 50);
    const bg = buffer_mod.Color.rgb(0, 0, 0);

    graphs.renderGaugeBar(&buf, 1, 1, 20, 0.0, fg, empty_fg, bg, false);
    graphs.renderGaugeBar(&buf, 1, 2, 20, 100.0, fg, empty_fg, bg, false);

    const c_full = buf.getCell(1, 2);
    try std.testing.expectEqualStrings("█", c_full.char[0..c_full.char_len]);
}
