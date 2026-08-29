const std = @import("std");
const types = @import("../core/types.zig");

pub const BenchmarkResult = struct {
    cpu_single_mops: f64 = 0.0,
    cpu_multi_gflops: f64 = 0.0,
    ram_seq_read_gb_s: f64 = 0.0,
    ram_seq_write_gb_s: f64 = 0.0,
    ram_latency_ns: f64 = 0.0,
    composite_index: u32 = 0,
};

pub fn runBenchmark(allocator: std.mem.Allocator) !BenchmarkResult {
    var result = BenchmarkResult{};

    // 1. Single-Core Integer MOPs (Million Operations Per Second)
    {
        var timer = try std.time.Timer.start();
        var accum: u64 = 0;
        var i: u64 = 0;
        const iters: u64 = 50_000_000;
        while (i < iters) : (i += 1) {
            accum = accum ^ (i *% 2654435761);
        }
        std.mem.doNotOptimizeAway(accum);
        const elapsed_ns = timer.read();
        const elapsed_s = @as(f64, @floatFromInt(elapsed_ns)) / 1_000_000_000.0;
        result.cpu_single_mops = (@as(f64, @floatFromInt(iters)) / 1_000_000.0) / elapsed_s;
    }

    // 2. Multi-Core Floating Point GFLOPS (Parallel Thread Pool)
    {
        const num_threads = if (std.Thread.getCpuCount()) |c| @max(1, @min(@as(usize, @intCast(c)), 64)) else |_| 4;
        const iters_per_thread: u64 = 8_000_000;

        const Worker = struct {
            fn run(iters: u64, out_accum: *f64) void {
                var f_accum: f64 = 1.0;
                var i: u64 = 0;
                while (i < iters) : (i += 1) {
                    f_accum = (f_accum * 1.0000001) + @as(f64, @floatFromInt(i % 100)) * 0.001;
                }
                out_accum.* = f_accum;
            }
        };

        var threads = try allocator.alloc(std.Thread, num_threads);
        defer allocator.free(threads);
        var accums = try allocator.alloc(f64, num_threads);
        defer allocator.free(accums);

        var timer = try std.time.Timer.start();
        for (0..num_threads) |t_idx| {
            threads[t_idx] = try std.Thread.spawn(.{}, Worker.run, .{ iters_per_thread, &accums[t_idx] });
        }
        for (threads) |handle| {
            handle.join();
        }
        const elapsed_ns = timer.read();
        const elapsed_s = @as(f64, @floatFromInt(elapsed_ns)) / 1_000_000_000.0;
        const total_ops = @as(f64, @floatFromInt(iters_per_thread * num_threads * 2));
        result.cpu_multi_gflops = (total_ops / 1_000_000_000.0) / elapsed_s;
    }

    // 3. RAM Sequential Read & Write Bandwidth
    {
        const buf_size = 64 * 1024 * 1024; // 64 MB buffer
        const buffer = try allocator.alloc(u8, buf_size);
        defer allocator.free(buffer);

        // Write test
        var timer = try std.time.Timer.start();
        @memset(buffer, 0xAA);
        std.mem.doNotOptimizeAway(buffer);
        const write_ns = timer.read();
        const write_s = @as(f64, @floatFromInt(write_ns)) / 1_000_000_000.0;
        const gb = @as(f64, @floatFromInt(buf_size)) / (1024.0 * 1024.0 * 1024.0);
        result.ram_seq_write_gb_s = gb / write_s;

        // Read test
        timer.reset();
        var sum: u64 = 0;
        for (buffer) |b| {
            sum +%= b;
        }
        std.mem.doNotOptimizeAway(sum);
        const read_ns = timer.read();
        const read_s = @as(f64, @floatFromInt(read_ns)) / 1_000_000_000.0;
        result.ram_seq_read_gb_s = gb / read_s;

        // Latency test via pointer-chasing cache-line stride (PRD §25)
        const stride_nodes = 262_144; // 256K nodes (16MB span to overflow L1/L2)
        const Node = struct { next: usize };
        const node_buf = try allocator.alloc(Node, stride_nodes);
        defer allocator.free(node_buf);
        var idx: usize = 0;
        while (idx < stride_nodes) : (idx += 1) {
            node_buf[idx].next = (idx *% 1664525 +% 1013904223) % stride_nodes;
        }
        var p_curr: usize = 0;
        var lat_timer = try std.time.Timer.start();
        var step: usize = 0;
        const lat_iters: usize = 2_000_000;
        while (step < lat_iters) : (step += 1) {
            p_curr = node_buf[p_curr].next;
        }
        std.mem.doNotOptimizeAway(p_curr);
        const lat_ns = lat_timer.read();
        result.ram_latency_ns = @as(f64, @floatFromInt(lat_ns)) / @as(f64, @floatFromInt(lat_iters));
    }


    // 4. Compute Composite Benchmark Score
    const cpu_score = result.cpu_single_mops * 1.5 + result.cpu_multi_gflops * 250.0;
    const mem_score = (result.ram_seq_read_gb_s + result.ram_seq_write_gb_s) * 60.0;
    result.composite_index = @as(u32, @intFromFloat(cpu_score + mem_score));

    return result;
}

pub fn printBenchmark(stdout: anytype, result: *const BenchmarkResult, json_mode: bool) !void {
    if (json_mode) {
        try stdout.print(
            \\{{
            \\  "cpu_single_mops": {d:.2},
            \\  "cpu_multi_gflops": {d:.2},
            \\  "ram_seq_read_gb_s": {d:.2},
            \\  "ram_seq_write_gb_s": {d:.2},
            \\  "ram_latency_ns": {d:.1},
            \\  "composite_index": {d}
            \\}}
            \\
        , .{
            result.cpu_single_mops,
            result.cpu_multi_gflops,
            result.ram_seq_read_gb_s,
            result.ram_seq_write_gb_s,
            result.ram_latency_ns,
            result.composite_index,
        });
        return;
    }

    try stdout.print(
        \\==================================================================
        \\  ZYPHOR HARDWARE PERFORMANCE & SUBSYSTEM BENCHMARK (PRD §25)
        \\==================================================================
        \\
        \\  CPU Compute Performance:
        \\    • Single-Core Integer Throughput:  {d:>8.1} MOP/s
        \\    • Multi-Core Floating-Point Rate:  {d:>8.2} GFLOPS
        \\
        \\  Memory Subsystem Bandwidth:
        \\    • Sequential Memory Read:         {d:>8.2} GB/s
        \\    • Sequential Memory Write:        {d:>8.2} GB/s
        \\    • Memory Access Latency:          {d:>8.1} ns
        \\
        \\  Composite Zyphor Hardware Index:     {d} PTS
        \\==================================================================
        \\
    , .{
        result.cpu_single_mops,
        result.cpu_multi_gflops,
        result.ram_seq_read_gb_s,
        result.ram_seq_write_gb_s,
        result.ram_latency_ns,
        result.composite_index,
    });
}
