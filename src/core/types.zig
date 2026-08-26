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
    model_name: [128]u8 = [_]u8{0} ** 128,
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
    mount_point: [64]u8 = [_]u8{0} ** 64,
    mount_len: usize = 0,
    fs_type: [32]u8 = [_]u8{0} ** 32,
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

pub const DiskMetrics = struct {
    partitions: []DiskPartition = &[_]DiskPartition{},
    read_bytes_sec: u64 = 0,
    write_bytes_sec: u64 = 0,
    iops: u32 = 0,
};

pub const NetworkInterface = struct {
    name: [64]u8 = [_]u8{0} ** 64,
    name_len: usize = 0,
    ip_address: [64]u8 = [_]u8{0} ** 64,
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
    total_rx_sec: u64 = 0,
    total_tx_sec: u64 = 0,
};

pub const GpuMetrics = struct {
    available: bool = false,
    name: [64]u8 = [_]u8{0} ** 64,
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
    name: [64]u8 = [_]u8{0} ** 64,
    name_len: usize = 0,
    cmdline: [256]u8 = [_]u8{0} ** 256,
    cmdline_len: usize = 0,
    user: [32]u8 = [_]u8{0} ** 32,
    user_len: usize = 0,
    cpu_percent: f32 = 0.0,
    memory_rss: u64 = 0,
    memory_vsize: u64 = 0,
    read_bytes_sec: u64 = 0,
    write_bytes_sec: u64 = 0,
    threads_count: u32 = 1,
    state: ProcessState = .running,

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
    summary: [128]u8 = [_]u8{0} ** 128,
    summary_len: usize = 0,

    pub fn getSummary(self: *const SystemHealth) []const u8 {
        if (self.summary_len == 0) return "All subsystems operating within optimal thresholds.";
        return self.summary[0..self.summary_len];
    }
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
    top_processes: []ProcessInfo = &[_]ProcessInfo{},
};
