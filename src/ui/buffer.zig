const std = @import("std");
const theme_mod = @import("theme.zig");
const types_mod = @import("../core/types.zig");
const Color = theme_mod.Color;

pub const Cell = struct {
    char: [4]u8 = .{ ' ', 0, 0, 0 },
    char_len: u8 = 1,
    fg: Color = Color.rgb(200, 200, 200),
    bg: Color = Color.rgb(13, 17, 23),
    bold: bool = false,
    underline: bool = false,
    dirty: bool = true,

    pub fn eql(self: Cell, other: Cell) bool {
        if (self.char_len != other.char_len) return false;
        if (!std.mem.eql(u8, self.char[0..self.char_len], other.char[0..other.char_len])) return false;
        if (self.bold != other.bold or self.underline != other.underline) return false;
        if (self.fg.is_plain != other.fg.is_plain) return false;
        if (!self.fg.is_plain) {
            if (self.fg.r != other.fg.r or self.fg.g != other.fg.g or self.fg.b != other.fg.b) return false;
            if (self.bg.r != other.bg.r or self.bg.g != other.bg.g or self.bg.b != other.bg.b) return false;
        }
        return true;
    }
};

pub const ScreenBuffer = struct {
    allocator: std.mem.Allocator,
    width: u16,
    height: u16,
    cells: []Cell,
    prev_cells: []Cell,
    default_bg: Color = Color.rgb(13, 17, 23),

    pub fn init(allocator: std.mem.Allocator, width: u16, height: u16) !ScreenBuffer {
        const total = @as(usize, width) * @as(usize, height);
        const cells = try allocator.alloc(Cell, total);
        const prev_cells = try allocator.alloc(Cell, total);

        // Initialize with impossible sentinel so first frame redraws everything
        const sentinel = Cell{
            .char = .{ 0, 0, 0, 0 },
            .char_len = 1,
            .fg = Color.rgb(1, 1, 1),
            .bg = Color.rgb(2, 2, 2),
            .dirty = true,
        };
        @memset(cells, Cell{});
        @memset(prev_cells, sentinel);

        return ScreenBuffer{
            .allocator = allocator,
            .width = width,
            .height = height,
            .cells = cells,
            .prev_cells = prev_cells,
        };
    }

    pub fn deinit(self: *ScreenBuffer) void {
        self.allocator.free(self.cells);
        self.allocator.free(self.prev_cells);
    }

    pub fn resize(self: *ScreenBuffer, width: u16, height: u16) !void {
        if (width == self.width and height == self.height) return;

        self.allocator.free(self.cells);
        self.allocator.free(self.prev_cells);

        const total = @as(usize, width) * @as(usize, height);
        self.cells = try self.allocator.alloc(Cell, total);
        self.prev_cells = try self.allocator.alloc(Cell, total);

        const sentinel = Cell{
            .char = .{ 0, 0, 0, 0 },
            .char_len = 1,
            .fg = Color.rgb(1, 1, 1),
            .bg = Color.rgb(2, 2, 2),
            .dirty = true,
        };
        @memset(self.cells, Cell{});
        @memset(self.prev_cells, sentinel);

        self.width = width;
        self.height = height;
    }

    pub fn clear(self: *ScreenBuffer, bg: Color) void {
        self.default_bg = bg;
        for (self.cells) |*cell| {
            cell.* = .{
                .char = .{ ' ', 0, 0, 0 },
                .char_len = 1,
                .fg = Color.rgb(200, 200, 200),
                .bg = bg,
                .bold = false,
                .underline = false,
                .dirty = false,
            };
        }
    }

    pub fn setCell(self: *ScreenBuffer, x: u16, y: u16, char: []const u8, fg: Color, bg: Color, bold: bool) void {
        if (x >= self.width or y >= self.height) return;
        const idx = @as(usize, y) * @as(usize, self.width) + @as(usize, x);

        var cell = Cell{
            .fg = fg,
            .bg = bg,
            .bold = bold,
        };
        const len = @min(char.len, 4);
        @memcpy(cell.char[0..len], char[0..len]);
        cell.char_len = @intCast(len);
        self.cells[idx] = cell;
    }

    pub fn setCellUnderline(self: *ScreenBuffer, x: u16, y: u16, char: []const u8, fg: Color, bg: Color, bold: bool) void {
        if (x >= self.width or y >= self.height) return;
        const idx = @as(usize, y) * @as(usize, self.width) + @as(usize, x);
        var cell = Cell{ .fg = fg, .bg = bg, .bold = bold, .underline = true };
        const len = @min(char.len, 4);
        @memcpy(cell.char[0..len], char[0..len]);
        cell.char_len = @intCast(len);
        self.cells[idx] = cell;
    }

    pub fn fillRow(self: *ScreenBuffer, y: u16, fg: Color, bg: Color) void {
        if (y >= self.height) return;
        var x: u16 = 0;
        while (x < self.width) : (x += 1) {
            self.setCell(x, y, " ", fg, bg, false);
        }
    }

    pub fn fillRect(self: *ScreenBuffer, x: u16, y: u16, w: u16, h: u16, bg: Color) void {
        var row: u16 = 0;
        while (row < h) : (row += 1) {
            var col: u16 = 0;
            while (col < w) : (col += 1) {
                self.setCell(x + col, y + row, " ", bg, bg, false);
            }
        }
    }

    pub fn writeString(self: *ScreenBuffer, x: u16, y: u16, text: []const u8, fg: Color, bg: Color, bold: bool) void {
        self.writeStringMax(x, y, text, self.width, fg, bg, bold);
    }

    pub fn writeStringMax(self: *ScreenBuffer, x: u16, y: u16, text: []const u8, max_chars: u16, fg: Color, bg: Color, bold: bool) void {
        if (y >= self.height) return;
        var curr_x = x;
        var i: usize = 0;
        var chars_written: u16 = 0;

        while (i < text.len and curr_x < self.width and chars_written < max_chars) {
            const byte = text[i];
            var char_len: usize = 1;
            if (byte >= 0xF0) char_len = 4
            else if (byte >= 0xE0) char_len = 3
            else if (byte >= 0xC0) char_len = 2;

            const end_idx = @min(i + char_len, text.len);
            self.setCell(curr_x, y, text[i..end_idx], fg, bg, bold);
            curr_x += 1;
            i += char_len;
            chars_written += 1;
        }
    }

    pub fn writeStringUnderline(self: *ScreenBuffer, x: u16, y: u16, text: []const u8, fg: Color, bg: Color, bold: bool) void {
        if (y >= self.height) return;
        var curr_x = x;
        var i: usize = 0;
        while (i < text.len and curr_x < self.width) {
            const byte = text[i];
            var char_len: usize = 1;
            if (byte >= 0xF0) char_len = 4
            else if (byte >= 0xE0) char_len = 3
            else if (byte >= 0xC0) char_len = 2;
            const end_idx = @min(i + char_len, text.len);
            self.setCellUnderline(curr_x, y, text[i..end_idx], fg, bg, bold);
            curr_x += 1;
            i += char_len;
        }
    }

    /// Draw a box with single-line Unicode borders and an optional centered title
    pub fn drawBox(
        self: *ScreenBuffer,
        x: u16,
        y: u16,
        w: u16,
        h: u16,
        title: ?[]const u8,
        border_color: Color,
        title_color: Color,
        bg_color: Color,
        plain: bool,
    ) void {
        if (w < 2 or h < 2) return;
        const right = x + w - 1;
        const bottom = y + h - 1;

        const tl = if (plain) "+" else "╭";
        const tr = if (plain) "+" else "╮";
        const bl = if (plain) "+" else "╰";
        const br = if (plain) "+" else "╯";
        const horiz = if (plain) "-" else "─";
        const vert = if (plain) "|" else "│";

        self.setCell(x, y, tl, border_color, bg_color, false);
        self.setCell(right, y, tr, border_color, bg_color, false);
        self.setCell(x, bottom, bl, border_color, bg_color, false);
        self.setCell(right, bottom, br, border_color, bg_color, false);

        // Top & bottom edges
        var cx = x + 1;
        while (cx < right) : (cx += 1) {
            self.setCell(cx, y, horiz, border_color, bg_color, false);
            self.setCell(cx, bottom, horiz, border_color, bg_color, false);
        }

        // Left & right edges + interior fill
        var cy = y + 1;
        while (cy < bottom) : (cy += 1) {
            self.setCell(x, cy, vert, border_color, bg_color, false);
            self.setCell(right, cy, vert, border_color, bg_color, false);
        }

        // Render title in the top border
        if (title) |t| {
            if (t.len > 0 and w > 6) {
                // Center the title
                const title_display_len = utf8DisplayLen(t);
                const inner_w = @as(usize, w - 2);
                const title_x = if (title_display_len + 4 < inner_w)
                    x + @as(u16, @intCast((inner_w - title_display_len - 2) / 2)) + 1
                else
                    x + 2;
                self.writeString(title_x - 1, y, " ", border_color, bg_color, false);
                self.writeString(title_x, y, t, title_color, bg_color, true);
                self.writeString(title_x + @as(u16, @intCast(title_display_len)), y, " ", border_color, bg_color, false);
            }
        }
    }

    /// Draw a thicker accent top-border box (╔═╗ style) for primary panels
    pub fn drawAccentBox(
        self: *ScreenBuffer,
        x: u16,
        y: u16,
        w: u16,
        h: u16,
        title: ?[]const u8,
        border_color: Color,
        title_color: Color,
        bg_color: Color,
        plain: bool,
    ) void {
        if (w < 2 or h < 2) return;
        const right = x + w - 1;
        const bottom = y + h - 1;

        const tl = if (plain) "+" else "╔";
        const tr = if (plain) "+" else "╗";
        const bl = if (plain) "+" else "╚";
        const br = if (plain) "+" else "╝";
        const horiz_top = if (plain) "=" else "═";
        const horiz_bot = if (plain) "-" else "─";
        const vert = if (plain) "|" else "║";

        self.setCell(x, y, tl, border_color, bg_color, false);
        self.setCell(right, y, tr, border_color, bg_color, false);
        self.setCell(x, bottom, bl, border_color, bg_color, false);
        self.setCell(right, bottom, br, border_color, bg_color, false);

        var cx = x + 1;
        while (cx < right) : (cx += 1) {
            self.setCell(cx, y, horiz_top, border_color, bg_color, false);
            self.setCell(cx, bottom, horiz_bot, border_color, bg_color, false);
        }

        var cy = y + 1;
        while (cy < bottom) : (cy += 1) {
            self.setCell(x, cy, vert, border_color, bg_color, false);
            self.setCell(right, cy, vert, border_color, bg_color, false);
        }

        if (title) |t| {
            if (t.len > 0 and w > 6) {
                const title_display_len = utf8DisplayLen(t);
                const inner_w = @as(usize, w - 2);
                const title_x = if (title_display_len + 4 < inner_w)
                    x + @as(u16, @intCast((inner_w - title_display_len - 2) / 2)) + 1
                else
                    x + 2;
                self.writeString(title_x - 1, y, " ", border_color, bg_color, false);
                self.writeString(title_x, y, t, title_color, bg_color, true);
                self.writeString(title_x + @as(u16, @intCast(title_display_len)), y, " ", border_color, bg_color, false);
            }
        }
    }

    /// Differential flush: only writes cells that changed since last frame
    pub fn flush(self: *ScreenBuffer, writer: anytype) !void {
        var buf: [65536]u8 = undefined;
        var out = std.io.fixedBufferStream(&buf);
        const w = out.writer();

        var cur_fg = Color.rgb(0, 0, 0);
        var cur_bg = Color.rgb(0, 0, 0);
        var cur_bold = false;
        var cur_underline = false;
        var last_x: i32 = -9999;
        var last_y: i32 = -9999;

        // Reset at frame start to guarantee a clean state
        try w.writeAll("\x1b[0m");
        cur_bold = false;
        cur_underline = false;

        var y: u16 = 0;
        while (y < self.height) : (y += 1) {
            var x: u16 = 0;
            while (x < self.width) : (x += 1) {
                const idx = @as(usize, y) * @as(usize, self.width) + @as(usize, x);
                const cell = self.cells[idx];
                const prev = self.prev_cells[idx];

                // Skip if unchanged
                if (cell.eql(prev)) continue;

                // Emit cursor movement if not sequential
                const ix = @as(i32, x);
                const iy = @as(i32, y);
                if (iy != last_y or ix != last_x + 1) {
                    try w.print("\x1b[{d};{d}H", .{ y + 1, x + 1 });
                }
                last_x = ix;
                last_y = iy;

                // Emit style changes
                const need_reset = (cur_bold and !cell.bold) or (cur_underline and !cell.underline);
                if (need_reset) {
                    try w.writeAll("\x1b[0m");
                    cur_bold = false;
                    cur_underline = false;
                    cur_fg = Color.rgb(0, 0, 0); // force re-emit
                    cur_bg = Color.rgb(0, 0, 0);
                }

                if (!cell.fg.is_plain) {
                    const fg_changed = cur_fg.r != cell.fg.r or cur_fg.g != cell.fg.g or cur_fg.b != cell.fg.b;
                    const bg_changed = cur_bg.r != cell.bg.r or cur_bg.g != cell.bg.g or cur_bg.b != cell.bg.b;
                    const bold_changed = cur_bold != cell.bold;
                    const underline_changed = cur_underline != cell.underline;

                    if (fg_changed or bg_changed or bold_changed or underline_changed) {
                        // Build a compact SGR sequence
                        try w.writeAll("\x1b[");
                        var first = true;
                        if (cell.bold and !cur_bold) {
                            try w.writeAll("1");
                            first = false;
                        }
                        if (cell.underline and !cur_underline) {
                            if (!first) try w.writeByte(';');
                            try w.writeAll("4");
                            first = false;
                        }
                        if (fg_changed) {
                            if (!first) try w.writeByte(';');
                            try w.print("38;2;{d};{d};{d}", .{ cell.fg.r, cell.fg.g, cell.fg.b });
                            first = false;
                        }
                        if (bg_changed) {
                            if (!first) try w.writeByte(';');
                            try w.print("48;2;{d};{d};{d}", .{ cell.bg.r, cell.bg.g, cell.bg.b });
                        }
                        try w.writeByte('m');
                        cur_fg = cell.fg;
                        cur_bg = cell.bg;
                        cur_bold = cell.bold;
                        cur_underline = cell.underline;
                    }
                }

                try w.writeAll(cell.char[0..cell.char_len]);
            }
        }

        // Reset at end
        try w.writeAll("\x1b[0m");

        // Commit
        try writer.writeAll(buf[0..out.pos]);

        // Swap buffers
        @memcpy(self.prev_cells, self.cells);
    }
};

fn utf8DisplayLen(s: []const u8) usize {
    var count: usize = 0;
    var i: usize = 0;
    while (i < s.len) {
        const byte = s[i];
        if (byte < 0x80) {
            i += 1;
        } else if (byte < 0xE0) {
            i += 2;
        } else if (byte < 0xF0) {
            i += 3;
        } else {
            i += 4;
        }
        count += 1;
    }
    return count;
}
