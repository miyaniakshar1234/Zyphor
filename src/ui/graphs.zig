const std = @import("std");
const buffer_mod = @import("buffer.zig");
const theme_mod = @import("theme.zig");
const ScreenBuffer = buffer_mod.ScreenBuffer;
const Color = theme_mod.Color;

/// Returns a color gradient: emerald green at 0%, amber at 60%, crimson red at 85%+
pub fn percentColor(pct: f32) Color {
    const p = std.math.clamp(pct, 0.0, 100.0);
    if (p < 50.0) {
        // Green (63, 185, 80) -> Yellow-Green (120, 205, 60)
        const t = p / 50.0;
        const r = @as(u8, @intFromFloat(63.0 + t * 57.0));
        const g = @as(u8, @intFromFloat(185.0 + t * 20.0));
        const b = @as(u8, @intFromFloat(80.0 - t * 20.0));
        return Color.rgb(r, g, b);
    } else if (p < 75.0) {
        // Yellow-Green -> Amber (240, 180, 0)
        const t = (p - 50.0) / 25.0;
        const r = @as(u8, @intFromFloat(120.0 + t * 120.0));
        const g = @as(u8, @intFromFloat(205.0 - t * 25.0));
        const b = @as(u8, @intFromFloat(60.0 - t * 60.0));
        return Color.rgb(r, g, b);
    } else if (p < 90.0) {
        // Amber -> Orange-Red (250, 90, 30)
        const t = (p - 75.0) / 15.0;
        const r = @as(u8, @intFromFloat(240.0 + t * 10.0));
        const g = @as(u8, @intFromFloat(180.0 - t * 90.0));
        const b = @as(u8, @intFromFloat(t * 30.0));
        return Color.rgb(r, g, b);
    } else {
        // Crimson Red (255, 45, 55)
        const t = @min((p - 90.0) / 10.0, 1.0);
        const r = @as(u8, @intFromFloat(250.0 + t * 5.0));
        const g = @as(u8, @intFromFloat(90.0 - t * 45.0));
        const b = @as(u8, @intFromFloat(30.0 + t * 25.0));
        return Color.rgb(r, g, b);
    }
}

/// Smooth quarter-fraction sub-cell block characters
const FRACTION_BLOCKS = [_][]const u8{
    " ", "▏", "▎", "▍", "▌", "▋", "▊", "▉", "█",
};

/// High-resolution braille 8-level column glyphs
const BRAILLE_LEVELS = [_][]const u8{
    " ", "⣀", "⣤", "⣶", "⣷", "⣿",
};

/// Render a full-color gradient gauge bar: [████░░░░░] with % label
pub fn renderGaugeBar(
    buf: *ScreenBuffer,
    x: u16,
    y: u16,
    width: u16,
    percent: f32,
    _fill_color: Color,
    muted_fg: Color,
    bg: Color,
    plain: bool,
) void {
    _ = _fill_color;
    if (width < 5) return;

    const p = std.math.clamp(percent, 0.0, 100.0);
    const fill_color = percentColor(p);

    // Reserve space for " XX.X%" label on right if wide enough
    const has_label = (width > 9);
    const bar_width = if (has_label) width - 7 else width - 2;
    const total_substeps = @as(f32, @floatFromInt(bar_width)) * 8.0;
    const filled_substeps = @as(u32, @intFromFloat(p / 100.0 * total_substeps));

    buf.setCell(x, y, "[", muted_fg, bg, false);

    var i: u16 = 0;
    while (i < bar_width) : (i += 1) {
        const cx = x + 1 + i;
        const cell_start = @as(u32, i) * 8;
        const local_pct = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(bar_width)) * 100.0;
        const block_color = percentColor(local_pct);

        if (filled_substeps >= cell_start + 8) {
            // Full block
            const fill = if (plain) "#" else "█";
            buf.setCell(cx, y, fill, block_color, bg, false);
        } else if (filled_substeps > cell_start) {
            // Fractional block
            const fraction = filled_substeps - cell_start;
            const frac_char = if (plain) "#" else FRACTION_BLOCKS[fraction];
            buf.setCell(cx, y, frac_char, block_color, bg, false);
        } else {
            // Empty background
            const empty = if (plain) "." else "░";
            buf.setCell(cx, y, empty, muted_fg, bg, false);
        }
    }

    buf.setCell(x + 1 + bar_width, y, "]", muted_fg, bg, false);

    // Percentage label
    if (has_label) {
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
    const muted = Color.rgb(45, 55, 68);
    const total_substeps = @as(f32, @floatFromInt(width)) * 8.0;
    const filled_substeps = @as(u32, @intFromFloat(p / 100.0 * total_substeps));

    var i: u16 = 0;
    while (i < width) : (i += 1) {
        const cell_start = @as(u32, i) * 8;
        if (filled_substeps >= cell_start + 8) {
            const fill = if (plain) "#" else "█";
            buf.setCell(x + i, y, fill, fill_color, bg, false);
        } else if (filled_substeps > cell_start) {
            const fraction = filled_substeps - cell_start;
            const frac_char = if (plain) "#" else FRACTION_BLOCKS[fraction];
            buf.setCell(x + i, y, frac_char, fill_color, bg, false);
        } else {
            const empty = if (plain) "." else "░";
            buf.setCell(x + i, y, empty, muted, bg, false);
        }
    }
}

