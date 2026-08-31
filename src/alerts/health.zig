const std = @import("std");
const types = @import("../core/types.zig");

pub fn computeHealthScore(
    cpu: *const types.CpuMetrics,
    mem: *const types.MemoryMetrics,
    disk: *const types.DiskMetrics,
    net: *const types.NetworkMetrics,
) types.SystemHealth {
    _ = net;

    // 1. CPU Score (0-100)
    var cpu_score: f32 = 100.0;
    if (cpu.total_usage > 95.0) {
        cpu_score = 30.0;
    } else if (cpu.total_usage > 85.0) {
        cpu_score = 60.0;
    } else if (cpu.total_usage > 70.0) {
        cpu_score = 80.0;
    }

    if (cpu.temperature_c) |temp| {
        if (temp > 90.0) {
            cpu_score = @min(cpu_score, 40.0);
        } else if (temp > 80.0) {
            cpu_score = @min(cpu_score, 70.0);
        }
    }

    // 2. Memory Score (0-100)
    var mem_score: f32 = 100.0;
    if (mem.used_percent > 95.0 or mem.pressure_level == .critical) {
        mem_score = 25.0;
    } else if (mem.used_percent > 88.0 or mem.pressure_level == .high) {
        mem_score = 55.0;
    } else if (mem.used_percent > 75.0 or mem.pressure_level == .medium) {
        mem_score = 80.0;
    }

    if (mem.swap_used_percent > 20.0) {
        mem_score = @min(mem_score, 60.0);
    }

    // 3. Disk Score (0-100)
    var disk_score: f32 = 100.0;
    for (disk.partitions) |part| {
        if (part.used_percent > 95.0) {
            disk_score = @min(disk_score, 30.0);
        } else if (part.used_percent > 90.0) {
            disk_score = @min(disk_score, 65.0);
        } else if (part.used_percent > 80.0) {
            disk_score = @min(disk_score, 85.0);
        }
    }

    // 4. Thermal Score
    var thermal_score: f32 = 100.0;
    if (cpu.temperature_c) |temp| {
        if (temp > 95.0) {
            thermal_score = 20.0;
        } else if (temp > 85.0) {
            thermal_score = 60.0;
        } else if (temp > 75.0) {
            thermal_score = 85.0;
        }
    }

    // Weighted Overall Score
    // CPU: 30%, Memory: 35%, Disk: 20%, Thermals: 15%
    const raw_total = (cpu_score * 0.30) + (mem_score * 0.35) + (disk_score * 0.20) + (thermal_score * 0.15);
    const safe_total = if (std.math.isNan(raw_total) or std.math.isInf(raw_total) or raw_total < 0.0) 100.0 else raw_total;
    const score_u8 = @as(u8, @intFromFloat(std.math.clamp(safe_total, 0.0, 100.0)));

    const status: types.HealthStatus = if (score_u8 >= 90)
        .excellent
    else if (score_u8 >= 75)
        .good
    else if (score_u8 >= 50)
        .fair
    else if (score_u8 >= 25)
        .poor
    else
        .critical;

    var health = types.SystemHealth{
        .overall_score = score_u8,
        .status = status,
        .cpu_score = @as(u8, @intFromFloat(std.math.clamp(if (std.math.isNan(cpu_score)) 100.0 else cpu_score, 0.0, 100.0))),
        .memory_score = @as(u8, @intFromFloat(std.math.clamp(if (std.math.isNan(mem_score)) 100.0 else mem_score, 0.0, 100.0))),
        .disk_score = @as(u8, @intFromFloat(std.math.clamp(if (std.math.isNan(disk_score)) 100.0 else disk_score, 0.0, 100.0))),
        .network_score = 100,
        .thermal_score = @as(u8, @intFromFloat(std.math.clamp(if (std.math.isNan(thermal_score)) 100.0 else thermal_score, 0.0, 100.0))),
    };


    var summary_buf: [128]u8 = @splat(0);
    const summary_str = switch (status) {
        .excellent => "All subsystems operating within optimal nominal bounds.",
        .good => "System is stable with standard background workload.",
        .fair => "Moderate resource contention detected in memory or CPU.",
        .poor => "High resource pressure: consider closing intensive tasks.",
        .critical => "Critical bottleneck detected: system stability at risk!",
    };
    @memcpy(summary_buf[0..summary_str.len], summary_str);
    health.summary = summary_buf;
    health.summary_len = summary_str.len;

    return health;
}
