const std = @import("std");
const types = @import("../core/types.zig");
const health = @import("../alerts/health.zig");

test "computeHealthScore socket density penalties" {
    const cpu = types.CpuMetrics{ .total_usage = 10.0 };
    const mem = types.MemoryMetrics{ .used_percent = 30.0 };
    const disk = types.DiskMetrics{};

    // Nominal network
    var net_normal = types.NetworkMetrics{};
    net_normal.active_connections = 20;
    const h1 = health.computeHealthScore(&cpu, &mem, &disk, &net_normal);

    // Saturated network sockets
    var net_heavy = types.NetworkMetrics{};
    net_heavy.active_connections = 600;
    const h2 = health.computeHealthScore(&cpu, &mem, &disk, &net_heavy);

    try std.testing.expect(h1.overall_score > h2.overall_score);
}
