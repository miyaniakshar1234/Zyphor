const std = @import("std");
const types = @import("types.zig");
const config_mod = @import("config.zig");
const history_mod = @import("history.zig");
const platform_mod = @import("../platform/platform.zig");
const process_mod = @import("../process/manager.zig");
const tree_mod = @import("../process/tree.zig");
const health_mod = @import("../alerts/health.zig");
const alert_mod = @import("../alerts/engine.zig");

pub const SystemEngine = struct {
    allocator: std.mem.Allocator,
    scratch_arena: std.heap.ArenaAllocator,
    platform: platform_mod.PlatformManager,
    process_mgr: process_mod.ProcessManager,
    process_tree: tree_mod.ProcessTree,
    history: history_mod.SystemHistory,
    alert_engine: alert_mod.AlertEngine,
    config: config_mod.Config,

    pub fn init(allocator: std.mem.Allocator) SystemEngine {
        return .{
            .allocator = allocator,
            .scratch_arena = std.heap.ArenaAllocator.init(allocator),
            .platform = platform_mod.PlatformManager.init(),
            .process_mgr = process_mod.ProcessManager.init(allocator),
            .process_tree = tree_mod.ProcessTree.init(allocator),
            .history = history_mod.SystemHistory{},
            .alert_engine = alert_mod.AlertEngine.init(allocator),
            .config = config_mod.Config{},
        };
    }

    pub fn deinit(self: *SystemEngine) void {
        self.scratch_arena.deinit();
        self.process_mgr.deinit();
        self.process_tree.deinit();
        self.alert_engine.deinit();
    }

    pub fn sampleSnapshot(self: *SystemEngine) !types.SystemSnapshot {
        _ = self.scratch_arena.reset(.retain_capacity);
        const scratch = self.scratch_arena.allocator();

        var collector = self.platform.getCollector();

        // 1. Collect Core Subsystems
        const cpu = try collector.getCpuMetrics(scratch);
        const mem = try collector.getMemoryMetrics();
        const disk = try collector.getDiskMetrics(scratch);
        const net = try collector.getNetworkMetrics(scratch);
        const gpu = collector.getGpuMetrics();
        const battery = collector.getBatteryMetrics();

        // 2. Collect Processes
        const procs = try collector.getProcessList(scratch);
        try self.process_mgr.update(procs, null);
        try self.process_tree.build(procs);

        // 3. Compute System Health & Alerts
        const health = health_mod.computeHealthScore(&cpu, &mem, &disk, &net);
        try self.alert_engine.evaluate(&cpu, &mem, &disk);

        // 4. Update History
        const net_rx_mb = @as(f32, @floatFromInt(net.total_rx_sec)) / (1024.0 * 1024.0);
        const net_tx_mb = @as(f32, @floatFromInt(net.total_tx_sec)) / (1024.0 * 1024.0);
        const disk_r_mb = @as(f32, @floatFromInt(disk.read_bytes_sec)) / (1024.0 * 1024.0);
        const disk_w_mb = @as(f32, @floatFromInt(disk.write_bytes_sec)) / (1024.0 * 1024.0);

        self.history.record(
            cpu.total_usage,
            mem.used_percent,
            net_rx_mb,
            net_tx_mb,
            disk_r_mb,
            disk_w_mb,
        );

        // 5. Select Top 20 processes
        const top_count = @min(20, self.process_mgr.getFilteredCount());
        var top_procs = try scratch.alloc(types.ProcessInfo, top_count);
        var i: usize = 0;
        while (i < top_count) : (i += 1) {
            top_procs[i] = self.process_mgr.getProcessAt(i) orelse types.ProcessInfo{};
        }

        return types.SystemSnapshot{
            .timestamp_ms = std.time.milliTimestamp(),
            .cpu = cpu,
            .memory = mem,
            .disk = disk,
            .network = net,
            .gpu = gpu,
            .battery = battery,
            .health = health,
            .top_processes = top_procs,
        };
    }
};
