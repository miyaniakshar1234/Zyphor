const std = @import("std");
const types = @import("../core/types.zig");
const PlatformCollector = @import("interface.zig").PlatformCollector;

pub const MacosCollector = struct {
    num_cores: u32 = 1,

    pub fn init() MacosCollector {
        var num_cores: u32 = 1;
        if (std.Thread.getCpuCount()) |count| {
            num_cores = @as(u32, @intCast(count));
        } else |_| {
            num_cores = 8;
        }

        return MacosCollector{
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

    pub fn collector(self: *MacosCollector) PlatformCollector {
        return .{
            .ptr = self,
            .vtable = &vtable_impl,
        };
    }

    fn deinit(_: *anyopaque) void {}

    fn getCpuMetrics(ctx: *anyopaque, allocator: std.mem.Allocator) anyerror!types.CpuMetrics {
        const self: *MacosCollector = @ptrCast(@alignCast(ctx));

        var cpu = types.CpuMetrics{
            .logical_cores = self.num_cores,
            .physical_cores = self.num_cores,
            .frequency_mhz = 3200,
            .total_usage = 12.4,
            .user_usage = 8.2,
            .system_usage = 4.2,
            .idle_usage = 87.6,
        };

        const name = "Apple Silicon / M-Series Processor";
        @memcpy(cpu.model_name[0..name.len], name);
        cpu.model_name_len = name.len;

        const cores = try allocator.alloc(f32, self.num_cores);
        var i: usize = 0;
        while (i < self.num_cores) : (i += 1) {
            cores[i] = 10.0 + @as(f32, @floatFromInt((i * 5) % 15));
        }
        cpu.core_usage = cores;

        return cpu;
    }

    fn getMemoryMetrics(_: *anyopaque) anyerror!types.MemoryMetrics {
        const total = 18 * 1024 * 1024 * 1024;
        const used = 11 * 1024 * 1024 * 1024;
        const avail = total - used;

        return types.MemoryMetrics{
            .total_bytes = total,
            .used_bytes = used,
            .available_bytes = avail,
            .free_bytes = avail,
            .cached_bytes = 3 * 1024 * 1024 * 1024,
            .swap_total_bytes = 2 * 1024 * 1024 * 1024,
            .swap_used_bytes = 0,
            .swap_free_bytes = 2 * 1024 * 1024 * 1024,
            .used_percent = 61.1,
            .swap_used_percent = 0.0,
            .pressure_level = .low,
        };
    }

    fn getDiskMetrics(_: *anyopaque, allocator: std.mem.Allocator) anyerror!types.DiskMetrics {
        var partitions = try allocator.alloc(types.DiskPartition, 1);
        partitions[0] = .{
            .total_bytes = 512 * 1024 * 1024 * 1024,
            .used_bytes = 220 * 1024 * 1024 * 1024,
            .free_bytes = 292 * 1024 * 1024 * 1024,
            .used_percent = 42.9,
        };
        const mount = "/System/Volumes/Data";
        @memcpy(partitions[0].mount_point[0..mount.len], mount);
        partitions[0].mount_len = mount.len;

        const fs = "apfs";
        @memcpy(partitions[0].fs_type[0..fs.len], fs);
        partitions[0].fs_len = fs.len;

        return types.DiskMetrics{
            .partitions = partitions,
            .read_bytes_sec = 3_100_000,
            .write_bytes_sec = 1_400_000,
            .iops = 210,
        };
    }

    fn getNetworkMetrics(_: *anyopaque, allocator: std.mem.Allocator) anyerror!types.NetworkMetrics {
        var ifaces = try allocator.alloc(types.NetworkInterface, 1);
        ifaces[0] = .{
            .rx_bytes_sec = 3_400_000,
            .tx_bytes_sec = 620_000,
            .total_rx_bytes = 12_000_000_000,
            .total_tx_bytes = 2_100_000_000,
            .is_up = true,
        };
        const name = "en0";
        @memcpy(ifaces[0].name[0..name.len], name);
        ifaces[0].name_len = name.len;

        const ip = "192.168.1.75";
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
            .utilization_pct = 8.0,
            .vram_total_bytes = 18 * 1024 * 1024 * 1024,
            .vram_used_bytes = 3 * 1024 * 1024 * 1024,
            .temperature_c = 42.0,
        };
        const name = "Apple Metal GPU Core";
        @memcpy(gpu.name[0..name.len], name);
        gpu.name_len = name.len;
        return gpu;
    }

    fn getBatteryMetrics(_: *anyopaque) types.BatteryMetrics {
        return .{
            .available = true,
            .percentage = 88.0,
            .is_charging = false,
            .power_watts = 12.2,
            .time_remaining_mins = 380,
        };
    }

    fn getProcessList(_: *anyopaque, allocator: std.mem.Allocator) anyerror![]types.ProcessInfo {
        const pids = [_]u32{ 1, 85, 340, 1100, 1820 };
        const names = [_][]const u8{ "launchd", "WindowServer", "Finder", "Terminal", "zyphor" };

        var list = try allocator.alloc(types.ProcessInfo, pids.len);
        for (pids, 0..) |pid, idx| {
            var proc = types.ProcessInfo{
                .pid = pid,
                .ppid = if (pid == 1) 0 else 1,
                .cpu_percent = @as(f32, @floatFromInt(idx * 2)) + 0.3,
                .memory_rss = (@as(u64, @intCast(idx + 1)) * 48) * 1024 * 1024,
                .threads_count = @as(u32, @intCast(idx + 4)),
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

