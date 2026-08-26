const std = @import("std");
const types = @import("../core/types.zig");

pub const PlatformCollector = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        getCpuMetrics: *const fn (ctx: *anyopaque, allocator: std.mem.Allocator) anyerror!types.CpuMetrics,
        getMemoryMetrics: *const fn (ctx: *anyopaque) anyerror!types.MemoryMetrics,
        getDiskMetrics: *const fn (ctx: *anyopaque, allocator: std.mem.Allocator) anyerror!types.DiskMetrics,
        getNetworkMetrics: *const fn (ctx: *anyopaque, allocator: std.mem.Allocator) anyerror!types.NetworkMetrics,
        getGpuMetrics: *const fn (ctx: *anyopaque) types.GpuMetrics,
        getBatteryMetrics: *const fn (ctx: *anyopaque) types.BatteryMetrics,
        getProcessList: *const fn (ctx: *anyopaque, allocator: std.mem.Allocator) anyerror![]types.ProcessInfo,
        killProcess: *const fn (ctx: *anyopaque, pid: u32) anyerror!void,
        suspendProcess: *const fn (ctx: *anyopaque, pid: u32) anyerror!void,
        resumeProcess: *const fn (ctx: *anyopaque, pid: u32) anyerror!void,
        deinit: *const fn (ctx: *anyopaque) void,
    };

    pub fn getCpuMetrics(self: PlatformCollector, allocator: std.mem.Allocator) anyerror!types.CpuMetrics {
        return self.vtable.getCpuMetrics(self.ptr, allocator);
    }

    pub fn getMemoryMetrics(self: PlatformCollector) anyerror!types.MemoryMetrics {
        return self.vtable.getMemoryMetrics(self.ptr);
    }

    pub fn getDiskMetrics(self: PlatformCollector, allocator: std.mem.Allocator) anyerror!types.DiskMetrics {
        return self.vtable.getDiskMetrics(self.ptr, allocator);
    }

    pub fn getNetworkMetrics(self: PlatformCollector, allocator: std.mem.Allocator) anyerror!types.NetworkMetrics {
        return self.vtable.getNetworkMetrics(self.ptr, allocator);
    }

    pub fn getGpuMetrics(self: PlatformCollector) types.GpuMetrics {
        return self.vtable.getGpuMetrics(self.ptr);
    }

    pub fn getBatteryMetrics(self: PlatformCollector) types.BatteryMetrics {
        return self.vtable.getBatteryMetrics(self.ptr);
    }

    pub fn getProcessList(self: PlatformCollector, allocator: std.mem.Allocator) anyerror![]types.ProcessInfo {
        return self.vtable.getProcessList(self.ptr, allocator);
    }

    pub fn killProcess(self: PlatformCollector, pid: u32) anyerror!void {
        return self.vtable.killProcess(self.ptr, pid);
    }

    pub fn suspendProcess(self: PlatformCollector, pid: u32) anyerror!void {
        return self.vtable.suspendProcess(self.ptr, pid);
    }

    pub fn resumeProcess(self: PlatformCollector, pid: u32) anyerror!void {
        return self.vtable.resumeProcess(self.ptr, pid);
    }

    pub fn deinit(self: PlatformCollector) void {
        self.vtable.deinit(self.ptr);
    }
};
