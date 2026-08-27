const std = @import("std");
const builtin = @import("builtin");
const PlatformCollector = @import("interface.zig").PlatformCollector;

pub const PlatformCollectorImpl = switch (builtin.os.tag) {
    .windows => @import("windows.zig").WindowsCollector,
    .macos => @import("macos.zig").MacosCollector,
    else => @import("linux.zig").LinuxCollector,
};

pub const PlatformContext = PlatformCollectorImpl;

pub const PlatformManager = struct {
    context: PlatformContext,

    pub fn init() PlatformManager {
        return .{
            .context = PlatformCollectorImpl.init(),
        };
    }

    pub fn getCollector(self: *PlatformManager) PlatformCollector {
        return self.context.collector();
    }
};
