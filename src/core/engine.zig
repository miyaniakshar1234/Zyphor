const std = @import("std");
const plugin_mod = @import("plugin.zig");
const docker_plugin = @import("../plugins/docker.zig");
const types = @import("types.zig");
const config_mod = @import("config.zig");
const history_mod = @import("history.zig");
const platform_mod = @import("../platform/platform.zig");
const process_mod = @import("../process/manager.zig");
const tree_mod = @import("../process/tree.zig");
const health_mod = @import("../alerts/health.zig");
const alert_mod = @import("../alerts/engine.zig");

pub const SystemEngine = struct {
    plugins: plugin_mod.PluginManager = .{},
    docker_plug: docker_plugin.DockerPlugin = .{},
    allocator: std.mem.Allocator,
    arenas: [2]std.heap.ArenaAllocator,
    active_arena_idx: usize = 0,
    platform: platform_mod.PlatformManager,
    process_mgr: process_mod.ProcessManager,
    process_tree: tree_mod.ProcessTree,
    history: history_mod.SystemHistory,
    alert_engine: alert_mod.AlertEngine,
    config: config_mod.Config,
    flight_recorder: FlightRecorder = .{},
    cached: types.SystemSnapshot = .{},

    pub fn init(allocator: std.mem.Allocator) SystemEngine {
        return .{
            .allocator = allocator,
            .arenas = [2]std.heap.ArenaAllocator{
                std.heap.ArenaAllocator.init(allocator),
                std.heap.ArenaAllocator.init(allocator),
            },
            .active_arena_idx = 0,
            .platform = platform_mod.PlatformManager.init(),
            .process_mgr = process_mod.ProcessManager.init(allocator),
            .process_tree = tree_mod.ProcessTree.init(allocator),
            .history = history_mod.SystemHistory{},
            .alert_engine = alert_mod.AlertEngine.init(allocator),
            .config = config_mod.Config{},
            .flight_recorder = .{},
        };
    }


    pub fn deinit(self: *SystemEngine) void {
        self.arenas[0].deinit();
        self.arenas[1].deinit();
        self.process_mgr.deinit();
        self.process_tree.deinit();
        self.alert_engine.deinit();
        self.platform.deinit();
    }


    pub fn sampleSnapshot(self: *SystemEngine) !types.SystemSnapshot {
        // Double-buffer arena swap: advance to the next arena slot and reset only the incoming slot
        self.active_arena_idx = (self.active_arena_idx + 1) % 2;
        _ = self.arenas[self.active_arena_idx].reset(.retain_capacity);
        const scratch = self.arenas[self.active_arena_idx].allocator();

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

        // 5. Select Top 100 processes
        const top_count = @min(100, self.process_mgr.getFilteredCount());
        var top_procs = try scratch.alloc(types.ProcessInfo, top_count);
        var i: usize = 0;
        while (i < top_count) : (i += 1) {
            top_procs[i] = self.process_mgr.getProcessAt(i) orelse types.ProcessInfo{};
        }

        // 6. Collect Real System Services & Daemons from Platform Collector
        const services = collector.getServices(scratch) catch &[_]types.SystemService{};

        // 7. Containers (Docker Engine API - empty until active daemon connected)
        const containers = &[_]types.DockerContainer{};

        // 8. Real System & Kernel Event Logs from Platform Collector
        const logs = collector.getSystemLogs(scratch) catch &[_]types.SystemLogEvent{};

        const snap = types.SystemSnapshot{
            .timestamp_ms = std.time.milliTimestamp(),
            .cpu = cpu,
            .memory = mem,
            .disk = disk,
            .network = net,
            .gpu = gpu,
            .thermal = .{
                .cpu_package_temp = cpu.temperature_c orelse 0.0,
                .gpu_temp = gpu.temperature_c orelse 0.0,
                .nvme_temp = 0.0,
                .throttling_detected = false,
                .fan_rpm = 0,
            },
            .battery = battery,
            .health = health,
            .boot = .{},
            .services = services,
            .top_processes = top_procs,
            .containers = containers,
            .system_logs = logs,
        };
        self.cached = snap;
        self.flight_recorder.record(snap);
        return snap;
    }


    /// Return the last sampled snapshot without re-sampling (for pause mode)
    pub fn lastSnapshot(self: *const SystemEngine) types.SystemSnapshot {

        return self.cached;
    }
};

pub const FlightRecorder = struct {
    snapshots: [60]types.SystemSnapshot = undefined,
    count: usize = 0,
    write_idx: usize = 0,

    pub fn record(self: *FlightRecorder, snap: types.SystemSnapshot) void {
        self.snapshots[self.write_idx] = snap;
        self.write_idx = (self.write_idx + 1) % 60;
        if (self.count < 60) self.count += 1;
    }

    pub fn getFrame(self: *const FlightRecorder, frame_back: usize) ?types.SystemSnapshot {
        if (self.count == 0 or frame_back >= self.count) return null;
        const idx = (self.write_idx + 60 - 1 - frame_back) % 60;
        return self.snapshots[idx];
    }
};



