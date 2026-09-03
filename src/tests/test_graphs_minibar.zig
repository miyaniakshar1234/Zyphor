const std = @import("std");
const buffer_mod = @import("../ui/buffer.zig");
const graphs = @import("../ui/graphs.zig");

test "graphs renderMiniBar bounds and step rendering" {
    const allocator = std.testing.allocator;
    var buf = try buffer_mod.ScreenBuffer.init(allocator, 30, 5);
    defer buf.deinit();

    graphs.renderMiniBar(&buf, 2, 2, 5, 50.0, buffer_mod.Color.rgb(0, 0, 0), false);
    const cell = buf.getCell(2, 2);
    try std.testing.expect(cell.char_len > 0);
}
