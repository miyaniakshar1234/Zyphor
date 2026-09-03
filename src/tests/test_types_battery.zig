const std = @import("std");
const types = @import("../core/types.zig");

test "BatteryMetrics charging and availability flags" {
    var batt = types.BatteryMetrics{};
    batt.available = true;
    batt.percentage = 85.0;
    batt.is_charging = true;

    try std.testing.expect(batt.available);
    try std.testing.expect(batt.is_charging);
    try std.testing.expectEqual(@as(f32, 85.0), batt.percentage);
}
