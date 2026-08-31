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

    pub fn validate(self: *Config) void {

        self.refresh_rate_ms = std.math.clamp(self.refresh_rate_ms, 50, 60000);
        self.cpu_warning_pct = std.math.clamp(self.cpu_warning_pct, 10.0, 99.0);
        self.cpu_critical_pct = std.math.clamp(self.cpu_critical_pct, self.cpu_warning_pct, 100.0);
        self.mem_warning_pct = std.math.clamp(self.mem_warning_pct, 10.0, 99.0);
        self.mem_critical_pct = std.math.clamp(self.mem_critical_pct, self.mem_warning_pct, 100.0);
        self.disk_warning_pct = std.math.clamp(self.disk_warning_pct, 10.0, 99.0);
        self.disk_critical_pct = std.math.clamp(self.disk_critical_pct, self.disk_warning_pct, 100.0);
        if (self.theme_name_len == 0) {
            self.setThemeName("anthropic");
        }
    }
};

test "config validation clamps out-of-range thresholds" {
    var cfg = Config{
        .refresh_rate_ms = 10,
        .cpu_warning_pct = 150.0,
        .cpu_critical_pct = -20.0,
        .theme_name_len = 0,
    };
    cfg.validate();
    try std.testing.expect(cfg.refresh_rate_ms >= 50);
    try std.testing.expect(cfg.cpu_warning_pct <= 99.0);
    try std.testing.expectEqualStrings("anthropic", cfg.getThemeName());
}

