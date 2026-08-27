const std = @import("std");
const types = @import("../core/types.zig");

pub const ProfilerState = enum {
    idle,
    running,
    finished,
    error_state,
};

pub const ProfilerResult = struct {
    pid: u32,
    name: [64]u8,
    name_len: usize,
    duration_secs: u32,
    samples: u32,
    
    cpu_avg: f32,
    cpu_max: f32,
    cpu_min: f32,
    
    mem_avg: u64,
    mem_max: u64,
    mem_min: u64,

    // Sample history for sparkline (up to 120 samples)
    cpu_history: [120]f32 = [_]f32{0} ** 120,
    mem_history: [120]u64 = [_]u64{0} ** 120,
    history_len: usize = 0,
};

pub const ProcessProfiler = struct {
    state: ProfilerState = .idle,
    target_pid: u32 = 0,
    target_name: [64]u8 = @splat(0),
    target_name_len: usize = 0,
    
    duration_secs: u32 = 10,
    elapsed_ms: u64 = 0,
    
    result: ProfilerResult = undefined,
    error_msg: [64]u8 = @splat(0),
    
    pub fn start(self: *ProcessProfiler, pid: u32, name: []const u8, duration: u32) void {
        self.state = .running;
        self.target_pid = pid;
        
        const len = @min(name.len, 64);
        @memcpy(self.target_name[0..len], name[0..len]);
        self.target_name_len = len;
        
        self.duration_secs = duration;
        self.elapsed_ms = 0;
        
        self.result = .{
            .pid = pid,
            .name = self.target_name,
            .name_len = self.target_name_len,
            .duration_secs = duration,
            .samples = 0,
            .cpu_avg = 0,
            .cpu_max = 0,
            .cpu_min = 999999.0,
            .mem_avg = 0,
            .mem_max = 0,
            .mem_min = 999999999999,
        };
    }
    
    pub fn addSample(self: *ProcessProfiler, cpu: f32, mem: u64) void {
        if (self.state != .running) return;
        
        const r = &self.result;
        
        // Rolling average
        const f_samples = @as(f32, @floatFromInt(r.samples));
        r.cpu_avg = ((r.cpu_avg * f_samples) + cpu) / (f_samples + 1.0);
        
        // Exact integer average for memory to avoid precision loss on large values
        const total_mem = (r.mem_avg * r.samples) + mem;
        r.samples += 1;
        r.mem_avg = total_mem / r.samples;
        
        if (cpu > r.cpu_max) r.cpu_max = cpu;
        if (cpu < r.cpu_min) r.cpu_min = cpu;
        
        if (mem > r.mem_max) r.mem_max = mem;
        if (mem < r.mem_min) r.mem_min = mem;
        
        if (r.history_len < 120) {
            r.cpu_history[r.history_len] = cpu;
            r.mem_history[r.history_len] = mem;
            r.history_len += 1;
        } else {
            // Shift left
            std.mem.copyForwards(f32, r.cpu_history[0..119], r.cpu_history[1..120]);
            std.mem.copyForwards(u64, r.mem_history[0..119], r.mem_history[1..120]);
            r.cpu_history[119] = cpu;
            r.mem_history[119] = mem;
        }
    }
};
