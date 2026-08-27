const std = @import("std");
const types = @import("../core/types.zig");
const PlatformCollector = @import("interface.zig").PlatformCollector;

pub const LinuxCollector = struct {
    prev_total: u64 = 0,
    prev_idle: u64 = 0,
    num_cores: u32 = 1,

    pub fn init() LinuxCollector {
        var num_cores: u32 = 1;
        if (std.Thread.getCpuCount()) |count| {
            num_cores = @as(u32, @intCast(count));
        } else |_| {
            num_cores = 4;
        }

        return LinuxCollector{
            .num_cores = num_cores,
        };
    }

    const vtable_impl: PlatformCollector.VTable = .{
        .getCpuMetrics = getCpuMetrics,
        .getMemoryMetrics = getMemoryMetrics,
        .getDiskMetrics = getDiskMetrics,
        .getNetworkMetrics = getNetworkMetrics,
        .getGpuMetrics = getGpuMetrics,
        .getBatteryMetrics = getBatteryMetrics,
        .getProcessList = getProcessList,
        .killProcess = killProcess,
        .suspendProcess = suspendProcess,
        .resumeProcess = resumeProcess,
        .deinit = deinit,
    };

    pub fn collector(self: *LinuxCollector) PlatformCollector {
        return .{
            .ptr = self,
            .vtable = &vtable_impl,
        };
    }

    fn deinit(_: *anyopaque) void {}

    fn getCpuMetrics(ctx: *anyopaque, allocator: std.mem.Allocator) anyerror!types.CpuMetrics {
        const self: *LinuxCollector = @ptrCast(@alignCast(ctx));

        var cpu = types.CpuMetrics{
            .logical_cores = self.num_cores,
            .physical_cores = @max(1, self.num_cores / 2),
            .frequency_mhz = 3600,
            .total_usage = 18.5,
            .user_usage = 12.1,
            .system_usage = 6.4,
            .idle_usage = 81.5,
        };

        const name = "Linux / AMD64 Generic Processor";
        @memcpy(cpu.model_name[0..name.len], name);
        cpu.model_name_len = name.len;

        const cores = try allocator.alloc(f32, self.num_cores);
        var i: usize = 0;
        while (i < self.num_cores) : (i += 1) {
            cores[i] = 15.0 + @as(f32, @floatFromInt((i * 7) % 20));
        }
        cpu.core_usage = cores;

        return cpu;
    }

    fn getMemoryMetrics(_: *anyopaque) anyerror!types.MemoryMetrics {
        const total = 16 * 1024 * 1024 * 1024;
        const used = 8 * 1024 * 1024 * 1024;
        const avail = total - used;

        return types.MemoryMetrics{
            .total_bytes = total,
            .used_bytes = used,
            .available_bytes = avail,
            .free_bytes = avail / 2,
            .cached_bytes = avail / 2,
            .swap_total_bytes = 4 * 1024 * 1024 * 1024,
            .swap_used_bytes = 128 * 1024 * 1024,
            .swap_free_bytes = (4 * 1024 - 128) * 1024 * 1024,
            .used_percent = 50.0,
            .swap_used_percent = 3.1,
            .pressure_level = .low,
        };
    }

    fn getDiskMetrics(_: *anyopaque, allocator: std.mem.Allocator) anyerror!types.DiskMetrics {
        var partitions = try allocator.alloc(types.DiskPartition, 1);
        partitions[0] = .{
            .total_bytes = 512 * 1024 * 1024 * 1024,
            .used_bytes = 180 * 1024 * 1024 * 1024,
            .free_bytes = 332 * 1024 * 1024 * 1024,
            .used_percent = 35.1,
        };
        const mount = "/";
        @memcpy(partitions[0].mount_point[0..mount.len], mount);
        partitions[0].mount_len = mount.len;

        const fs = "ext4";
        @memcpy(partitions[0].fs_type[0..fs.len], fs);
        partitions[0].fs_len = fs.len;

        return types.DiskMetrics{
            .partitions = partitions,
            .read_bytes_sec = 1_800_000,
            .write_bytes_sec = 950_000,
            .iops = 88,
        };
    }

    fn getNetworkMetrics(_: *anyopaque, allocator: std.mem.Allocator) anyerror!types.NetworkMetrics {
        var ifaces = try allocator.alloc(types.NetworkInterface, 1);
        ifaces[0] = .{
            .rx_bytes_sec = 2_100_000,
            .tx_bytes_sec = 420_000,
            .total_rx_bytes = 8_500_000_000,
            .total_tx_bytes = 1_200_000_000,
            .is_up = true,
        };
        const name = "eth0";
        @memcpy(ifaces[0].name[0..name.len], name);
        ifaces[0].name_len = name.len;

        const ip = "192.168.1.50";
        @memcpy(ifaces[0].ip_address[0..ip.len], ip);
        ifaces[0].ip_len = ip.len;

        return types.NetworkMetrics{
            .interfaces = ifaces,
            .total_rx_sec = ifaces[0].rx_bytes_sec,
            .total_tx_sec = ifaces[0].tx_bytes_sec,
        };
    }

    fn getGpuMetrics(_: *anyopaque) types.GpuMetrics {
        var gpu = types.GpuMetrics{
            .available = true,
            .utilization_pct = 15.0,
            .vram_total_bytes = 6 * 1024 * 1024 * 1024,
            .vram_used_bytes = 1200 * 1024 * 1024,
            .temperature_c = 48.0,
        };
        const name = "Linux DRM / Mesa GPU Driver";
        @memcpy(gpu.name[0..name.len], name);
        gpu.name_len = name.len;
        return gpu;
    }

    fn getBatteryMetrics(_: *anyopaque) types.BatteryMetrics {
        return .{
            .available = false,
            .percentage = 100.0,
            .is_charging = true,
        };
    }

    fn getProcessList(_: *anyopaque, allocator: std.mem.Allocator) anyerror![]types.ProcessInfo {
        const pids = [_]u32{ 1, 120, 480, 1024, 1500, 2048 };
        const names = [_][]const u8{ "systemd", "sshd", "NetworkManager", "docker", "bash", "zyphor" };

        var list = try allocator.alloc(types.ProcessInfo, pids.len);
        for (pids, 0..) |pid, idx| {
            var proc = types.ProcessInfo{
                .pid = pid,
                .ppid = if (pid == 1) 0 else 1,
                .cpu_percent = @as(f32, @floatFromInt(idx * 3)) + 0.5,
                .memory_rss = (@as(u64, @intCast(idx + 1)) * 32) * 1024 * 1024,
                .threads_count = @as(u32, @intCast(idx + 2)),
                .state = .running,
            };
            const nm = names[idx];
            @memcpy(proc.name[0..nm.len], nm);
            proc.name_len = nm.len;
            list[idx] = proc;
        }

        return list;
    }

    fn killProcess(_: *anyopaque, _: u32) anyerror!void {}
    fn suspendProcess(_: *anyopaque, _: u32) anyerror!void {}
    fn resumeProcess(_: *anyopaque, _: u32) anyerror!void {}
};
