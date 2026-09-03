const std = @import("std");
const types = @import("../core/types.zig");

pub const SortField = enum {
    cpu,
    memory,
    pid,
    name,
    threads,
};

pub const SortOrder = enum {
    ascending,
    descending,
};

pub const ProcessManager = struct {
    allocator: std.mem.Allocator,
    raw_processes: std.ArrayList(types.ProcessInfo) = .empty,
    tree_processes: std.ArrayList(types.ProcessInfo) = .empty,
    filtered_indices: std.ArrayList(usize) = .empty,
    sort_field: SortField = .cpu,
    sort_order: SortOrder = .descending,
    active_filter: [64]u8 = @splat(0),
    active_filter_len: usize = 0,
    tree_mode: bool = false,

    pub fn init(allocator: std.mem.Allocator) ProcessManager {
        return .{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *ProcessManager) void {
        self.raw_processes.deinit(self.allocator);
        self.tree_processes.deinit(self.allocator);
        self.filtered_indices.deinit(self.allocator);
    }

    fn rebuildTree(self: *ProcessManager) !void {
        const tree_mod = @import("tree.zig");
        var tree = tree_mod.ProcessTree.init(self.allocator);
        defer tree.deinit();
        try tree.build(self.raw_processes.items);

        self.tree_processes.clearRetainingCapacity();
        try tree.flatten(&self.tree_processes);
    }

    pub fn toggleTreeMode(self: *ProcessManager) !void {
        self.tree_mode = !self.tree_mode;
        if (self.tree_mode) {
            try self.rebuildTree();
        }
        try self.applyFilterAndSort();
    }

    pub fn setFilter(self: *ProcessManager, query: ?[]const u8) !void {
        if (query) |q| {
            const len = @min(q.len, self.active_filter.len);
            @memcpy(self.active_filter[0..len], q[0..len]);
            @memset(self.active_filter[len..], 0);
            self.active_filter_len = len;
        } else {
            @memset(&self.active_filter, 0);
            self.active_filter_len = 0;
        }
        try self.applyFilterAndSort();
    }


    pub fn getFilter(self: *const ProcessManager) ?[]const u8 {
        if (self.active_filter_len == 0) return null;
        return self.active_filter[0..self.active_filter_len];
    }

    pub fn update(self: *ProcessManager, new_procs: []const types.ProcessInfo, filter_query: ?[]const u8) !void {
        if (filter_query) |q| {
            const len = @min(q.len, self.active_filter.len);
            @memcpy(self.active_filter[0..len], q[0..len]);
            self.active_filter_len = len;
        }
        self.raw_processes.clearRetainingCapacity();
        try self.raw_processes.appendSlice(self.allocator, new_procs);

        if (self.tree_mode) {
            try self.rebuildTree();
        }

        try self.applyFilterAndSort();
    }

    pub fn setSort(self: *ProcessManager, field: SortField, order: SortOrder) !void {
        self.sort_field = field;
        self.sort_order = order;
        try self.applyFilterAndSort();
    }

    pub fn applyFilterAndSort(self: *ProcessManager) !void {
        self.filtered_indices.clearRetainingCapacity();

        const active_list = if (self.tree_mode) self.tree_processes.items else self.raw_processes.items;
        const filter = self.getFilter();

        for (active_list, 0..) |proc, idx| {
            if (filter) |query| {
                if (query.len > 0) {
                    const name = proc.getName();
                    var pid_buf: [16]u8 = undefined;
                    const pid_str = std.fmt.bufPrint(&pid_buf, "{d}", .{proc.pid}) catch "";

                    const name_matches = containsIgnoreCase(name, query);
                    const pid_matches = containsIgnoreCase(pid_str, query);

                    if (!name_matches and !pid_matches) {
                        continue;
                    }
                }
            }
            try self.filtered_indices.append(self.allocator, idx);
        }

        if (self.tree_mode) return; // Skip sorting to preserve tree topology

        const field = self.sort_field;
        const order = self.sort_order;

        const Context = struct {
            items: []const types.ProcessInfo,
            field: SortField,
            order: SortOrder,

            pub fn lessThan(ctx: @This(), a_idx: usize, b_idx: usize) bool {
                const first = if (ctx.order == .ascending) ctx.items[a_idx] else ctx.items[b_idx];
                const second = if (ctx.order == .ascending) ctx.items[b_idx] else ctx.items[a_idx];

                return switch (ctx.field) {
                    .cpu => {
                        const a_cpu = if (std.math.isNan(first.cpu_percent) or std.math.isInf(first.cpu_percent) or first.cpu_percent < 0.0) 0.0 else first.cpu_percent;
                        const b_cpu = if (std.math.isNan(second.cpu_percent) or std.math.isInf(second.cpu_percent) or second.cpu_percent < 0.0) 0.0 else second.cpu_percent;
                        if (a_cpu == b_cpu) return first.pid < second.pid;
                        return a_cpu < b_cpu;
                    },
                    .memory => if (first.memory_rss == second.memory_rss) first.pid < second.pid else first.memory_rss < second.memory_rss,
                    .pid => first.pid < second.pid,
                    .name => std.mem.order(u8, first.getName(), second.getName()) == .lt,
                    .threads => if (first.threads_count == second.threads_count) first.pid < second.pid else first.threads_count < second.threads_count,
                };

            }
        };

        const ctx = Context{
            .items = active_list,
            .field = field,
            .order = order,
        };

        std.mem.sort(usize, self.filtered_indices.items, ctx, Context.lessThan);
    }

    pub fn getFilteredCount(self: *const ProcessManager) usize {
        return self.filtered_indices.items.len;
    }

    pub fn getProcessAt(self: *const ProcessManager, filtered_idx: usize) ?types.ProcessInfo {
        if (filtered_idx >= self.filtered_indices.items.len) return null;
        const raw_idx = self.filtered_indices.items[filtered_idx];
        const active_list = if (self.tree_mode) self.tree_processes.items else self.raw_processes.items;
        return active_list[raw_idx];
    }
};

fn containsIgnoreCase(haystack: []const u8, needle: []const u8) bool {
    if (needle.len == 0) return true;
    if (needle.len > haystack.len) return false;

    var i: usize = 0;
    while (i <= haystack.len - needle.len) : (i += 1) {
        var match = true;
        var j: usize = 0;
        while (j < needle.len) : (j += 1) {
            const h = std.ascii.toLower(haystack[i + j]);
            const n = std.ascii.toLower(needle[j]);
            if (h != n) {
                match = false;
                break;
            }
        }
        if (match) return true;
    }
    return false;
}