/// Render a block sparkline history graph
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

    const blocks = [_][]const u8{ " ", " ", "▂", "▃", "▄", "▅", "▆", "▇", "█" };
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

/// Two-row sparkline for taller graph sections with smooth vertical graduation
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

    const blocks_top = [_][]const u8{ " ", " ", " ", " ", " ", "▄", "▅", "▆", "█" };
    const blocks_bot = [_][]const u8{ " ", "▂", "▃", "▄", "█", "█", "█", "█", "█" };

    const count = @min(@as(usize, width), history.len);
    const start = if (history.len > count) history.len - count else 0;

    var i: usize = 0;
    while (i < count) : (i += 1) {
        const val = history[start + i];
        const normalized = std.math.clamp(val / 100.0, 0.0, 1.0);
        const block_idx = @as(usize, @intFromFloat(normalized * 8.0));
        const col = percentColor(val);
        const bot_col = col.darken(35);

        const top_char = if (plain) (if (block_idx >= 5) "#" else " ") else blocks_top[block_idx];
        const bot_char = if (plain) (if (block_idx >= 1) "=" else " ") else blocks_bot[block_idx];

        buf.setCell(x + @as(u16, @intCast(i)), y, top_char, col, bg, false);
        buf.setCell(x + @as(u16, @intCast(i)), y + 1, bot_char, bot_col, bg, false);
    }
}

/// Three-row braille-enhanced area waveform graph for dedicated panel views
pub fn renderWaveformGraph(
    buf: *ScreenBuffer,
    x: u16,
    y: u16,
    width: u16,
    height: u16,
    history: []const f32,
    color_override: ?Color,
    bg: Color,
    plain: bool,
) void {
    if (width == 0 or height == 0 or history.len == 0) return;

    const count = @min(@as(usize, width), history.len);
    const start = if (history.len > count) history.len - count else 0;

    // Find peak value in history for dynamic auto-scaling
    var peak_val: f32 = 0.01;
    for (history) |v| {
        if (v > peak_val) peak_val = v;
    }
    const scale_max = if (color_override != null) @max(0.05, peak_val * 1.15) else 100.0;

    var col: usize = 0;
    while (col < count) : (col += 1) {
        const val = history[start + col];
        const col_fg = color_override orelse percentColor(val);

        // Normalize across height rows (0 to height)
        const total_steps = @as(f32, @floatFromInt(height)) * 8.0;
        const filled_steps = (std.math.clamp(val / scale_max, 0.0, 1.0)) * total_steps;

        var row: u16 = 0;
        while (row < height) : (row += 1) {
            // Inverted Y: row 0 is top, row (height-1) is bottom
            const cell_y = y + (height - 1 - row);
            const row_start = @as(f32, @floatFromInt(row)) * 8.0;

            if (filled_steps >= row_start + 8.0) {
                // Full block
                const char = if (plain) "#" else "█";
                const row_fg = if (row == height - 1) col_fg else col_fg.darken(@as(u8, @intCast((height - 1 - row) * 20)));
                buf.setCell(x + @as(u16, @intCast(col)), cell_y, char, row_fg, bg, false);
            } else if (filled_steps > row_start) {
                // Partial block
                const step = @as(usize, @intFromFloat(filled_steps - row_start));
                const char = if (plain) "=" else FRACTION_BLOCKS[@min(step, 8)];
                buf.setCell(x + @as(u16, @intCast(col)), cell_y, char, col_fg, bg, false);
            } else {
                // Empty cell
                if (!plain) {
                    buf.setCell(x + @as(u16, @intCast(col)), cell_y, " ", bg, bg, false);
                }
            }
        }
    }
}

