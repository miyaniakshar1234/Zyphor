const std = @import("std");

pub const Config = struct {
    refresh_rate_ms: u32 = 1000,
    theme_name: [32]u8 = defaultTheme(),
    theme_name_len: usize = 9,
    enable_mouse: bool = true,
    plain_mode: bool = false,
    history_capacity: usize = 120, // 2 minutes at 1s intervals

    // Thresholds
    cpu_warning_pct: f32 = 80.0,
    cpu_critical_pct: f32 = 95.0,
    mem_warning_pct: f32 = 85.0,
    mem_critical_pct: f32 = 95.0,
    disk_warning_pct: f32 = 85.0,
    disk_critical_pct: f32 = 95.0,
    temp_warning_c: f32 = 80.0,
    temp_critical_c: f32 = 90.0,

    fn defaultTheme() [32]u8 {
        var buf: [32]u8 = @splat(0);
        const name = "anthropic";
        @memcpy(buf[0..name.len], name);
        return buf;
    }

    pub fn getThemeName(self: *const Config) []const u8 {
        return self.theme_name[0..self.theme_name_len];
    }

    pub fn setThemeName(self: *Config, name: []const u8) void {
        const len = @min(name.len, self.theme_name.len);
        @memcpy(self.theme_name[0..len], name[0..len]);
        self.theme_name_len = len;
    }
};
