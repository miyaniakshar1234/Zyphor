const std = @import("std");
const theme_mod = @import("theme.zig");
const Color = theme_mod.Color;

pub const Cell = struct {
    char: [4]u8 = [_]u8{ ' ', 0, 0, 0 },
    char_len: u8 = 1,
    fg: Color = Color.rgb(255, 255, 255),
    bg: Color = Color.rgb(0, 0, 0),
    bold: bool = false,
    underline: bool = false,

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

    pub fn init(allocator: std.mem.Allocator, width: u16, height: u16) !ScreenBuffer {
        const total = @as(usize, width) * @as(usize, height);
        const cells = try allocator.alloc(Cell, total);
        @memset(cells, Cell{});
        return ScreenBuffer{
            .allocator = allocator,
            .width = width,
            .height = height,
            .cells = cells,
        };
    }

    pub fn deinit(self: *ScreenBuffer) void {
        self.allocator.free(self.cells);
    }

    pub fn clear(self: *ScreenBuffer, bg: Color) void {
        for (self.cells) |*cell| {
            cell.* = Cell{
                .char = [_]u8{ ' ', 0, 0, 0 },
                .char_len = 1,
                .bg = bg,
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
        cell.char_len = @as(u8, @intCast(len));

        self.cells[idx] = cell;
    }

    pub fn writeString(self: *ScreenBuffer, x: u16, y: u16, text: []const u8, fg: Color, bg: Color, bold: bool) void {
        if (y >= self.height) return;
        var curr_x = x;
        var i: usize = 0;

        while (i < text.len and curr_x < self.width) {
            const byte = text[i];
            var char_len: usize = 1;
            if (byte >= 0xF0) {
                char_len = 4;
            } else if (byte >= 0xE0) {
                char_len = 3;
            } else if (byte >= 0xC0) {
                char_len = 2;
            }

            const end_idx = @min(i + char_len, text.len);
            const slice = text[i..end_idx];

            self.setCell(curr_x, y, slice, fg, bg, bold);
            curr_x += 1;
            i += char_len;
        }
    }

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

        const tl = if (plain) "+" else "┌";
        const tr = if (plain) "+" else "┐";
        const bl = if (plain) "+" else "└";
        const br = if (plain) "+" else "┘";
        const horiz = if (plain) "-" else "─";
        const vert = if (plain) "|" else "│";

        // Draw corners
        self.setCell(x, y, tl, border_color, bg_color, false);
        self.setCell(right, y, tr, border_color, bg_color, false);
        self.setCell(x, bottom, bl, border_color, bg_color, false);
        self.setCell(right, bottom, br, border_color, bg_color, false);

        // Draw top & bottom edges
        var cx = x + 1;
        while (cx < right) : (cx += 1) {
            self.setCell(cx, y, horiz, border_color, bg_color, false);
            self.setCell(cx, bottom, horiz, border_color, bg_color, false);
        }

        // Draw left & right edges
        var cy = y + 1;
        while (cy < bottom) : (cy += 1) {
            self.setCell(x, cy, vert, border_color, bg_color, false);
            self.setCell(right, cy, vert, border_color, bg_color, false);
        }

        // Draw Title
        if (title) |t| {
            if (t.len > 0 and w > 4) {
                const title_x = x + 2;
                self.setCell(title_x - 1, y, " ", border_color, bg_color, false);
                self.writeString(title_x, y, t, title_color, bg_color, true);
                self.setCell(title_x + @as(u16, @intCast(t.len)), y, " ", border_color, bg_color, false);
            }
        }
    }

    pub fn flush(self: *const ScreenBuffer, writer: anytype) !void {
        // Move to top-left
        try writer.writeAll("\x1b[H");

        var cur_fg = Color.plain();
        var cur_bg = Color.plain();
        var cur_bold = false;

        var y: u16 = 0;
        while (y < self.height) : (y += 1) {
            var x: u16 = 0;
            while (x < self.width) : (x += 1) {
                const idx = @as(usize, y) * @as(usize, self.width) + @as(usize, x);
                const cell = self.cells[idx];

                if (!cell.fg.is_plain) {
                    if (cur_bold != cell.bold or cur_fg.r != cell.fg.r or cur_fg.g != cell.fg.g or cur_fg.b != cell.fg.b or cur_bg.r != cell.bg.r or cur_bg.g != cell.bg.g or cur_bg.b != cell.bg.b) {
                        if (cell.bold) {
                            try writer.print("\x1b[1;38;2;{d};{d};{d};48;2;{d};{d};{d}m", .{ cell.fg.r, cell.fg.g, cell.fg.b, cell.bg.r, cell.bg.g, cell.bg.b });
                        } else {
                            try writer.print("\x1b[0;38;2;{d};{d};{d};48;2;{d};{d};{d}m", .{ cell.fg.r, cell.fg.g, cell.fg.b, cell.bg.r, cell.bg.g, cell.bg.b });
                        }
                        cur_fg = cell.fg;
                        cur_bg = cell.bg;
                        cur_bold = cell.bold;
                    }
                }

                try writer.writeAll(cell.char[0..cell.char_len]);
            }
            if (y < self.height - 1) {
                try writer.writeAll("\r\n");
            }
        }

        // Reset styling
        try writer.writeAll("\x1b[0m");
    }
};
