const std = @import("std");
const builtin = @import("builtin");
const PlatformCollector = @import("interface.zig").PlatformCollector;

const WindowsCollector = @import("windows.zig").WindowsCollector;
const LinuxCollector = @import("linux.zig").LinuxCollector;
const MacosCollector = @import("macos.zig").MacosCollector;

pub const PlatformContext = union(enum) {
    windows: WindowsCollector,
    linux: LinuxCollector,
    macos: MacosCollector,
};

pub const PlatformManager = struct {
    context: PlatformContext,

    pub fn init() PlatformManager {
        if (builtin.os.tag == .windows) {
            return .{
                .context = .{ .windows = WindowsCollector.init() },
            };
        } else if (builtin.os.tag == .linux) {
            return .{
                .context = .{ .linux = LinuxCollector.init() },
            };
        } else if (builtin.os.tag == .macos) {
            return .{
                .context = .{ .macos = MacosCollector.init() },
            };
        } else {
            // Default fallback to linux mock
            return .{
                .context = .{ .linux = LinuxCollector.init() },
            };
        }
    }

    pub fn getCollector(self: *PlatformManager) PlatformCollector {
        switch (self.context) {
            .windows => |*w| return w.collector(),
            .linux => |*l| return l.collector(),
            .macos => |*m| return m.collector(),
        }
    }
};
