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

    pub fn darken(self: Color, amount: u8) Color {
        return .{
            .r = if (self.r > amount) self.r - amount else 0,
            .g = if (self.g > amount) self.g - amount else 0,
            .b = if (self.b > amount) self.b - amount else 0,
            .is_plain = self.is_plain,
        };
    }

    pub fn brighten(self: Color, amount: u8) Color {
        return .{
            .r = @intCast(@min(255, @as(u16, self.r) + amount)),
            .g = @intCast(@min(255, @as(u16, self.g) + amount)),
            .b = @intCast(@min(255, @as(u16, self.b) + amount)),
            .is_plain = self.is_plain,
        };
    }
};

pub const Theme = struct {
    name: []const u8,
    // Core colors
    bg: Color,
    fg: Color,
    accent: Color,
    accent_dim: Color,     // dimmed version of accent for separators/dividers
    secondary: Color,      // secondary highlight (memory, etc.)
    // Semantic
    success: Color,
    warning: Color,
    critical: Color,
    // UI structure
    border: Color,
    header: Color,         // column header text
    header_bg: Color,      // top header bar background
    tab_bg: Color,         // tab bar & status bar background
    selected: Color,       // selected row background
    muted: Color,          // secondary text / inactive tabs
};

// ─────────────────────────────────────────────────────────────────────────────
// BUILT-IN THEMES
// ─────────────────────────────────────────────────────────────────────────────

