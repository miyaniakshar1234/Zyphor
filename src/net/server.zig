const std = @import("std");
const engine_mod = @import("../core/engine.zig");
const export_mod = @import("../cli/export.zig");
const types = @import("../core/types.zig");

pub fn runDaemon(allocator: std.mem.Allocator, engine: *engine_mod.SystemEngine, port: u16) !void {
    const address = try std.net.Address.parseIp("0.0.0.0", port);
    var server = try address.listen(.{
        .reuse_address = true,
    });
    defer server.deinit();

    const stdout = types.getStdout();
    try stdout.print("Zyphor Remote Monitoring Daemon running on tcp://0.0.0.0:{d}\n", .{port});
    try stdout.print("Waiting for incoming requests on /api/snapshot...\n", .{});

    while (true) {
        var connection = server.accept() catch |err| {
            try stdout.print("Error accepting connection: {}\n", .{err});
            continue;
        };
        defer connection.stream.close();

        var buffer: [1024]u8 = undefined;
        const read_len = connection.stream.read(&buffer) catch 0;
        if (read_len == 0) continue;
        
        const req = buffer[0..read_len];
        if (std.mem.indexOf(u8, req, "GET /api/snapshot") != null) {
            const snap = engine.sampleSnapshot() catch |err| {
                try stdout.print("Failed to sample snapshot: {}\n", .{err});
                _ = connection.stream.write("HTTP/1.1 500 Internal Server Error\r\n\r\n") catch {};
                continue;
            };

            var json_buffer: std.ArrayListUnmanaged(u8) = .empty;
            defer json_buffer.deinit(allocator);
            
            try export_mod.printJsonSnapshot(json_buffer.writer(allocator), &snap);
            
            var header_buf: std.ArrayListUnmanaged(u8) = .empty;
            defer header_buf.deinit(allocator);
            try header_buf.writer(allocator).print(
                "HTTP/1.1 200 OK\r\n" ++
                "Content-Type: application/json\r\n" ++
                "Access-Control-Allow-Origin: *\r\n" ++
                "Content-Length: {d}\r\n" ++
                "Connection: close\r\n\r\n",
                .{json_buffer.items.len}
            );

            _ = connection.stream.write(header_buf.items) catch {};
            _ = connection.stream.write(json_buffer.items) catch {};
            
            try stdout.print("[{d}] Served /api/snapshot to remote client.\n", .{std.time.timestamp()});
        } else {
            _ = connection.stream.write("HTTP/1.1 404 Not Found\r\nConnection: close\r\n\r\n") catch {};
        }
    }
}

