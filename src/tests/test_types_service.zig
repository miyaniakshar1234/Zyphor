const std = @import("std");
const types = @import("../core/types.zig");

test "SystemService status and startup string mapping" {
    var srv = types.SystemService{};
    srv.status = .running;
    const name = "EventLog";
    @memcpy(srv.name[0..name.len], name);
    srv.name_len = name.len;

    try std.testing.expectEqualStrings(name, srv.getName());
    try std.testing.expectEqual(types.ServiceStatus.running, srv.status);
    try std.testing.expectEqualStrings("Running", srv.status.asText());
}
