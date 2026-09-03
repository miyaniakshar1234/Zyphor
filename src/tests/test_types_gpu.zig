const std = @import("std");
const types = @import("../core/types.zig");

test "GpuMetrics name and VRAM allocation" {
    var gpu = types.GpuMetrics{};
    const name = "NVIDIA GeForce RTX 4050";
    @memcpy(gpu.name[0..name.len], name);
    gpu.name_len = name.len;

    gpu.vram_total_bytes = 6 * 1024 * 1024 * 1024;
    gpu.vram_used_bytes = 2 * 1024 * 1024 * 1024;
    gpu.utilization_pct = 42.0;

    try std.testing.expectEqualStrings(name, gpu.getName());
    try std.testing.expectEqual(@as(f32, 42.0), gpu.utilization_pct);
}
