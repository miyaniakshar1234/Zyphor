const std = @import("std");
const builtin = @import("builtin");
const PlatformCollector = @import("interface.zig").PlatformCollector;

const WindowsCollector = if (builtin.os.tag == .windows) @import("windows.zig").WindowsCollector else struct {};
const LinuxCollector = if (builtin.os.tag == .linux or (builtin.os.tag != .windows and builtin.os.tag != .macos)) @import("linux.zig").LinuxCollector else struct {};
const MacosCollector = if (builtin.os.tag == .macos) @import("macos.zig").MacosCollector else struct {};

pub const PlatformContext = if (builtin.os.tag == .windows)
    WindowsCollector
else if (builtin.os.tag == .macos)
    MacosCollector
else
    LinuxCollector;

pub const PlatformManager = struct {
    context: PlatformContext,

    pub fn init() PlatformManager {
        if (builtin.os.tag == .windows) {
            return .{
                .context = WindowsCollector.init(),
            };
        } else if (builtin.os.tag == .macos) {
            return .{
                .context = MacosCollector.init(),
            };
        } else {
            return .{
                .context = LinuxCollector.init(),
            };
        }
    }

    pub fn getCollector(self: *PlatformManager) PlatformCollector {
        return self.context.collector();
    }
};
