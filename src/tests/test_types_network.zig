const std = @import("std");
const types = @import("../core/types.zig");

test "NetworkInterface name and link speed" {
    var iface = types.NetworkInterface{};
    const name = "Wi-Fi";
    @memcpy(iface.name[0..name.len], name);
    iface.name_len = name.len;

    iface.rx_bytes_sec = 1024 * 1024;
    iface.tx_bytes_sec = 512 * 1024;
    iface.is_up = true;

    try std.testing.expectEqualStrings(name, iface.getName());
    try std.testing.expect(iface.is_up);
    try std.testing.expectEqual(@as(u64, 1048576), iface.rx_bytes_sec);
}
