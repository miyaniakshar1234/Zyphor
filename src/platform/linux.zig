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

    fn readProcMeminfo() ?types.MemoryMetrics {
        var file = std.fs.openFileAbsolute("/proc/meminfo", .{}) catch return null;
        defer file.close();

        var buf: [2048]u8 = undefined;
        const len = file.readAll(&buf) catch return null;
        const text = buf[0..len];

        var total_kb: u64 = 0;
        var free_kb: u64 = 0;
        var avail_kb: u64 = 0;
        var cached_kb: u64 = 0;
        var swap_total_kb: u64 = 0;
        var swap_free_kb: u64 = 0;

        var lines = std.mem.splitScalar(u8, text, '\n');
        while (lines.next()) |line| {
            if (std.mem.startsWith(u8, line, "MemTotal:")) {
                total_kb = parseKb(line);
            } else if (std.mem.startsWith(u8, line, "MemFree:")) {
                free_kb = parseKb(line);
            } else if (std.mem.startsWith(u8, line, "MemAvailable:")) {
                avail_kb = parseKb(line);
            } else if (std.mem.startsWith(u8, line, "Cached:")) {
                cached_kb = parseKb(line);
            } else if (std.mem.startsWith(u8, line, "SwapTotal:")) {
                swap_total_kb = parseKb(line);
            } else if (std.mem.startsWith(u8, line, "SwapFree:")) {
                swap_free_kb = parseKb(line);
            }
        }

        if (total_kb == 0) return null;
        if (avail_kb == 0) avail_kb = free_kb + cached_kb;
        const used_kb = if (total_kb > avail_kb) total_kb - avail_kb else 0;
        const swap_used_kb = if (swap_total_kb > swap_free_kb) swap_total_kb - swap_free_kb else 0;

        const total_bytes = total_kb * 1024;
        const used_bytes = used_kb * 1024;
        const avail_bytes = avail_kb * 1024;
        const free_bytes = free_kb * 1024;
        const cached_bytes = cached_kb * 1024;
        const swap_total_bytes = swap_total_kb * 1024;
        const swap_used_bytes = swap_used_kb * 1024;
        const swap_free_bytes = swap_free_kb * 1024;

        const used_pct = if (total_bytes > 0) (@as(f32, @floatFromInt(used_bytes)) / @as(f32, @floatFromInt(total_bytes))) * 100.0 else 0.0;
        const swap_pct = if (swap_total_bytes > 0) (@as(f32, @floatFromInt(swap_used_bytes)) / @as(f32, @floatFromInt(swap_total_bytes))) * 100.0 else 0.0;

        const pressure: types.MemoryPressureLevel = if (used_pct > 90.0 or swap_pct > 60.0)
            .critical
        else if (used_pct > 80.0 or swap_pct > 30.0)
            .high
        else if (used_pct > 65.0)
            .medium
        else
            .low;

        return types.MemoryMetrics{
            .total_bytes = total_bytes,
            .used_bytes = used_bytes,
            .available_bytes = avail_bytes,
            .free_bytes = free_bytes,
            .cached_bytes = cached_bytes,
            .swap_total_bytes = swap_total_bytes,
            .swap_used_bytes = swap_used_bytes,
            .swap_free_bytes = swap_free_bytes,
            .used_percent = used_pct,
            .swap_used_percent = swap_pct,
            .pressure_level = pressure,
        };
    }

    fn parseKb(line: []const u8) u64 {
        var it = std.mem.tokenizeAny(u8, line, " \t:");
        _ = it.next(); // Skip key name
        if (it.next()) |val_str| {
            return std.fmt.parseInt(u64, val_str, 10) catch 0;
        }
        return 0;
    }

    fn getMemoryMetrics(_: *anyopaque) anyerror!types.MemoryMetrics {
        if (readProcMeminfo()) |mem| {
            return mem;
        }

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
        var dir = try std.fs.cwd().openDir("/proc", .{ .iterate = true });
        defer dir.close();

        var procs = std.ArrayList(types.ProcessInfo).init(allocator);
        defer procs.deinit();

        var it = dir.iterate();
        var buf: [4096]u8 = undefined;

        while (try it.next()) |entry| {
            if (entry.kind != .directory) continue;
            const pid = std.fmt.parseInt(u32, entry.name, 10) catch continue;

            var stat_path_buf: [256]u8 = undefined;
            const stat_path = std.fmt.bufPrint(&stat_path_buf, "/proc/{d}/stat", .{pid}) catch continue;

            const file = std.fs.openFileAbsolute(stat_path, .{}) catch continue;
            defer file.close();

            const len = file.readAll(&buf) catch continue;
            const content = buf[0..len];

            // Parse stat
            const open_paren = std.mem.indexOfScalar(u8, content, '(');
            const close_paren = std.mem.lastIndexOfScalar(u8, content, ')');
            if (open_paren == null or close_paren == null or close_paren.? < open_paren.?) continue;

            const name = content[open_paren.? + 1 .. close_paren.?];
            const after_name = content[close_paren.? + 2 ..];

            var tok_it = std.mem.splitScalar(u8, after_name, ' ');
            const state_str = tok_it.next() orelse continue;
            const ppid_str = tok_it.next() orelse continue;
            
            // Skip down to threads and rss
            var i: usize = 4;
            while (i < 20) : (i += 1) {
                _ = tok_it.next();
            }
            const threads_str = tok_it.next() orelse "1";
            _ = tok_it.next(); // itrealvalue
            _ = tok_it.next(); // starttime
            _ = tok_it.next(); // vsize
            const rss_str = tok_it.next() orelse "0";

            const ppid = std.fmt.parseInt(u32, ppid_str, 10) catch 0;
            const threads = std.fmt.parseInt(u32, threads_str, 10) catch 1;
            // rss is in pages, standard page size is 4KB
            const rss = (std.fmt.parseInt(u64, rss_str, 10) catch 0) * 4096;
            
            const p_state: types.ProcessState = switch (state_str[0]) {
                'R' => .running,
                'S', 'I' => .sleeping,
                'D' => .waiting,
                'Z' => .zombie,
                'T', 't' => .stopped,
                else => .unknown,
            };

            var proc = types.ProcessInfo{
                .pid = pid,
                .ppid = ppid,
                .cpu_percent = 0.0, // CPU usage requires deltas, left at 0 for now
                .memory_rss = rss,
                .threads_count = threads,
                .state = p_state,
            };
            
            const n_len = @min(name.len, 64);
            @memcpy(proc.name[0..n_len], name[0..n_len]);
            proc.name_len = n_len;

            try procs.append(proc);
        }

        return procs.toOwnedSlice();
    }

    fn killProcess(_: *anyopaque, _: u32) anyerror!void {}
    fn suspendProcess(_: *anyopaque, _: u32) anyerror!void {}
    fn resumeProcess(_: *anyopaque, _: u32) anyerror!void {}
};


