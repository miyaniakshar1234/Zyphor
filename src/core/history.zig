const std = @import("std");

pub fn RingBuffer(comptime T: type, comptime Capacity: usize) type {
    return struct {
        const Self = @This();

        buffer: [Capacity]T = [_]T{0} ** Capacity,
        head: usize = 0,
        count: usize = 0,

        pub fn init() Self {
            return Self{};
        }

        pub fn push(self: *Self, value: T) void {
            self.buffer[self.head] = value;
            self.head = (self.head + 1) % Capacity;
            if (self.count < Capacity) {
                self.count += 1;
            }
        }

        pub fn latest(self: *const Self) ?T {
            if (self.count == 0) return null;
            const idx = if (self.head == 0) Capacity - 1 else self.head - 1;
            return self.buffer[idx];
        }

        /// Copies values in chronological order (oldest -> newest) into target slice
        pub fn getChronological(self: *const Self, out: []T) usize {
            const available = @min(self.count, out.len);
            if (available == 0) return 0;

            var start_idx: usize = 0;
            if (self.count == Capacity) {
                start_idx = self.head;
            } else {
                start_idx = 0;
            }

            var i: usize = 0;
            while (i < available) : (i += 1) {
                const idx = (start_idx + i) % Capacity;
                out[i] = self.buffer[idx];
            }
            return available;
        }

        pub fn minMaxAvg(self: *const Self) struct { min: T, max: T, avg: f32 } {
            if (self.count == 0) return .{ .min = 0, .max = 0, .avg = 0.0 };

            var min_v: T = self.buffer[0];
            var max_v: T = self.buffer[0];
            var sum: f64 = 0.0;

            var i: usize = 0;
            while (i < self.count) : (i += 1) {
                const v = self.buffer[i];
                if (v < min_v) min_v = v;
                if (v > max_v) max_v = v;
                sum += @as(f64, @floatCast(v));
            }

            return .{
                .min = min_v,
                .max = max_v,
                .avg = @as(f32, @floatCast(sum / @as(f64, @floatFromInt(self.count)))),
            };
        }
    };
}

pub const SystemHistory = struct {
    cpu_history: RingBuffer(f32, 120) = RingBuffer(f32, 120).init(),
    memory_history: RingBuffer(f32, 120) = RingBuffer(f32, 120).init(),
    net_rx_history: RingBuffer(f32, 120) = RingBuffer(f32, 120).init(),
    net_tx_history: RingBuffer(f32, 120) = RingBuffer(f32, 120).init(),
    disk_read_history: RingBuffer(f32, 120) = RingBuffer(f32, 120).init(),
    disk_write_history: RingBuffer(f32, 120) = RingBuffer(f32, 120).init(),

    pub fn record(
        self: *SystemHistory,
        cpu_usage: f32,
        mem_usage: f32,
        net_rx_mb: f32,
        net_tx_mb: f32,
        disk_r_mb: f32,
        disk_w_mb: f32,
    ) void {
        self.cpu_history.push(cpu_usage);
        self.memory_history.push(mem_usage);
        self.net_rx_history.push(net_rx_mb);
        self.net_tx_history.push(net_tx_mb);
        self.disk_read_history.push(disk_r_mb);
        self.disk_write_history.push(disk_w_mb);
    }
};
