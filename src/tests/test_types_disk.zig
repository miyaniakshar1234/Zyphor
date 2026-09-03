const std = @import("std");
const types = @import("../core/types.zig");

test "DiskPartition mount and filesystem helpers" {
    var part = types.DiskPartition{};
    const mount = "C:\\";
    @memcpy(part.mount_point[0..mount.len], mount);
    part.mount_point_len = mount.len;

    const fs = "NTFS";
    @memcpy(part.filesystem[0..fs.len], fs);
    part.filesystem_len = fs.len;

    part.total_bytes = 500 * 1024 * 1024 * 1024;
    part.used_bytes = 250 * 1024 * 1024 * 1024;
    part.used_percent = 50.0;

    try std.testing.expectEqualStrings(mount, part.getMount());
    try std.testing.expectEqualStrings(fs, part.getFs());
    try std.testing.expectEqual(@as(f32, 50.0), part.used_percent);
}
