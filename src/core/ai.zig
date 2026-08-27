const std = @import("std");
const types = @import("types.zig");

pub const AIInsight = struct {
    title: []const u8,
    explanation: []const u8,
    action: []const u8,
    severity: types.HealthStatus,
};

pub fn generateHeuristicInsights(allocator: std.mem.Allocator, snapshot: *const types.SystemSnapshot) ![]AIInsight {
    var insights: std.ArrayListUnmanaged(AIInsight) = .empty;

    const cpu_usage = snapshot.cpu.total_usage;
    const mem_usage = (snapshot.memory.used_bytes * 100) / (snapshot.memory.total_bytes + 1);
    const swap_usage = if (snapshot.memory.swap_total_bytes > 0) 
        (snapshot.memory.swap_used_bytes * 100) / snapshot.memory.swap_total_bytes else 0;

    // CPU Insight
    if (cpu_usage > 85.0) {
        if (snapshot.top_processes.len > 0) {
            const top = snapshot.top_processes[0];
            try insights.append(allocator, .{
                .title = "High CPU Congestion Detected",
                .explanation = try std.fmt.allocPrint(allocator, "The system is under heavy computational load ({d:.1}%). '{s}' is the primary contributor using {d:.1}% of CPU resources.", .{cpu_usage, top.getName(), top.cpu_percent}),
                .action = try std.fmt.allocPrint(allocator, "Consider suspending or terminating PID {d} ({s}) to restore responsiveness.", .{top.pid, top.getName()}),
                .severity = .critical,
            });
        }
    }

    // Memory Insight
    if (mem_usage > 85) {
        var top_mem: ?types.ProcessInfo = null;
        var highest_mem: u64 = 0;
        for (snapshot.top_processes) |p| {
            if (p.memory_vsize > highest_mem) {
                highest_mem = p.memory_vsize;
                top_mem = p;
            }
        }

        if (top_mem) |top| {
            const mem_mb = top.memory_vsize / (1024 * 1024);
            var action_str: []const u8 = "";
            
            if (swap_usage > 20) {
                action_str = try std.fmt.allocPrint(allocator, "Memory pressure is causing increased swap activity (Swap: {d}%). '{s}' is consuming {d} MB.", .{swap_usage, top.getName(), mem_mb});
            } else {
                action_str = try std.fmt.allocPrint(allocator, "'{s}' is currently the largest memory consumer at {d} MB. Check for memory leaks.", .{top.getName(), mem_mb});
            }

            try insights.append(allocator, .{
                .title = "Memory Saturation Risk",
                .explanation = try std.fmt.allocPrint(allocator, "System RAM is {d}% saturated, reducing disk cache capability.", .{mem_usage}),
                .action = action_str,
                .severity = if (mem_usage > 95) .critical else .fair,
            });
        }
    }
    
    // Thermal/Battery Insight
    if ((!snapshot.battery.is_charging) and snapshot.cpu.total_usage > 50.0) {
         try insights.append(allocator, .{
                .title = "Rapid Battery Depletion Expected",
                .explanation = "High CPU load while discharging will significantly reduce battery life.",
                .action = "Switch to a power-saving profile or close background telemetry agents.",
                .severity = .fair,
         });
    }

    // If completely healthy, provide a positive reinforcement insight
    if (insights.items.len == 0) {
         try insights.append(allocator, .{
                .title = "System Operates at Optimal Efficiency",
                .explanation = "No significant bottlenecks, memory leaks, or thermal throttling detected.",
                .action = "No action required. All hardware subsystems are performing within expected margins.",
                .severity = .excellent,
         });
    }

    return insights.toOwnedSlice(allocator);
}




