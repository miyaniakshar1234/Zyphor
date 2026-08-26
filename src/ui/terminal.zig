const std = @import("std");
const builtin = @import("builtin");
const types = @import("../core/types.zig");

const windows = std.os.windows;
const DWORD = windows.DWORD;
const HANDLE = windows.HANDLE;
const BOOL = windows.BOOL;
const SHORT = windows.SHORT;
const WORD = windows.WORD;

const STD_INPUT_HANDLE: DWORD = @bitCast(@as(i32, -10));
const STD_OUTPUT_HANDLE: DWORD = @bitCast(@as(i32, -11));

const ENABLE_PROCESSED_INPUT: DWORD = 0x0001;
const ENABLE_LINE_INPUT: DWORD = 0x0002;
const ENABLE_ECHO_INPUT: DWORD = 0x0004;
const ENABLE_VIRTUAL_TERMINAL_INPUT: DWORD = 0x0200;

const ENABLE_PROCESSED_OUTPUT: DWORD = 0x0001;
const ENABLE_WRAP_AT_EOL_OUTPUT: DWORD = 0x0002;
const ENABLE_VIRTUAL_TERMINAL_PROCESSING: DWORD = 0x0004;

const COORD = extern struct { X: SHORT, Y: SHORT };
const SMALL_RECT = extern struct { Left: SHORT, Top: SHORT, Right: SHORT, Bottom: SHORT };
const CONSOLE_SCREEN_BUFFER_INFO = extern struct {
    dwSize: COORD,
    dwCursorPosition: COORD,
    wAttributes: WORD,
    srWindow: SMALL_RECT,
    dwMaximumWindowSize: COORD,
};

extern "kernel32" fn GetStdHandle(nStdHandle: DWORD) callconv(.winapi) ?HANDLE;
extern "kernel32" fn GetConsoleMode(hConsoleHandle: HANDLE, lpMode: *DWORD) callconv(.winapi) BOOL;
extern "kernel32" fn SetConsoleMode(hConsoleHandle: HANDLE, dwMode: DWORD) callconv(.winapi) BOOL;
extern "kernel32" fn GetConsoleScreenBufferInfo(hConsoleOutput: HANDLE, lpConsoleScreenBufferInfo: *CONSOLE_SCREEN_BUFFER_INFO) callconv(.winapi) BOOL;

pub const Key = union(enum) {
    char: u8,
    up,
    down,
    left,
    right,
    enter,
    escape,
    backspace,
    tab,
    shift_tab,
    page_up,
    page_down,
    home,
    end,
    delete,
    f: u8,
    unknown,
};

pub const TerminalSize = struct {
    width: u16 = 80,
    height: u16 = 24,
};

pub const Terminal = struct {
    orig_in_mode: DWORD = 0,
    orig_out_mode: DWORD = 0,
    h_in: ?HANDLE = null,
    h_out: ?HANDLE = null,
    in_raw_mode: bool = false,

    pub fn init() Terminal {
        return Terminal{};
    }

    pub fn enterRawMode(self: *Terminal) !void {
        self.h_in = GetStdHandle(STD_INPUT_HANDLE);
        self.h_out = GetStdHandle(STD_OUTPUT_HANDLE);

        if (self.h_in) |hIn| {
            _ = GetConsoleMode(hIn, &self.orig_in_mode);
            const raw_in = (self.orig_in_mode &
                ~(ENABLE_LINE_INPUT | ENABLE_ECHO_INPUT | ENABLE_PROCESSED_INPUT)) |
                ENABLE_VIRTUAL_TERMINAL_INPUT;
            _ = SetConsoleMode(hIn, raw_in);
        }

        if (self.h_out) |hOut| {
            _ = GetConsoleMode(hOut, &self.orig_out_mode);
            const raw_out = self.orig_out_mode |
                ENABLE_PROCESSED_OUTPUT |
                ENABLE_WRAP_AT_EOL_OUTPUT |
                ENABLE_VIRTUAL_TERMINAL_PROCESSING;
            _ = SetConsoleMode(hOut, raw_out);
        }

        const stdout = types.getStdout();
        // Switch to alternate screen, hide cursor, clear screen
        try stdout.writeAll("\x1b[?1049h\x1b[?25l\x1b[2J\x1b[H");
        self.in_raw_mode = true;
    }

    pub fn exitRawMode(self: *Terminal) void {
        if (!self.in_raw_mode) return;

        const stdout = types.getStdout();
        stdout.writeAll("\x1b[?25h\x1b[?1049l\x1b[0m") catch {};

        if (self.h_in) |hIn| _ = SetConsoleMode(hIn, self.orig_in_mode);
        if (self.h_out) |hOut| _ = SetConsoleMode(hOut, self.orig_out_mode);

        self.in_raw_mode = false;
    }

    pub fn getSize(self: *const Terminal) TerminalSize {
        if (self.h_out) |hOut| {
            var info: CONSOLE_SCREEN_BUFFER_INFO = undefined;
            if (GetConsoleScreenBufferInfo(hOut, &info) != 0) {
                const w = @as(u16, @intCast(info.srWindow.Right - info.srWindow.Left + 1));
                const h = @as(u16, @intCast(info.srWindow.Bottom - info.srWindow.Top + 1));
                if (w > 20 and h > 5) return .{ .width = w, .height = h };
            }
        }
        return .{ .width = 120, .height = 36 };
    }

    pub fn readKey(_: *Terminal) ?Key {
        const file = std.fs.File.stdin();
        var byte_buf: [1]u8 = undefined;

        const bytes_read = file.read(&byte_buf) catch return null;
        if (bytes_read == 0) return null;

        const b = byte_buf[0];

        if (b == '\x1b') {
            var seq: [6]u8 = undefined;
            const seq_len = file.read(&seq) catch return .escape;
            if (seq_len == 0) return .escape;

            if (seq[0] == '[' and seq_len >= 2) {
                return switch (seq[1]) {
                    'A' => .up,
                    'B' => .down,
                    'C' => .right,
                    'D' => .left,
                    'H' => .home,
                    'F' => .end,
                    'Z' => .shift_tab,
                    '3' => .delete, // ESC [ 3 ~
                    '5' => .page_up,
                    '6' => .page_down,
                    else => .unknown,
                };
            }
            return .escape;
        }

        return switch (b) {
            '\r', '\n' => .enter,
            '\t' => .tab,
            127, 8 => .backspace,
            else => .{ .char = b },
        };
    }
};
