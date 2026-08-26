const std = @import("std");

pub const Color = struct {
    r: u8 = 255,
    g: u8 = 255,
    b: u8 = 255,
    is_plain: bool = false,

    pub fn rgb(r: u8, g: u8, b: u8) Color {
        return .{ .r = r, .g = g, .b = b, .is_plain = false };
    }

    pub fn plain() Color {
        return .{ .is_plain = true };
    }
};

pub const Theme = struct {
    name: []const u8,
    bg: Color,
    fg: Color,
    accent: Color,
    secondary: Color,
    success: Color,
    warning: Color,
    critical: Color,
    border: Color,
    header: Color,
    selected: Color,
    muted: Color,
};

pub const BuiltinThemes = struct {
    pub const midnight = Theme{
        .name = "midnight",
        .bg = Color.rgb(13, 17, 23),
        .fg = Color.rgb(230, 237, 243),
        .accent = Color.rgb(88, 166, 255),
        .secondary = Color.rgb(56, 189, 248),
        .success = Color.rgb(63, 185, 80),
        .warning = Color.rgb(210, 153, 34),
        .critical = Color.rgb(248, 81, 73),
        .border = Color.rgb(48, 54, 61),
        .header = Color.rgb(121, 192, 255),
        .selected = Color.rgb(33, 40, 52),
        .muted = Color.rgb(139, 148, 158),
    };

    pub const cyber = Theme{
        .name = "cyber",
        .bg = Color.rgb(5, 5, 10),
        .fg = Color.rgb(240, 240, 255),
        .accent = Color.rgb(255, 0, 128),
        .secondary = Color.rgb(0, 240, 255),
        .success = Color.rgb(0, 255, 136),
        .warning = Color.rgb(255, 230, 0),
        .critical = Color.rgb(255, 50, 50),
        .border = Color.rgb(100, 0, 160),
        .header = Color.rgb(255, 0, 200),
        .selected = Color.rgb(40, 10, 60),
        .muted = Color.rgb(120, 100, 160),
    };

    pub const aurora = Theme{
        .name = "aurora",
        .bg = Color.rgb(16, 24, 32),
        .fg = Color.rgb(224, 242, 254),
        .accent = Color.rgb(52, 211, 153),
        .secondary = Color.rgb(45, 212, 191),
        .success = Color.rgb(74, 222, 128),
        .warning = Color.rgb(251, 191, 36),
        .critical = Color.rgb(248, 113, 113),
        .border = Color.rgb(30, 58, 70),
        .header = Color.rgb(167, 139, 250),
        .selected = Color.rgb(20, 45, 55),
        .muted = Color.rgb(148, 163, 184),
    };

    pub const nord = Theme{
        .name = "nord",
        .bg = Color.rgb(46, 52, 64),
        .fg = Color.rgb(236, 239, 244),
        .accent = Color.rgb(136, 192, 208),
        .secondary = Color.rgb(129, 161, 193),
        .success = Color.rgb(163, 190, 140),
        .warning = Color.rgb(235, 203, 139),
        .critical = Color.rgb(191, 97, 106),
        .border = Color.rgb(76, 86, 106),
        .header = Color.rgb(143, 188, 187),
        .selected = Color.rgb(59, 66, 82),
        .muted = Color.rgb(140, 150, 170),
    };

    pub const solarized = Theme{
        .name = "solarized",
        .bg = Color.rgb(0, 43, 54),
        .fg = Color.rgb(131, 148, 150),
        .accent = Color.rgb(38, 139, 210),
        .secondary = Color.rgb(42, 161, 152),
        .success = Color.rgb(133, 153, 0),
        .warning = Color.rgb(181, 137, 0),
        .critical = Color.rgb(220, 50, 47),
        .border = Color.rgb(7, 54, 66),
        .header = Color.rgb(108, 113, 196),
        .selected = Color.rgb(7, 54, 66),
        .muted = Color.rgb(88, 110, 117),
    };

    pub const high_contrast = Theme{
        .name = "high_contrast",
        .bg = Color.rgb(0, 0, 0),
        .fg = Color.rgb(255, 255, 255),
        .accent = Color.rgb(0, 255, 255),
        .secondary = Color.rgb(255, 255, 0),
        .success = Color.rgb(0, 255, 0),
        .warning = Color.rgb(255, 165, 0),
        .critical = Color.rgb(255, 0, 0),
        .border = Color.rgb(255, 255, 255),
        .header = Color.rgb(255, 255, 255),
        .selected = Color.rgb(60, 60, 60),
        .muted = Color.rgb(180, 180, 180),
    };

    pub const plain = Theme{
        .name = "plain",
        .bg = Color.plain(),
        .fg = Color.plain(),
        .accent = Color.plain(),
        .secondary = Color.plain(),
        .success = Color.plain(),
        .warning = Color.plain(),
        .critical = Color.plain(),
        .border = Color.plain(),
        .header = Color.plain(),
        .selected = Color.plain(),
        .muted = Color.plain(),
    };
};

pub fn getThemeByName(name: []const u8) Theme {
    if (std.mem.eql(u8, name, "cyber")) return BuiltinThemes.cyber;
    if (std.mem.eql(u8, name, "aurora")) return BuiltinThemes.aurora;
    if (std.mem.eql(u8, name, "nord")) return BuiltinThemes.nord;
    if (std.mem.eql(u8, name, "solarized")) return BuiltinThemes.solarized;
    if (std.mem.eql(u8, name, "high_contrast")) return BuiltinThemes.high_contrast;
    if (std.mem.eql(u8, name, "plain")) return BuiltinThemes.plain;
    return BuiltinThemes.midnight;
}
