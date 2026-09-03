const std = @import("std");
const types = @import("../core/types.zig");

test "MemoryMetrics percentage and pressure level validation" {
    var mem = types.MemoryMetrics{};
    mem.total_bytes = 32 * 1024 * 1024 * 1024;
    mem.used_bytes = 16 * 1024 * 1024 * 1024;
    mem.used_percent = 50.0;
    mem.pressure_level = .normal;

    try std.testing.expectEqual(@as(f32, 50.0), mem.used_percent);
    try std.testing.expectEqual(types.PressureLevel.normal, mem.pressure_level);
}
