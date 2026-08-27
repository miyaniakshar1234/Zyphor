const std = @import("std");
const types = @import("types.zig");

pub const Plugin = struct {
    name: []const u8,
    ctx: *anyopaque,
    
    initFn: *const fn (ctx: *anyopaque, allocator: std.mem.Allocator) anyerror!void,
    updateFn: *const fn (ctx: *anyopaque, snapshot: *types.SystemSnapshot, allocator: std.mem.Allocator) anyerror!void,
    deinitFn: *const fn (ctx: *anyopaque, allocator: std.mem.Allocator) void,

    pub fn init(self: *const Plugin, allocator: std.mem.Allocator) !void {
        if (self.initFn != undefined) try self.initFn(self.ctx, allocator);
    }
    pub fn update(self: *const Plugin, snapshot: *types.SystemSnapshot, allocator: std.mem.Allocator) !void {
        if (self.updateFn != undefined) try self.updateFn(self.ctx, snapshot, allocator);
    }
    pub fn deinit(self: *const Plugin, allocator: std.mem.Allocator) void {
        if (self.deinitFn != undefined) self.deinitFn(self.ctx, allocator);
    }
};

pub const PluginManager = struct {
    plugins: std.ArrayListUnmanaged(Plugin) = .empty,

    pub fn register(self: *PluginManager, allocator: std.mem.Allocator, plugin: Plugin) !void {
        try self.plugins.append(allocator, plugin);
    }

    pub fn initializeAll(self: *PluginManager, allocator: std.mem.Allocator) !void {
        for (self.plugins.items) |p| {
            try p.init(allocator);
        }
    }

    pub fn updateAll(self: *PluginManager, snapshot: *types.SystemSnapshot, allocator: std.mem.Allocator) !void {
        for (self.plugins.items) |p| {
            try p.update(snapshot, allocator);
        }
    }

    pub fn deinitAll(self: *PluginManager, allocator: std.mem.Allocator) void {
        for (self.plugins.items) |p| {
            p.deinit(allocator);
        }
        self.plugins.deinit(allocator);
    }
};