pub const BuiltinThemes = struct {

    /// Anthropic - elegant charcoal with terracotta/peach accents
    pub const anthropic = Theme{
        .name = "anthropic",
        .bg         = Color.rgb(31,  29,  28),  // Very dark warm gray (#1f1d1c)
        .fg         = Color.rgb(235, 233, 228), // Soft paper white (#ebe9e4)
        .accent     = Color.rgb(217, 119, 87),  // Terracotta / Rust (#d97757)
        .accent_dim = Color.rgb(138, 90,  74),  // Dimmed rust
        .secondary  = Color.rgb(229, 192, 123), // Warm sand/biscuit (#e5c07b)
        .success    = Color.rgb(113, 142, 117), // Muted sage green
        .warning    = Color.rgb(212, 162, 89),  // Soft amber
        .critical   = Color.rgb(186, 84,  84),  // Muted brick red
        .border     = Color.rgb(65,  60,  58),  // Subtle borders
        .header     = Color.rgb(217, 119, 87),  // Same as accent
        .header_bg  = Color.rgb(40,  37,  36),  // Slightly lighter charcoal
        .tab_bg     = Color.rgb(25,  24,  23),  // Darker tab bar
        .selected   = Color.rgb(54,  51,  49),  // Selected item
        .muted      = Color.rgb(154, 149, 142), // Muted text
    };

    /// Hacker - terminal green matrix style
    pub const hacker = Theme{
        .name = "hacker",
        .bg         = Color.rgb(2,   5,   2),
        .fg         = Color.rgb(57,  255, 20),
        .accent     = Color.rgb(0,   255, 0),
        .accent_dim = Color.rgb(0,   80,  0),
        .secondary  = Color.rgb(0,   200, 0),
        .success    = Color.rgb(57,  255, 20),
        .warning    = Color.rgb(200, 255, 0),
        .critical   = Color.rgb(255, 0,   0),
        .border     = Color.rgb(0,   120, 0),
        .header     = Color.rgb(100, 255, 100),
        .header_bg  = Color.rgb(5,   15,  5),
        .tab_bg     = Color.rgb(3,   10,  3),
        .selected   = Color.rgb(0,   50,  0),
        .muted      = Color.rgb(0,   150, 0),
    };
    
    /// Tokyo Night - beautiful blue/purple
    pub const tokyo_night = Theme{
        .name = "tokyo_night",
        .bg         = Color.rgb(26,  27,  38),
        .fg         = Color.rgb(192, 202, 245),
        .accent     = Color.rgb(187, 154, 247), // Purple
        .accent_dim = Color.rgb(80,  60,  120),
        .secondary  = Color.rgb(122, 162, 247), // Blue
        .success    = Color.rgb(158, 206, 106), // Green
        .warning    = Color.rgb(224, 175, 104), // Yellow/Orange
        .critical   = Color.rgb(247, 118, 142), // Red
        .border     = Color.rgb(86,  95,  137), // Comment grey
        .header     = Color.rgb(125, 207, 255), // Cyan
        .header_bg  = Color.rgb(31,  35,  53),
        .tab_bg     = Color.rgb(22,  22,  30),
        .selected   = Color.rgb(41,  46,  66),
        .muted      = Color.rgb(169, 177, 214),
    };

    /// Midnight — deep blue-black with electric blue accents (DEFAULT)
    pub const midnight = Theme{
        .name = "midnight",
        .bg         = Color.rgb(13,  17,  23),
        .fg         = Color.rgb(220, 228, 238),
        .accent     = Color.rgb(88,  166, 255),
        .accent_dim = Color.rgb(40,  80,  130),
        .secondary  = Color.rgb(56,  189, 248),
        .success    = Color.rgb(63,  185, 80),
        .warning    = Color.rgb(210, 153, 34),
        .critical   = Color.rgb(248, 81,  73),
        .border     = Color.rgb(45,  55,  72),
        .header     = Color.rgb(121, 192, 255),
        .header_bg  = Color.rgb(22,  29,  42),
        .tab_bg     = Color.rgb(18,  22,  32),
        .selected   = Color.rgb(30,  43,  62),
        .muted      = Color.rgb(100, 116, 139),
    };

    /// Cyber — intense synthwave neon on deep dark purple
    pub const cyber = Theme{
        .name = "cyber",
        .bg         = Color.rgb(8,   4,   16),
        .fg         = Color.rgb(240, 240, 255),
        .accent     = Color.rgb(255, 0,   85), // Hot pink-red
        .accent_dim = Color.rgb(120, 0,   40),
        .secondary  = Color.rgb(0,   255, 255), // Pure Cyan
        .success    = Color.rgb(57,  255, 20), // Neon Lime Green
        .warning    = Color.rgb(255, 215, 0), // Golden Yellow
        .critical   = Color.rgb(255, 20,  60), // Laser Red
        .border     = Color.rgb(138, 43,  226), // Blue Violet
        .header     = Color.rgb(255, 105, 180), // Hot Pink
        .header_bg  = Color.rgb(20,  10,  35),
        .tab_bg     = Color.rgb(14,  6,   24),
        .selected   = Color.rgb(60,  10,  80),
        .muted      = Color.rgb(140, 100, 180),
    };

    /// Aurora — teal and violet on dark navy
    pub const aurora = Theme{
        .name = "aurora",
        .bg         = Color.rgb(14,  22,  32),
        .fg         = Color.rgb(220, 242, 255),
        .accent     = Color.rgb(52,  211, 153),
        .accent_dim = Color.rgb(20,  90,  65),
        .secondary  = Color.rgb(167, 139, 250),
        .success    = Color.rgb(74,  222, 128),
        .warning    = Color.rgb(251, 191, 36),
        .critical   = Color.rgb(248, 113, 113),
        .border     = Color.rgb(28,  52,  70),
        .header     = Color.rgb(167, 139, 250),
        .header_bg  = Color.rgb(20,  32,  48),
        .tab_bg     = Color.rgb(16,  26,  38),
        .selected   = Color.rgb(22,  46,  58),
        .muted      = Color.rgb(120, 148, 172),
    };

    /// Nord — arctic blue-greys
    pub const nord = Theme{
        .name = "nord",
        .bg         = Color.rgb(46,  52,  64),
        .fg         = Color.rgb(236, 239, 244),
        .accent     = Color.rgb(136, 192, 208),
        .accent_dim = Color.rgb(70,  100, 120),
        .secondary  = Color.rgb(129, 161, 193),
        .success    = Color.rgb(163, 190, 140),
        .warning    = Color.rgb(235, 203, 139),
        .critical   = Color.rgb(191, 97,  106),
        .border     = Color.rgb(67,  76,  94),
        .header     = Color.rgb(143, 188, 187),
        .header_bg  = Color.rgb(36,  42,  54),
        .tab_bg     = Color.rgb(40,  46,  58),
        .selected   = Color.rgb(59,  66,  82),
        .muted      = Color.rgb(118, 130, 150),
    };

    /// Solarized Dark
    pub const solarized = Theme{
        .name = "solarized",
        .bg         = Color.rgb(0,   43,  54),
        .fg         = Color.rgb(131, 148, 150),
        .accent     = Color.rgb(38,  139, 210),
        .accent_dim = Color.rgb(10,  60,  90),
        .secondary  = Color.rgb(42,  161, 152),
        .success    = Color.rgb(133, 153, 0),
        .warning    = Color.rgb(181, 137, 0),
        .critical   = Color.rgb(220, 50,  47),
        .border     = Color.rgb(7,   54,  66),
        .header     = Color.rgb(108, 113, 196),
        .header_bg  = Color.rgb(0,   30,  40),
        .tab_bg     = Color.rgb(0,   36,  46),
        .selected   = Color.rgb(0,   66,  84),
        .muted      = Color.rgb(70,  90,  100),
    };

    /// Gruvbox — warm oranges and yellows
    pub const gruvbox = Theme{
        .name = "gruvbox",
        .bg         = Color.rgb(29,  32,  33),
        .fg         = Color.rgb(235, 219, 178),
        .accent     = Color.rgb(250, 189, 47),
        .accent_dim = Color.rgb(100, 78,  20),
        .secondary  = Color.rgb(214, 93,  14),
        .success    = Color.rgb(142, 192, 124),
        .warning    = Color.rgb(250, 189, 47),
        .critical   = Color.rgb(251, 73,  52),
        .border     = Color.rgb(60,  56,  54),
        .header     = Color.rgb(250, 189, 47),
        .header_bg  = Color.rgb(40,  40,  40),
        .tab_bg     = Color.rgb(32,  32,  32),
        .selected   = Color.rgb(68,  68,  68),
        .muted      = Color.rgb(146, 131, 116),
    };

    /// High Contrast — maximum readability
    pub const high_contrast = Theme{
        .name = "high_contrast",
        .bg         = Color.rgb(0,   0,   0),
        .fg         = Color.rgb(255, 255, 255),
        .accent     = Color.rgb(0,   255, 255),
        .accent_dim = Color.rgb(0,   100, 100),
        .secondary  = Color.rgb(255, 255, 0),
        .success    = Color.rgb(0,   255, 0),
        .warning    = Color.rgb(255, 165, 0),
        .critical   = Color.rgb(255, 0,   0),
        .border     = Color.rgb(180, 180, 180),
        .header     = Color.rgb(255, 255, 255),
        .header_bg  = Color.rgb(30,  30,  30),
        .tab_bg     = Color.rgb(20,  20,  20),
        .selected   = Color.rgb(50,  50,  50),
        .muted      = Color.rgb(180, 180, 180),
    };

    /// Synthwave '84 - retro neon violet, pink, and sunset amber
    pub const synthwave_84 = Theme{
        .name = "synthwave_84",
        .bg         = Color.rgb(26,  20,  40),
        .fg         = Color.rgb(240, 235, 255),
        .accent     = Color.rgb(255, 105, 180), // Hot pink
        .accent_dim = Color.rgb(140, 50,  100),
        .secondary  = Color.rgb(120, 220, 255), // Neon sky blue
        .success    = Color.rgb(114, 241, 184), // Neon aqua
        .warning    = Color.rgb(254, 218, 106), // Sunset gold
        .critical   = Color.rgb(254, 68,  122), // Laser red
        .border     = Color.rgb(75,  55,  105),
        .header     = Color.rgb(255, 120, 200),
        .header_bg  = Color.rgb(36,  28,  55),
        .tab_bg     = Color.rgb(20,  15,  32),
        .selected   = Color.rgb(75,  50,  110),
        .muted      = Color.rgb(160, 140, 190),
    };

    /// Matrix Rain - ultra-clean dark cyber matrix
    pub const matrix_rain = Theme{
        .name = "matrix_rain",
        .bg         = Color.rgb(5,   10,  7),
        .fg         = Color.rgb(150, 255, 170),
        .accent     = Color.rgb(0,   255, 102), // Radioactive green
        .accent_dim = Color.rgb(0,   90,  36),
        .secondary  = Color.rgb(0,   204, 153), // Electric mint
        .success    = Color.rgb(57,  255, 20),
        .warning    = Color.rgb(255, 215, 0),
        .critical   = Color.rgb(255, 51,  102),
        .border     = Color.rgb(15,  50,  25),
        .header     = Color.rgb(0,   255, 102),
        .header_bg  = Color.rgb(8,   20,  12),
        .tab_bg     = Color.rgb(4,   12,  6),
        .selected   = Color.rgb(10,  40,  20),
        .muted      = Color.rgb(60,  140, 80),
    };

    /// Plain — no colors (for terminals without true-color support)
    pub const no_color = Theme{
        .name = "plain",
        .bg         = Color.plain(),
        .fg         = Color.plain(),
        .accent     = Color.plain(),
        .accent_dim = Color.plain(),
        .secondary  = Color.plain(),
        .success    = Color.plain(),
        .warning    = Color.plain(),
        .critical   = Color.plain(),
        .border     = Color.plain(),
        .header     = Color.plain(),
        .header_bg  = Color.plain(),
        .tab_bg     = Color.plain(),
        .selected   = Color.plain(),
        .muted      = Color.plain(),
    };
};

