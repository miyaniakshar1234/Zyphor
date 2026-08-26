const std = @import("std");
const math = std.math;

pub fn main() !void {
    const w = 16;
    const h = 8;
    const cx: f32 = @as(f32, w) * 2.0 / 2.0;
    const cy: f32 = @as(f32, h) * 4.0 / 2.0;
    const radius: f32 = 14.0;
    const inner_radius: f32 = 10.0;
    
    const pct: f32 = 0.65;
    const end_angle: f32 = pct * math.pi * 2.0;

    var buf: [4]u8 = undefined;

    var row: u16 = 0;
    while (row < h) : (row += 1) {
        var col: u16 = 0;
        while (col < w) : (col += 1) {
            var dots: u8 = 0;
            var dy: u16 = 0;
            while (dy < 4) : (dy += 1) {
                var dx: u16 = 0;
                while (dx < 2) : (dx += 1) {
                    const px = @as(f32, @floatFromInt(col * 2 + dx));
                    const py = @as(f32, @floatFromInt(row * 4 + dy));
                    
                    const dist = math.hypot(px - cx, py - cy);
                    if (dist >= inner_radius and dist <= radius) {
                        var angle = math.atan2(px - cx, cy - py);
                        if (angle < 0) angle += math.pi * 2.0;
                        if (angle <= end_angle) {
                            const dot_bit: u8 = @as(u8, 1) << @as(u3, @intCast(dx * 4 + dy));
                            dots |= dot_bit;
                        }
                    }
                }
            }
            
            var braille: u16 = 0x2800;
            if (dots & (1 << 0) != 0) braille |= 0x01;
            if (dots & (1 << 1) != 0) braille |= 0x02;
            if (dots & (1 << 2) != 0) braille |= 0x04;
            if (dots & (1 << 3) != 0) braille |= 0x40;
            if (dots & (1 << 4) != 0) braille |= 0x08;
            if (dots & (1 << 5) != 0) braille |= 0x10;
            if (dots & (1 << 6) != 0) braille |= 0x20;
            if (dots & (1 << 7) != 0) braille |= 0x80;
            
            if (braille == 0x2800) {
                std.debug.print(" ", .{});
            } else {
                const len = std.unicode.utf8Encode(@as(u21, @intCast(braille)), &buf) catch 0;
                std.debug.print("{s}", .{buf[0..len]});
            }
        }
        std.debug.print("\n", .{});
    }
}
scratch
