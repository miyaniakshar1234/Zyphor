const std = @import("std");
const graphs = @import("../ui/graphs.zig");

test "graphs percentColor threshold mapping" {
    const low = graphs.percentColor(20.0);
    const mid = graphs.percentColor(65.0);
    const high = graphs.percentColor(92.0);

    try std.testing.expect(low.g > 100);
    try std.testing.expect(mid.r > 150 and mid.g > 100);
    try std.testing.expect(high.r > 200 and high.g < 100);
}
