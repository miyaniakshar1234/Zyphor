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
        var self: *DockerPlugin = @ptrCast(@alignCast(ctx));
        self.ticks += 1;

        const sample_containers = [_]struct {
            id: []const u8, name: []const u8, image: []const u8, state: types.ContainerState, 
            cpu: f32, mem: u64, mem_limit: u64, rx: u64, tx: u64
        }{
            .{ .id = "a1b2c3d4e5f6", .name = "zyphor-redis-cache", .image = "redis:7.0-alpine", .state = .running, .cpu = 0.8, .mem = 42 * 1024 * 1024, .mem_limit = 256 * 1024 * 1024, .rx = 120500, .tx = 84000 },
            .{ .id = "f6e5d4c3b2a1", .name = "api-gateway-prod", .image = "nginx:latest", .state = .running, .cpu = 2.4, .mem = 18 * 1024 * 1024, .mem_limit = 128 * 1024 * 1024, .rx = 1048576 * 5, .tx = 1048576 * 12 },
            .{ .id = "112233445566", .name = "postgres-db-main", .image = "postgres:15", .state = .running, .cpu = 14.5, .mem = 1024 * 1024 * 1024, .mem_limit = 4096 * 1024 * 1024, .rx = 1048576 * 2, .tx = 1048576 * 50 },
            .{ .id = "7f8e9d0c1b2a", .name = "legacy-cron-job", .image = "ubuntu:20.04", .state = .exited, .cpu = 0.0, .mem = 0, .mem_limit = 512 * 1024 * 1024, .rx = 0, .tx = 0 },
        };

        var containers = try allocator.alloc(types.DockerContainer, sample_containers.len);
        for (sample_containers, 0..) |sc, cidx| {
            var c = types.DockerContainer{
                .state = sc.state,
                .cpu_percent = sc.cpu,
                .memory_used_bytes = sc.mem,
                .memory_limit_bytes = sc.mem_limit,
                .net_rx_bytes = sc.rx,
                .net_tx_bytes = sc.tx,
            };
            const id_len = @min(sc.id.len, 64);
            @memcpy(c.id[0..id_len], sc.id[0..id_len]);
            c.id_len = id_len;
            
            const name_len = @min(sc.name.len, 64);
            @memcpy(c.name[0..name_len], sc.name[0..name_len]);
            c.name_len = name_len;
            
            const img_len = @min(sc.image.len, 64);
            @memcpy(c.image[0..img_len], sc.image[0..img_len]);
            c.image_len = img_len;
            
            containers[cidx] = c;
        }

        // Just add some jitter using self.ticks
        if (containers.len > 0) {
            containers[0].cpu_percent += @as(f32, @floatFromInt(self.ticks % 10)) * 0.1;
        }

        snapshot.containers = containers;
    }

    fn deinit(ctx: *anyopaque, allocator: std.mem.Allocator) void {
        _ = ctx;
        _ = allocator;
    }
};
