const std = @import("std");
const types = @import("../core/types.zig");

pub const ProcessTreeNode = struct {
    process: types.ProcessInfo,
    children: std.ArrayList(*ProcessTreeNode) = .empty,
    depth: usize = 0,
    is_expanded: bool = true,
    aggregate_cpu: f32 = 0.0,
    aggregate_rss: u64 = 0,

    pub fn init(allocator: std.mem.Allocator, proc: types.ProcessInfo) !*ProcessTreeNode {
        const node = try allocator.create(ProcessTreeNode);
        node.* = .{
            .process = proc,
            .children = .empty,
            .depth = 0,
            .is_expanded = true,
            .aggregate_cpu = proc.cpu_percent,
            .aggregate_rss = proc.memory_rss,
        };
        return node;
    }

    pub fn deinit(self: *ProcessTreeNode, allocator: std.mem.Allocator) void {
        for (self.children.items) |child| {
            child.deinit(allocator);
        }
        self.children.deinit(allocator);
        allocator.destroy(self);
    }
};

pub const ProcessTree = struct {
    allocator: std.mem.Allocator,
    roots: std.ArrayList(*ProcessTreeNode) = .empty,
    node_map: std.AutoHashMap(u32, *ProcessTreeNode),

    pub fn init(allocator: std.mem.Allocator) ProcessTree {
        return .{
            .allocator = allocator,
            .roots = .empty,
            .node_map = std.AutoHashMap(u32, *ProcessTreeNode).init(allocator),
        };
    }

    pub fn deinit(self: *ProcessTree) void {
        for (self.roots.items) |root| {
            root.deinit(self.allocator);
        }
        self.roots.deinit(self.allocator);
        self.node_map.deinit();
    }

    pub fn build(self: *ProcessTree, processes: []const types.ProcessInfo) !void {
        // Clear previous tree
        for (self.roots.items) |root| {
            root.deinit(self.allocator);
        }
        self.roots.clearRetainingCapacity();
        self.node_map.clearRetainingCapacity();

        // 1. Create nodes for each process
        for (processes) |proc| {
            const node = try ProcessTreeNode.init(self.allocator, proc);
            try self.node_map.put(proc.pid, node);
        }

        // 2. Link parent-child nodes
        for (processes) |proc| {
            const current_node = self.node_map.get(proc.pid) orelse continue;

            if (proc.ppid == 0 or proc.ppid == proc.pid) {
                try self.roots.append(self.allocator, current_node);
            } else if (self.node_map.get(proc.ppid)) |parent_node| {
                current_node.depth = parent_node.depth + 1;
                try parent_node.children.append(self.allocator, current_node);
            } else {
                try self.roots.append(self.allocator, current_node);
            }
        }

        // 3. Compute aggregate resource metrics
        for (self.roots.items) |root| {
            calculateAggregates(root);
        }
    }

    fn calculateAggregates(node: *ProcessTreeNode) void {
        var total_cpu = node.process.cpu_percent;
        var total_rss = node.process.memory_rss;

        for (node.children.items) |child| {
            child.depth = node.depth + 1;
            calculateAggregates(child);
            total_cpu += child.aggregate_cpu;
            total_rss += child.aggregate_rss;
        }

        node.aggregate_cpu = total_cpu;
        node.aggregate_rss = total_rss;
    }

    pub fn flatten(self: *ProcessTree, out_list: *std.ArrayList(types.ProcessInfo)) !void {
        for (self.roots.items, 0..) |root, i| {
            const is_last = (i == self.roots.items.len - 1);
            try self.flattenNode(root, out_list, is_last);
        }
    }

    fn flattenNode(self: *ProcessTree, node: *ProcessTreeNode, out_list: *std.ArrayList(types.ProcessInfo), is_last: bool) !void {
        var info = node.process;
        info.tree_depth = @as(u16, @intCast(node.depth));
        info.is_last_child = is_last;
        try out_list.append(self.allocator, info);

        if (node.is_expanded) {
            for (node.children.items, 0..) |child, i| {
                const child_last = (i == node.children.items.len - 1);
                try self.flattenNode(child, out_list, child_last);
            }
        }
    }
};
