const std = @import("std");

pub const OutWriter = struct {
    file: std.fs.File,

    pub fn print(self: OutWriter, comptime fmt: []const u8, args: anytype) !void {
        var buf: [8192]u8 = undefined;
        const msg = try std.fmt.bufPrint(&buf, fmt, args);
        try self.file.writeAll(msg);
    }

    pub fn writeAll(self: OutWriter, bytes: []const u8) !void {
        try self.file.writeAll(bytes);
    }
};

pub fn getStdout() OutWriter {
    return .{ .file = std.fs.File.stdout() };
}

pub const ProcessState = enum {
    running,
    sleeping,
    disk_sleep,
    stopped,
    zombie,
    unknown,

    pub fn toChar(self: ProcessState) u8 {
        return switch (self) {
            .running => 'R',
            .sleeping => 'S',
            .disk_sleep => 'D',
            .stopped => 'T',
            .zombie => 'Z',
            .unknown => '?',
        };
    }

    pub fn asText(self: ProcessState) []const u8 {
        return switch (self) {
            .running => "Running",
            .sleeping => "Sleeping",
            .disk_sleep => "Disk Sleep",
            .stopped => "Stopped",
            .zombie => "Zombie",
            .unknown => "Unknown",
        };
    }
};

pub const MemoryPressureLevel = enum {
    low,
    medium,
    high,
    critical,

    pub fn asText(self: MemoryPressureLevel) []const u8 {
        return switch (self) {
            .low => "LOW (Healthy)",
            .medium => "MEDIUM (Moderate)",
            .high => "HIGH (Contention)",
            .critical => "CRITICAL (Thrashing)",
        };
    }
};

pub const HealthStatus = enum {
    excellent,
    good,
    fair,
    poor,
    critical,

    pub fn asText(self: HealthStatus) []const u8 {
        return switch (self) {
            .excellent => "EXCELLENT",
            .good => "GOOD",
            .fair => "FAIR",
            .poor => "POOR",
            .critical => "CRITICAL",
        };
    }
};

pub const CpuMetrics = struct {
    total_usage: f32 = 0.0,
    user_usage: f32 = 0.0,
    system_usage: f32 = 0.0,
    idle_usage: f32 = 100.0,
    iowait_usage: f32 = 0.0,
    frequency_mhz: u32 = 0,
    logical_cores: u32 = 1,
    physical_cores: u32 = 1,
    core_usage: []f32 = &[_]f32{},
    temperature_c: ?f32 = null,
    model_name: [128]u8 = @splat(0),
    model_name_len: usize = 0,

    pub fn getModelName(self: *const CpuMetrics) []const u8 {
        if (self.model_name_len == 0) return "Generic Processor";
        return self.model_name[0..self.model_name_len];
    }
};

pub const MemoryMetrics = struct {
    total_bytes: u64 = 0,
    used_bytes: u64 = 0,
    free_bytes: u64 = 0,
    available_bytes: u64 = 0,
    cached_bytes: u64 = 0,
    swap_total_bytes: u64 = 0,
    swap_used_bytes: u64 = 0,
    swap_free_bytes: u64 = 0,
    used_percent: f32 = 0.0,
    swap_used_percent: f32 = 0.0,
    pressure_level: MemoryPressureLevel = .low,
};

pub const DiskPartition = struct {
    mount_point: [64]u8 = @splat(0),
    mount_len: usize = 0,
    fs_type: [32]u8 = @splat(0),
    fs_len: usize = 0,
    total_bytes: u64 = 0,
    used_bytes: u64 = 0,
    free_bytes: u64 = 0,
    used_percent: f32 = 0.0,

    pub fn getMount(self: *const DiskPartition) []const u8 {
        return self.mount_point[0..self.mount_len];
    }

    pub fn getFs(self: *const DiskPartition) []const u8 {
        return self.fs_type[0..self.fs_len];
    }
};

pub const DirectoryNode = struct {
    name: [64]u8 = @splat(0),
    name_len: usize = 0,
    size_bytes: u64 = 0,
    file_count: u32 = 0,
    used_percent: f32 = 0.0,
    depth: u8 = 0,

    pub fn getName(self: *const DirectoryNode) []const u8 {
        return self.name[0..self.name_len];
    }
};

pub const DiskMetrics = struct {
    partitions: []DiskPartition = &[_]DiskPartition{},
    top_directories: []DirectoryNode = &[_]DirectoryNode{},
    read_bytes_sec: u64 = 0,
    write_bytes_sec: u64 = 0,
    iops: u32 = 0,
};

pub const ConnectionState = enum {
    established,
    listen,
    time_wait,
    close_wait,
    syn_sent,
    syn_recv,
    fin_wait,
    closed,

    pub fn asText(self: ConnectionState) []const u8 {
        return switch (self) {
            .established => "ESTABLISHED",
            .listen => "LISTEN",
            .time_wait => "TIME_WAIT",
            .close_wait => "CLOSE_WAIT",
            .syn_sent => "SYN_SENT",
            .syn_recv => "SYN_RECV",
            .fin_wait => "FIN_WAIT",
            .closed => "CLOSED",
        };
    }
};

pub const NetworkConnection = struct {
    pid: u32 = 0,
    process_name: [64]u8 = @splat(0),
    process_name_len: usize = 0,
    proto_tcp: bool = true,
    local_port: u16 = 0,
    remote_addr: [32]u8 = @splat(0),
    remote_addr_len: usize = 0,
    remote_port: u16 = 0,
    state: ConnectionState = .listen,

    pub fn getProcessName(self: *const NetworkConnection) []const u8 {
        if (self.process_name_len == 0) return "system";
        return self.process_name[0..self.process_name_len];
    }

    pub fn getRemoteAddr(self: *const NetworkConnection) []const u8 {
        if (self.remote_addr_len == 0) return "*";
        return self.remote_addr[0..self.remote_addr_len];
    }
};

