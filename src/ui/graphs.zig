const std = @import("std");
const buffer_mod = @import("buffer.zig");
const theme_mod = @import("theme.zig");
const ScreenBuffer = buffer_mod.ScreenBuffer;
const Color = theme_mod.Color;

/// Returns a color gradient: green at 0%, yellow at 60%, red at 85%+
pub fn percentColor(pct: f32) Color {
    const p = std.math.clamp(pct, 0.0, 100.0);
    if (p < 60.0) {
        // Green -> Yellow: interpolate g from 185 to 220, r from 63 to 220
        const t = p / 60.0;
        const r = @as(u8, @intFromFloat(63.0 + t * 157.0));
        const g = @as(u8, @intFromFloat(185.0 + t * 35.0));
        return Color.rgb(r, g, 80 - @as(u8, @intFromFloat(t * 60.0)));
    } else if (p < 85.0) {
        // Yellow -> Orange
        const t = (p - 60.0) / 25.0;
        const r = @as(u8, @intFromFloat(220.0 + t * 28.0));
        const g = @as(u8, @intFromFloat(210.0 - t * 110.0));
        return Color.rgb(r, g, 0);
    } else {
        // Orange -> Red
        const t = @min((p - 85.0) / 15.0, 1.0);
        const r = @as(u8, @intFromFloat(248.0));
        const g = @as(u8, @intFromFloat(100.0 - t * 100.0));
        return Color.rgb(r, g, @as(u8, @intFromFloat(t * 30.0)));
    }
}

/// Render a full-color gradient gauge bar: [████░░░░░] with % label
pub fn renderGaugeBar(
    buf: *ScreenBuffer,
    x: u16,
    y: u16,
    width: u16,
    percent: f32,
    _fill_color: Color, // ignored — now gradient-based
    muted_fg: Color,
    bg: Color,
    plain: bool,
) void {
    _ = _fill_color;
    if (width < 5) return;

    const p = std.math.clamp(percent, 0.0, 100.0);
    const fill_color = percentColor(p);

    // Reserve 6 chars for " XX.X%" label on right
    const bar_width = if (width > 8) width - 7 else width - 2;
    const filled = @as(u16, @intFromFloat(p / 100.0 * @as(f32, @floatFromInt(bar_width))));

    buf.setCell(x, y, "[", muted_fg, bg, false);
    var i: u16 = 0;
    while (i < bar_width) : (i += 1) {
        const cx = x + 1 + i;
        if (i < filled) {
            // Gradient: full blocks shift color as they approach the fill end
            const local_pct = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(bar_width)) * 100.0;
            const block_color = percentColor(local_pct);
            const fill = if (plain) "#" else "█";
            buf.setCell(cx, y, fill, block_color, bg, false);
        } else {
            const empty = if (plain) "." else "░";
            buf.setCell(cx, y, empty, muted_fg, bg, false);
        }
    }
    buf.setCell(x + 1 + bar_width, y, "]", muted_fg, bg, false);

    // Percentage label
    if (width > 8) {
        var label_buf: [7]u8 = undefined;
        const label = std.fmt.bufPrint(&label_buf, " {d:>4.1}%", .{p}) catch " ???%";
        buf.writeString(x + 2 + bar_width, y, label, fill_color, bg, true);
    }
}

/// Render a mini single-bar without label (for per-core grids)
pub fn renderMiniBar(
    buf: *ScreenBuffer,
    x: u16,
    y: u16,
    width: u16,
    percent: f32,
    bg: Color,
    plain: bool,
) void {
    if (width < 2) return;
    const p = std.math.clamp(percent, 0.0, 100.0);
    const fill_color = percentColor(p);
    const muted = Color.rgb(60, 65, 72);
    const filled = @as(u16, @intFromFloat(p / 100.0 * @as(f32, @floatFromInt(width))));

    var i: u16 = 0;
    while (i < width) : (i += 1) {
        if (i < filled) {
            const fill = if (plain) "#" else "█";
            buf.setCell(x + i, y, fill, fill_color, bg, false);
        } else {
            const empty = if (plain) "." else "▁";
            buf.setCell(x + i, y, empty, muted, bg, false);
        }
    }
}

/// Render a block sparkline history graph with a color gradient bottom line
pub fn renderSparkline(
    buf: *ScreenBuffer,
    x: u16,
    y: u16,
    width: u16,
    history: []const f32,
    _fg: Color,
    bg: Color,
    plain: bool,
) void {
    _ = _fg;
    if (width == 0 or history.len == 0) return;

    const blocks = [_][]const u8{ " ", "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" };
    const ascii_blocks = [_][]const u8{ " ", ".", "-", "-", "=", "=", "#", "#", "!" };

    const count = @min(@as(usize, width), history.len);
    const start = if (history.len > count) history.len - count else 0;

    var i: usize = 0;
    while (i < count) : (i += 1) {
        const val = history[start + i];
        const normalized = std.math.clamp(val / 100.0, 0.0, 1.0);
        const block_idx = @as(usize, @intFromFloat(normalized * 8.0));

        const char = if (plain) ascii_blocks[block_idx] else blocks[block_idx];
        const col = percentColor(val);
        buf.setCell(x + @as(u16, @intCast(i)), y, char, col, bg, false);
    }
}

/// Two-row sparkline for a taller graph section
pub fn renderSparklineDouble(
    buf: *ScreenBuffer,
    x: u16,
    y: u16,
    width: u16,
    history: []const f32,
    bg: Color,
    plain: bool,
) void {
    if (width == 0 or history.len == 0) return;

    const blocks_top = [_][]const u8{ " ", " ", " ", " ", "▄", "▄", "▄", "█", "█" };
    const blocks_bot = [_][]const u8{ " ", "▄", "▄", "▄", "█", "█", "█", "█", "█" };

    const count = @min(@as(usize, width), history.len);
    const start = if (history.len > count) history.len - count else 0;

    var i: usize = 0;
    while (i < count) : (i += 1) {
        const val = history[start + i];
        const normalized = std.math.clamp(val / 100.0, 0.0, 1.0);
        const block_idx = @as(usize, @intFromFloat(normalized * 8.0));
        const col = percentColor(val);
        const dark_col = Color.rgb(
            @intCast(@max(0, @as(i16, col.r) - 40)),
            @intCast(@max(0, @as(i16, col.g) - 40)),
            @intCast(@max(0, @as(i16, col.b) - 40)),
        );

        const top_char = if (plain) (if (block_idx >= 4) "#" else " ") else blocks_top[block_idx];
        const bot_char = if (plain) (if (block_idx >= 2) "=" else " ") else blocks_bot[block_idx];

        buf.setCell(x + @as(u16, @intCast(i)), y, top_char, col, bg, false);
        buf.setCell(x + @as(u16, @intCast(i)), y + 1, bot_char, dark_col, bg, false);
    }
}

/// Draw a thin horizontal separator line
pub fn renderSeparator(buf: *ScreenBuffer, x: u16, y: u16, w: u16, color: Color, bg: Color, plain: bool) void {
    const ch = if (plain) "-" else "─";
    var i: u16 = 0;
    while (i < w) : (i += 1) {
        buf.setCell(x + i, y, ch, color, bg, false);
    }
}

/// Render a labeled value pair: "  CPU:  " + colored value
pub fn renderLabel(buf: *ScreenBuffer, x: u16, y: u16, label: []const u8, value: []const u8, label_color: Color, value_color: Color, bg: Color) void {
    buf.writeString(x, y, label, label_color, bg, false);
    const lx = x + @as(u16, @intCast(label.len));
    buf.writeString(lx, y, value, value_color, bg, true);
}
