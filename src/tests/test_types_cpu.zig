const std = @import("std");
const types = @import("../core/types.zig");

test "CpuMetrics helper methods and bounds" {
    var cpu = types.CpuMetrics{};
    cpu.total_usage = 45.5;
    cpu.physical_cores = 14;
    cpu.logical_cores = 28;
    cpu.frequency_mhz = 2304;

    const test_name = "Intel Core i7-14700HX";
    @memcpy(cpu.model_name[0..test_name.len], test_name);
    cpu.model_name_len = test_name.len;

    try std.testing.expectEqualStrings(test_name, cpu.getModelName());
    try std.testing.expectEqual(@as(u16, 14), cpu.physical_cores);
    try std.testing.expectEqual(@as(u16, 28), cpu.logical_cores);
}