pub const NetworkInterface = struct {
    name: [64]u8 = @splat(0),
    name_len: usize = 0,
    ip_address: [64]u8 = @splat(0),
    ip_len: usize = 0,
    rx_bytes_sec: u64 = 0,
    tx_bytes_sec: u64 = 0,
    total_rx_bytes: u64 = 0,
    total_tx_bytes: u64 = 0,
    is_up: bool = true,

    pub fn getName(self: *const NetworkInterface) []const u8 {
        return self.name[0..self.name_len];
    }

    pub fn getIp(self: *const NetworkInterface) []const u8 {
        return self.ip_address[0..self.ip_len];
    }
};

pub const NetworkMetrics = struct {
    interfaces: []NetworkInterface = &[_]NetworkInterface{},
    connections: []NetworkConnection = &[_]NetworkConnection{},
    total_rx_sec: u64 = 0,
    total_tx_sec: u64 = 0,
};

pub const GpuMetrics = struct {
    available: bool = false,
    name: [64]u8 = @splat(0),
    name_len: usize = 0,
    utilization_pct: f32 = 0.0,
    vram_total_bytes: u64 = 0,
    vram_used_bytes: u64 = 0,
    temperature_c: ?f32 = null,

    pub fn getName(self: *const GpuMetrics) []const u8 {
        if (!self.available or self.name_len == 0) return "No GPU Detected";
        return self.name[0..self.name_len];
    }
};

pub const BatteryMetrics = struct {
    available: bool = false,
    percentage: f32 = 100.0,
    is_charging: bool = false,
    power_watts: ?f32 = null,
    time_remaining_mins: ?u32 = null,
};

pub const ProcessInfo = struct {
    pid: u32 = 0,
    ppid: u32 = 0,
    name: [64]u8 = @splat(0),
    name_len: usize = 0,
    cmdline: [256]u8 = @splat(0),
    cmdline_len: usize = 0,
    user: [32]u8 = @splat(0),
    user_len: usize = 0,
    cpu_percent: f32 = 0.0,
    memory_rss: u64 = 0,
    memory_vsize: u64 = 0,
    read_bytes_sec: u64 = 0,
    write_bytes_sec: u64 = 0,
    threads_count: u32 = 1,
    state: ProcessState = .running,
    tree_depth: u16 = 0,
    is_last_child: bool = false,

    pub fn getName(self: *const ProcessInfo) []const u8 {
        return self.name[0..self.name_len];
    }

    pub fn getCmdline(self: *const ProcessInfo) []const u8 {
        return self.cmdline[0..self.cmdline_len];
    }

    pub fn getUser(self: *const ProcessInfo) []const u8 {
        if (self.user_len == 0) return "system";
        return self.user[0..self.user_len];
    }
};

pub const SystemHealth = struct {
    overall_score: u8 = 100,
    status: HealthStatus = .excellent,
    cpu_score: u8 = 100,
    memory_score: u8 = 100,
    disk_score: u8 = 100,
    network_score: u8 = 100,
    thermal_score: u8 = 100,
    summary: [128]u8 = @splat(0),
    summary_len: usize = 0,

    pub fn getSummary(self: *const SystemHealth) []const u8 {
        if (self.summary_len == 0) return "All subsystems operating within optimal thresholds.";
        return self.summary[0..self.summary_len];
    }
};

pub const ServiceStatus = enum {
    running,
    stopped,
    paused,
    start_pending,
    stop_pending,
    unknown,

    pub fn asText(self: ServiceStatus) []const u8 {
        return switch (self) {
            .running => "RUNNING",
            .stopped => "STOPPED",
            .paused => "PAUSED",
            .start_pending => "STARTING",
            .stop_pending => "STOPPING",
            .unknown => "UNKNOWN",
        };
    }
};

pub const SystemService = struct {
    name: [64]u8 = @splat(0),
    name_len: usize = 0,
    display_name: [128]u8 = @splat(0),
    display_name_len: usize = 0,
    status: ServiceStatus = .running,
    startup_type: [32]u8 = @splat(0),
    startup_type_len: usize = 0,

    pub fn getName(self: *const SystemService) []const u8 {
        return self.name[0..self.name_len];
    }

    pub fn getDisplayName(self: *const SystemService) []const u8 {
        if (self.display_name_len == 0) return self.getName();
        return self.display_name[0..self.display_name_len];
    }

    pub fn getStartupType(self: *const SystemService) []const u8 {
        if (self.startup_type_len == 0) return "Automatic";
        return self.startup_type[0..self.startup_type_len];
    }
};

pub const BootAnalysis = struct {
    total_boot_s: f32 = 7.42,
    kernel_time_s: f32 = 1.42,
    services_time_s: f32 = 2.31,
    user_session_s: f32 = 3.69,
    startup_apps_count: u32 = 14,
};

pub const SystemSnapshot = struct {
    timestamp_ms: i64 = 0,
    cpu: CpuMetrics = .{},
    memory: MemoryMetrics = .{},
    disk: DiskMetrics = .{},
    network: NetworkMetrics = .{},
    gpu: GpuMetrics = .{},
    battery: BatteryMetrics = .{},
    health: SystemHealth = .{},
    boot: BootAnalysis = .{},
    services: []SystemService = &[_]SystemService{},
    top_processes: []ProcessInfo = &[_]ProcessInfo{},
};
