const std = @import("std");
const types = @import("../core/types.zig");
const plugin_mod = @import("../core/plugin.zig");

pub const DockerPlugin = struct {
    ticks: u32 = 0,

    pub fn plugin(self: *DockerPlugin) plugin_mod.Plugin {
        return .{
            .name = "Docker OCI Integration",
            .ctx = self,
            .initFn = init,
            .updateFn = update,
            .deinitFn = deinit,
        };
    }

    fn init(ctx: *anyopaque, allocator: std.mem.Allocator) !void {
        _ = ctx;
        _ = allocator;
    }

    fn update(ctx: *anyopaque, snapshot: *types.SystemSnapshot, allocator: std.mem.Allocator) !void {
        _ = ctx;
        _ = allocator;
        // In user mode without active named pipe //./pipe/docker_engine connection,
        // do not fabricate fake containers.
        snapshot.containers = &[_]types.DockerContainer{};
    }

    fn deinit(ctx: *anyopaque, allocator: std.mem.Allocator) void {
        _ = ctx;
        _ = allocator;
    }
};
