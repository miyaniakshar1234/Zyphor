const std = @import("std");
const types = @import("../core/types.zig");

pub const AlertSeverity = enum {
    info,
    warning,
    critical,

    pub fn asText(self: AlertSeverity) []const u8 {
        return switch (self) {
            .info => "INFO",
            .warning => "WARN",
            .critical => "CRIT",
        };
    }
};

pub const Alert = struct {
    severity: AlertSeverity,
    title: [64]u8 = @splat(0),
    title_len: usize = 0,
    message: [128]u8 = @splat(0),
    message_len: usize = 0,
    timestamp_ms: i64 = 0,

    pub fn getTitle(self: *const Alert) []const u8 {
        return self.title[0..self.title_len];
    }

    pub fn getMessage(self: *const Alert) []const u8 {
        return self.message[0..self.message_len];
    }
};

pub const AlertEngine = struct {
    alerts: std.ArrayList(Alert) = .empty,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) AlertEngine {
        return .{
            .allocator = allocator,
            .alerts = .empty,
        };
    }

    pub fn deinit(self: *AlertEngine) void {
        self.alerts.deinit(self.allocator);
    }

    pub fn evaluate(
        self: *AlertEngine,
        cpu: *const types.CpuMetrics,
        mem: *const types.MemoryMetrics,
        disk: *const types.DiskMetrics,
    ) !void {
        self.alerts.clearRetainingCapacity();

        // 1. Check Memory Pressure
        if (mem.used_percent > 90.0) {
            var alert = Alert{
                .severity = if (mem.used_percent > 95.0) .critical else .warning,
                .timestamp_ms = std.time.milliTimestamp(),
            };
            const title = "High Memory Pressure";
            @memcpy(alert.title[0..title.len], title);
            alert.title_len = title.len;

            var buf: [128]u8 = undefined;
            const msg = std.fmt.bufPrint(&buf, "RAM usage at {d:.1}%. Potential risk of swap thrashing.", .{mem.used_percent}) catch "High memory pressure detected.";
            @memcpy(alert.message[0..msg.len], msg);
            alert.message_len = msg.len;

            try self.alerts.append(self.allocator, alert);
        }

        // 2. Check CPU Usage
        if (!std.math.isNan(cpu.total_usage) and cpu.total_usage > 90.0) {
            var alert = Alert{
                .severity = if (cpu.total_usage > 95.0) .critical else .warning,
                .timestamp_ms = std.time.milliTimestamp(),
            };
            const title = "High CPU Utilization";
            @memcpy(alert.title[0..title.len], title);
            alert.title_len = title.len;

            var buf: [128]u8 = undefined;
            const msg = std.fmt.bufPrint(&buf, "Total CPU load at {d:.1}%. Check top running processes.", .{cpu.total_usage}) catch "High CPU utilization detected.";
            @memcpy(alert.message[0..msg.len], msg);
            alert.message_len = msg.len;

            try self.alerts.append(self.allocator, alert);
        }

        // 3. Check Disk Capacity
        for (disk.partitions) |part| {
            if (!std.math.isNan(part.used_percent) and part.used_percent > 90.0) {
                var alert = Alert{
                    .severity = if (part.used_percent > 95.0) .critical else .warning,
                    .timestamp_ms = std.time.milliTimestamp(),
                };
                const title = "Low Disk Space";
                @memcpy(alert.title[0..title.len], title);
                alert.title_len = title.len;

                var buf: [128]u8 = undefined;
                const msg = std.fmt.bufPrint(&buf, "Mount '{s}' is {d:.1}% full ({d} MB free).", .{ part.getMount(), part.used_percent, part.free_bytes / (1024 * 1024) }) catch "Low storage capacity on partition.";
                @memcpy(alert.message[0..msg.len], msg);
                alert.message_len = msg.len;

                try self.alerts.append(self.allocator, alert);
            }
        }
    }
};

