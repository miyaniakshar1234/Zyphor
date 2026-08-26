const std = @import("std");
pub fn main() !void {
    const left_mask = [_]u16{0x00, 0x40, 0x44, 0x46, 0x47};
    const right_mask = [_]u16{0x00, 0x80, 0xA0, 0xB0, 0xB8};
    var buf: [4]u8 = undefined;
    
    const code = 0x2800 | left_mask[4] | right_mask[3];
    const len = try std.unicode.utf8Encode(@as(u21, @intCast(code)), &buf);
    std.debug.print("Code: {x}, UTF-8: {s}\n", .{code, buf[0..len]});
}
