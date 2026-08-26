const std = @import("std");
const builtin = @import("builtin");
const types = @import("../core/types.zig");

const windows = std.os.windows;
const DWORD = windows.DWORD;
const HANDLE = windows.HANDLE;
const BOOL = windows.BOOL;

const STD_INPUT_HANDLE: DWORD = @bitCast(@as(i32, -10));
const STD_OUTPUT_HANDLE: DWORD = @bitCast(@as(i32, -11));

const ENABLE_PROCESSED_INPUT: DWORD = 0x0001;
const ENABLE_LINE_INPUT: DWORD = 0x0002;
const ENABLE_ECHO_INPUT: DWORD = 0x0004;
const ENABLE_MOUSE_INPUT: DWORD = 0x0010;
const ENABLE_VIRTUAL_TERMINAL_INPUT: DWORD = 0x0200;

const ENABLE_PROCESSED_OUTPUT: DWORD = 0x0001;
const ENABLE_WRAP_AT_EOL_OUTPUT: DWORD = 0x0002;
const ENABLE_VIRTUAL_TERMINAL_PROCESSING: DWORD = 0x0004;

extern "kernel32" fn GetStdHandle(nStdHandle: DWORD) callconv(.winapi) ?HANDLE;
extern "kernel32" fn GetConsoleMode(hConsoleHandle: HANDLE, lpMode: *DWORD) callconv(.winapi) BOOL;
extern "kernel32" fn SetConsoleMode(hConsoleHandle: HANDLE, dwMode: DWORD) callconv(.winapi) BOOL;

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
        if (builtin.os.tag == .windows) {
            self.h_in = GetStdHandle(STD_INPUT_HANDLE);
            self.h_out = GetStdHandle(STD_OUTPUT_HANDLE);

            if (self.h_in) |hIn| {
                _ = GetConsoleMode(hIn, &self.orig_in_mode);
                const raw_in = (self.orig_in_mode & ~(ENABLE_LINE_INPUT | ENABLE_ECHO_INPUT | ENABLE_PROCESSED_INPUT)) | ENABLE_VIRTUAL_TERMINAL_INPUT;
                _ = SetConsoleMode(hIn, raw_in);
            }

            if (self.h_out) |hOut| {
                _ = GetConsoleMode(hOut, &self.orig_out_mode);
                const raw_out = self.orig_out_mode | ENABLE_PROCESSED_OUTPUT | ENABLE_WRAP_AT_EOL_OUTPUT | ENABLE_VIRTUAL_TERMINAL_PROCESSING;
                _ = SetConsoleMode(hOut, raw_out);
            }
        }

        const stdout = types.getStdout();
        try stdout.writeAll("\x1b[?1049h\x1b[?25l\x1b[2J\x1b[H");
        self.in_raw_mode = true;
    }

    pub fn exitRawMode(self: *Terminal) void {
        if (!self.in_raw_mode) return;

        const stdout = types.getStdout();
        stdout.writeAll("\x1b[?25h\x1b[?1049l") catch {};

        if (builtin.os.tag == .windows) {
            if (self.h_in) |hIn| {
                _ = SetConsoleMode(hIn, self.orig_in_mode);
            }
            if (self.h_out) |hOut| {
                _ = SetConsoleMode(hOut, self.orig_out_mode);
            }
        }
        self.in_raw_mode = false;
    }

    pub fn getSize(_: *const Terminal) TerminalSize {
        return .{
            .width = 120,
            .height = 36,
        };
    }

    pub fn readKey(_: *Terminal) ?Key {
        const file = std.fs.File.stdin();
        var byte_buf: [1]u8 = undefined;

        const bytes_read = file.read(&byte_buf) catch return null;
        if (bytes_read == 0) return null;

        const b = byte_buf[0];
        if (b == '\x1b') {
            var seq: [3]u8 = undefined;
            const seq_len = file.read(&seq) catch return .escape;
            if (seq_len == 0) return .escape;

            if (seq[0] == '[') {
                if (seq_len >= 2) {
                    return switch (seq[1]) {
                        'A' => .up,
                        'B' => .down,
                        'C' => .right,
                        'D' => .left,
                        'H' => .home,
                        'F' => .end,
                        'Z' => .shift_tab,
                        else => .unknown,
                    };
                }
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
