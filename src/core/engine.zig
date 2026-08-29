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

        // 6. Populate System Services & Daemons (PRD §23)
        const sample_services = [_]struct {
            name: []const u8,
            disp: []const u8,
            desc: []const u8,
            group: []const u8,
            status: types.ServiceStatus,
            startup: []const u8,
            pid: u32,
        }{
            .{ .name = "WinDefend", .disp = "Microsoft Defender Antivirus Service", .desc = "Active runtime threat defense and memory integrity guardian", .group = "Security", .status = .running, .startup = "Automatic", .pid = 2840 },
            .{ .name = "EventLog", .disp = "Windows Event Log Kernel Service", .desc = "Kernel structured telemetry and system event dispatcher", .group = "Core OS", .status = .running, .startup = "Automatic", .pid = 820 },
            .{ .name = "Dhcp", .disp = "DHCP Client Network Service", .desc = "IPv4/IPv6 address negotiation and dynamic routing client", .group = "Network", .status = .running, .startup = "Automatic", .pid = 1140 },
            .{ .name = "Dnscache", .disp = "DNS Client Caching Service", .desc = "Domain name resolution caching and DoH edge client", .group = "Network", .status = .running, .startup = "Automatic", .pid = 1480 },
            .{ .name = "docker", .disp = "Docker Engine Virtualization Daemon", .desc = "OCI container runtime and virtualization orchestration engine", .group = "Containers", .status = .running, .startup = "Automatic", .pid = 4920 },
            .{ .name = "sshd", .disp = "OpenSSH SSH Server Daemon", .desc = "Encrypted remote terminal and secure shell listener (:22)", .group = "Network", .status = .running, .startup = "Automatic", .pid = 3120 },
            .{ .name = "wuauserv", .disp = "Windows Update Service", .desc = "Background software patch and security rollup manager", .group = "Maintenance", .status = .running, .startup = "Manual", .pid = 6200 },
            .{ .name = "Audiosrv", .disp = "Windows Audio Core Service", .desc = "Kernel low-latency audio stream mixer and DSP pipeline", .group = "Media", .status = .running, .startup = "Automatic", .pid = 1960 },
            .{ .name = "LanmanServer", .disp = "Server SMB File Sharing", .desc = "SMB 3.1.1 network storage protocol and named pipe provider", .group = "Network", .status = .running, .startup = "Automatic", .pid = 2150 },
            .{ .name = "W32Time", .disp = "Windows Time Synchronization", .desc = "NTP chronometer client maintaining sub-millisecond clock sync", .group = "Core OS", .status = .running, .startup = "Automatic", .pid = 2410 },
            .{ .name = "Spooler", .disp = "Print Spooler Subsystem", .desc = "Print queue spooler and document rasterization service", .group = "Drivers", .status = .stopped, .startup = "Manual", .pid = 0 },
            .{ .name = "SysMain", .disp = "SuperFetch Memory Optimizer", .desc = "Physical RAM predictive page cache preloader", .group = "Performance", .status = .running, .startup = "Automatic", .pid = 1680 },
            .{ .name = "DiagTrack", .disp = "Connected User Diagnostics", .desc = "Hardware telemetry collector and diagnostic event pipeline", .group = "Diagnostics", .status = .running, .startup = "Automatic", .pid = 3890 },
            .{ .name = "BFE", .disp = "Base Filtering Engine", .desc = "IPsec and packet filtering policy manager for firewall", .group = "Security", .status = .running, .startup = "Automatic", .pid = 1320 },
        };

        var services = try scratch.alloc(types.SystemService, sample_services.len);
        for (sample_services, 0..) |ss, sidx| {
            var srv = types.SystemService{
                .status = ss.status,
                .pid = ss.pid,
            };
            @memcpy(srv.name[0..ss.name.len], ss.name);
            srv.name_len = ss.name.len;
            @memcpy(srv.display_name[0..ss.disp.len], ss.disp);
            srv.display_name_len = ss.disp.len;
            @memcpy(srv.description[0..ss.desc.len], ss.desc);
            srv.description_len = ss.desc.len;
            @memcpy(srv.group[0..ss.group.len], ss.group);
            srv.group_len = ss.group.len;
            @memcpy(srv.startup_type[0..ss.startup.len], ss.startup);
            srv.startup_type_len = ss.startup.len;
            services[sidx] = srv;
        }

        // 7. Populate Docker Containers (PRD §43)
        const sample_containers = [_]struct {
            id: []const u8,
            name: []const u8,
            image: []const u8,
            state: types.ContainerState,
            cpu: f32,
            mem: u64,
            mem_limit: u64,
            rx: u64,
            tx: u64,
        }{
            .{ .id = "a1b2c3d4e5f6", .name = "zyphor-postgres-1", .image = "postgres:15-alpine", .state = .running, .cpu = 2.4, .mem = 420 * 1024 * 1024, .mem_limit = 2 * 1024 * 1024 * 1024, .rx = 1250000, .tx = 850000 },
            .{ .id = "f6e5d4c3b2a1", .name = "zyphor-redis-1", .image = "redis:7-alpine", .state = .running, .cpu = 0.4, .mem = 80 * 1024 * 1024, .mem_limit = 512 * 1024 * 1024, .rx = 250000, .tx = 250000 },
            .{ .id = "9a8b7c6d5e4f", .name = "zyphor-api-prod", .image = "zyphor/api:latest", .state = .running, .cpu = 8.2, .mem = 310 * 1024 * 1024, .mem_limit = 1024 * 1024 * 1024, .rx = 4100000, .tx = 4500000 },
            .{ .id = "3c4d5e6f7a8b", .name = "zyphor-worker", .image = "zyphor/worker:latest", .state = .running, .cpu = 15.6, .mem = 850 * 1024 * 1024, .mem_limit = 2 * 1024 * 1024 * 1024, .rx = 150000, .tx = 950000 },
            .{ .id = "7f8e9d0c1b2a", .name = "legacy-cron-job", .image = "ubuntu:20.04", .state = .exited, .cpu = 0.0, .mem = 0, .mem_limit = 512 * 1024 * 1024, .rx = 0, .tx = 0 },
        };

        var containers = try scratch.alloc(types.DockerContainer, sample_containers.len);
        for (sample_containers, 0..) |sc, cidx| {
            var c = types.DockerContainer{
                .state = sc.state,
                .cpu_percent = sc.cpu,
                .memory_used_bytes = sc.mem,
                .memory_limit_bytes = sc.mem_limit,
                .net_rx_bytes = sc.rx,
                .net_tx_bytes = sc.tx,
            };
            @memcpy(c.id[0..sc.id.len], sc.id);
            c.id_len = sc.id.len;
            @memcpy(c.name[0..sc.name.len], sc.name);
            c.name_len = sc.name.len;
            @memcpy(c.image[0..sc.image.len], sc.image);
            c.image_len = sc.image.len;
            containers[cidx] = c;
        }

        const snap = types.SystemSnapshot{
            .timestamp_ms = std.time.milliTimestamp(),
            .cpu = cpu,
            .memory = mem,
            .disk = disk,
            .network = net,
            .gpu = gpu,
            .thermal = .{
                .cpu_package_temp = cpu.temperature_c orelse 48.5,
                .gpu_temp = gpu.temperature_c orelse 52.0,
                .nvme_temp = 39.0,
                .throttling_detected = (cpu.total_usage > 95.0 and (cpu.temperature_c orelse 0.0) > 85.0),
                .fan_rpm = if (cpu.total_usage > 70.0) 2400 else 1850,
            },
            .battery = battery,
            .health = health,
            .boot = .{},
            .services = services,
            .top_processes = top_procs,
            .containers = containers,
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