pub const ALL_THEMES = [_]Theme{
    BuiltinThemes.anthropic,
    BuiltinThemes.cyber,
    BuiltinThemes.synthwave_84,
    BuiltinThemes.matrix_rain,
    BuiltinThemes.tokyo_night,
    BuiltinThemes.hacker,
    BuiltinThemes.midnight,
    BuiltinThemes.aurora,
    BuiltinThemes.nord,
    BuiltinThemes.solarized,
    BuiltinThemes.gruvbox,
    BuiltinThemes.high_contrast,
};

pub fn getThemeByName(name: []const u8) Theme {
    if (std.mem.eql(u8, name, "anthropic"))     return BuiltinThemes.anthropic;
    if (std.mem.eql(u8, name, "cyber"))         return BuiltinThemes.cyber;
    if (std.mem.eql(u8, name, "synthwave_84"))  return BuiltinThemes.synthwave_84;
    if (std.mem.eql(u8, name, "matrix_rain"))   return BuiltinThemes.matrix_rain;
    if (std.mem.eql(u8, name, "tokyo_night"))   return BuiltinThemes.tokyo_night;
    if (std.mem.eql(u8, name, "hacker"))        return BuiltinThemes.hacker;
    if (std.mem.eql(u8, name, "midnight"))      return BuiltinThemes.midnight;
    if (std.mem.eql(u8, name, "aurora"))        return BuiltinThemes.aurora;
    if (std.mem.eql(u8, name, "nord"))          return BuiltinThemes.nord;
    if (std.mem.eql(u8, name, "solarized"))     return BuiltinThemes.solarized;
    if (std.mem.eql(u8, name, "gruvbox"))       return BuiltinThemes.gruvbox;
    if (std.mem.eql(u8, name, "high_contrast")) return BuiltinThemes.high_contrast;
    if (std.mem.eql(u8, name, "plain"))         return BuiltinThemes.no_color;
    return BuiltinThemes.anthropic; // default
}

pub fn getThemeByIndex(idx: usize) Theme {
    return ALL_THEMES[idx % ALL_THEMES.len];
}

