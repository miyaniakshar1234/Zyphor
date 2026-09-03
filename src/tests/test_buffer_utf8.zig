const std = @import("std");
const buffer_mod = @import("../ui/buffer.zig");

test "ScreenBuffer utf8DisplayLen calculation" {
    const ascii_len = buffer_mod.utf8DisplayLen("Hello");
    try std.testing.expectEqual(@as(usize, 5), ascii_len);

    const unicode_len = buffer_mod.utf8DisplayLen("╭───╮");
    try std.testing.expectEqual(@as(usize, 5), unicode_len);
}