/// High-density true Braille area-fill graph (2x4 resolution per cell)
pub fn renderBrailleGraph(
    buf: *ScreenBuffer,
    x: u16,
    y: u16,
    width: u16,
    height: u16,
    history: []const f32,
    color_override: ?Color,
    bg: Color,
    plain: bool,
) void {
    if (width == 0 or height == 0) return;
    if (plain) {
        renderWaveformGraph(buf, x, y, width, height, history, color_override, bg, plain);
        return;
    }

    if (history.len == 0) {
        var col: u16 = 0;
        while (col < width) : (col += 1) {
            var row: u16 = 0;
            while (row < height) : (row += 1) {
                const cell_y = y + (height - 1 - row);
                if (row == 0) {
                    buf.setCell(x + col, cell_y, "─", Color.rgb(40, 45, 55), bg, false);
                } else if (col % 6 == 0 and row % 2 == 0) {
                    buf.setCell(x + col, cell_y, "·", Color.rgb(35, 40, 48), bg, false);
                }
            }
        }
        return;
    }

    const left_mask = [_]u16{ 0x00, 0x40, 0x44, 0x46, 0x47 };
    const right_mask = [_]u16{ 0x00, 0x80, 0xA0, 0xB0, 0xB8 };

    const max_hist = @min(history.len, @as(usize, width) * 2);
    const start_idx = if (history.len > max_hist) history.len - max_hist else 0;

    // Find peak value in history for dynamic auto-scaling
    var peak_val: f32 = 0.01;
    for (history) |v| {
        if (v > peak_val) peak_val = v;
    }
    const scale_max = if (color_override != null) @max(0.05, peak_val * 1.15) else 100.0;

    var col: u16 = 0;
    while (col < width) : (col += 1) {
        // We read two historical data points per cell column (left and right dots)
        const left_idx = start_idx + @as(usize, col) * 2;
        const right_idx = left_idx + 1;

        const left_val = if (left_idx < history.len) history[left_idx] else 0.0;
        const right_val = if (right_idx < history.len) history[right_idx] else 0.0;

        const max_val = @max(left_val, right_val);
        const col_fg = color_override orelse percentColor(max_val);

        const total_pixels = @as(f32, @floatFromInt(height)) * 4.0;
        const left_pixels = @as(u16, @intFromFloat(std.math.clamp(left_val / scale_max * total_pixels, 0.0, total_pixels)));
        const right_pixels = @as(u16, @intFromFloat(std.math.clamp(right_val / scale_max * total_pixels, 0.0, total_pixels)));

        var row: u16 = 0;
        while (row < height) : (row += 1) {
            const cell_y = y + (height - 1 - row);
            const row_px = row * 4;

            const l_px = if (left_pixels > row_px) @min(left_pixels - row_px, 4) else 0;
            const r_px = if (right_pixels > row_px) @min(right_pixels - row_px, 4) else 0;

            if (l_px == 0 and r_px == 0) {
                // Subtle oscilloscope radar grid dot
                if (row == 0) {
                    buf.setCell(x + col, cell_y, "─", Color.rgb(40, 45, 55), bg, false);
                } else if (col % 6 == 0 and row % 2 == 0) {
                    buf.setCell(x + col, cell_y, "·", Color.rgb(35, 40, 48), bg, false);
                } else {
                    buf.setCell(x + col, cell_y, " ", bg, bg, false);
                }
            } else {
                const code = 0x2800 | left_mask[l_px] | right_mask[r_px];
                var utf8_buf: [4]u8 = undefined;
                const len = std.unicode.utf8Encode(@as(u21, @intCast(code)), &utf8_buf) catch 0;
                
                const row_fg = if (row == height - 1) col_fg else col_fg.darken(@as(u8, @intCast((height - 1 - row) * 12)));
                buf.setCell(x + col, cell_y, utf8_buf[0..len], row_fg, bg, false);
            }
        }
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

/// High-density radial dial graph mapping 0..100% to a circular gauge
pub fn renderRadialDial(
    buf: *ScreenBuffer,
    x: u16,
    y: u16,
    radius_chars: u16,
    thickness: f32,
    percent: f32,
    fg: Color,
    bg: Color,
    plain: bool,
) void {
    if (plain or radius_chars < 3) return;
    
    const w = radius_chars * 2;
    const h = radius_chars;
    const cx = @as(f32, @floatFromInt(w)) * 2.0 / 2.0;
    const cy = @as(f32, @floatFromInt(h)) * 4.0 / 2.0;
    const radius = @as(f32, @floatFromInt(radius_chars)) * 4.0 / 2.0;
    const inner_radius = radius - thickness;
    
    const pct = std.math.clamp(percent, 0.0, 100.0) / 100.0;
    const end_angle = pct * std.math.pi * 2.0;

    var row: u16 = 0;
    while (row < h) : (row += 1) {
        var col: u16 = 0;
        while (col < w) : (col += 1) {
            var dots: u8 = 0;
            var track_dots: u8 = 0;
            var dy: u16 = 0;
            while (dy < 4) : (dy += 1) {
                var dx: u16 = 0;
                while (dx < 2) : (dx += 1) {
                    const px = @as(f32, @floatFromInt(col * 2 + dx));
                    const py = @as(f32, @floatFromInt(row * 4 + dy));
                    
                    const dist = std.math.hypot(px - cx, py - cy);
                    if (dist >= inner_radius and dist <= radius) {
                        var angle = std.math.atan2(px - cx, cy - py);
                        if (angle < 0) angle += std.math.pi * 2.0;
                        if (angle <= end_angle) {
                            const dot_bit: u8 = @as(u8, 1) << @as(u3, @intCast(dx * 4 + dy));
                            dots |= dot_bit;
                        } else if (dist >= radius - 1.0) {
                            const dot_bit: u8 = @as(u8, 1) << @as(u3, @intCast(dx * 4 + dy));
                            track_dots |= dot_bit;
                        }
                    }
                }
            }
            
            if (dots > 0) {
                var braille: u16 = 0x2800;
                if (dots & (1 << 0) != 0) braille |= 0x01;
                if (dots & (1 << 1) != 0) braille |= 0x02;
                if (dots & (1 << 2) != 0) braille |= 0x04;
                if (dots & (1 << 3) != 0) braille |= 0x40;
                if (dots & (1 << 4) != 0) braille |= 0x08;
                if (dots & (1 << 5) != 0) braille |= 0x10;
                if (dots & (1 << 6) != 0) braille |= 0x20;
                if (dots & (1 << 7) != 0) braille |= 0x80;
                
                var utf8_buf: [4]u8 = undefined;
                const len = std.unicode.utf8Encode(@as(u21, @intCast(braille)), &utf8_buf) catch 0;
                buf.setCell(x + col, y + row, utf8_buf[0..len], fg, bg, false);
            } else if (track_dots > 0) {
                var braille: u16 = 0x2800;
                if (track_dots & (1 << 0) != 0) braille |= 0x01;
                if (track_dots & (1 << 1) != 0) braille |= 0x02;
                if (track_dots & (1 << 2) != 0) braille |= 0x04;
                if (track_dots & (1 << 3) != 0) braille |= 0x40;
                if (track_dots & (1 << 4) != 0) braille |= 0x08;
                if (track_dots & (1 << 5) != 0) braille |= 0x10;
                if (track_dots & (1 << 6) != 0) braille |= 0x20;
                if (track_dots & (1 << 7) != 0) braille |= 0x80;
                
                var utf8_buf: [4]u8 = undefined;
                const len = std.unicode.utf8Encode(@as(u21, @intCast(braille)), &utf8_buf) catch 0;
                const dim_fg = Color.rgb(
                    @as(u8, @intFromFloat(@as(f32, @floatFromInt(fg.r)) * 0.25)),
                    @as(u8, @intFromFloat(@as(f32, @floatFromInt(fg.g)) * 0.25)),
                    @as(u8, @intFromFloat(@as(f32, @floatFromInt(fg.b)) * 0.25)),
                );
                buf.setCell(x + col, y + row, utf8_buf[0..len], dim_fg, bg, false);
            }
        }
    }
}



pub fn renderSeparatorVertical(buf: *ScreenBuffer, x: u16, y: u16, h: u16, color: Color, bg: Color, plain: bool) void {
    var i: u16 = 0;
    while (i < h) : (i += 1) {
        if (y + i >= buf.height) break;
        if (plain) {
            buf.writeString(x, y + i, "|", color, bg, false);
        } else {
            buf.writeString(x, y + i, "│", color, bg, false);
        }
    }
}
