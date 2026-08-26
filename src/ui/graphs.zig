const std = @import("std");
const buffer_mod = @import("buffer.zig");
const theme_mod = @import("theme.zig");
const ScreenBuffer = buffer_mod.ScreenBuffer;
const Color = theme_mod.Color;

pub fn renderGaugeBar(
    buf: *ScreenBuffer,
    x: u16,
    y: u16,
    width: u16,
    percent: f32,
    fg: Color,
    muted_fg: Color,
    bg: Color,
    plain: bool,
) void {
    if (width < 8) return;

    buf.setCell(x, y, "[", muted_fg, bg, false);
    const bar_width = width - 2;
    const filled_chars = @as(u16, @intFromFloat(std.math.clamp(percent / 100.0, 0.0, 1.0) * @as(f32, @floatFromInt(bar_width))));

    var i: u16 = 0;
    while (i < bar_width) : (i += 1) {
        const cx = x + 1 + i;
        if (i < filled_chars) {
            const fill = if (plain) "#" else "█";
            buf.setCell(cx, y, fill, fg, bg, true);
        } else {
            const empty = if (plain) "-" else "░";
            buf.setCell(cx, y, empty, muted_fg, bg, false);
        }
    }

    buf.setCell(x + width - 1, y, "]", muted_fg, bg, false);
}

pub fn renderSparkline(
    buf: *ScreenBuffer,
    x: u16,
    y: u16,
    width: u16,
    history: []const f32,
    fg: Color,
    bg: Color,
    plain: bool,
) void {
    if (width == 0 or history.len == 0) return;

    const blocks = [_][]const u8{ " ", " ", "▂", "▃", "▄", "▅", "▆", "▇", "█" };
    const ascii_blocks = [_][]const u8{ ".", ".", "-", "-", "=", "=", "#", "#", "#" };

    const count = @min(@as(usize, width), history.len);
    const start_offset = if (history.len > count) history.len - count else 0;

    var i: usize = 0;
    while (i < count) : (i += 1) {
        const val = history[start_offset + i];
        const normalized = std.math.clamp(val / 100.0, 0.0, 1.0);
        const block_idx = @as(usize, @intFromFloat(normalized * 8.0));

        const char = if (plain) ascii_blocks[block_idx] else blocks[block_idx];
        buf.setCell(x + @as(u16, @intCast(i)), y, char, fg, bg, false);
    }
}
