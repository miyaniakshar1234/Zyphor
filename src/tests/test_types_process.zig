const std = @import("std");
const types = @import("../core/types.zig");

test "ProcessInfo name trimming and metrics" {
    var proc = types.ProcessInfo{
        .pid = 1337,
        .ppid = 1,
        .cpu_percent = 12.5,
        .memory_rss = 64 * 1024 * 1024,
    };
    const name = "zyphor.exe";
    @memcpy(proc.name[0..name.len], name);
    proc.name_len = name.len;

    try std.testing.expectEqualStrings(name, proc.getName());
    try std.testing.expectEqual(@as(u32, 1337), proc.pid);
    try std.testing.expectEqual(@as(f32, 12.5), proc.cpu_percent);
}
