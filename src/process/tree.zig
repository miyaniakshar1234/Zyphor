const std = @import("std");
const types = @import("../core/types.zig");

pub const ProcessTreeNode = struct {
    process: types.ProcessInfo,
    children: std.ArrayList(*ProcessTreeNode) = .empty,
    parent: ?*ProcessTreeNode = null,
    depth: usize = 0,
    is_expanded: bool = true,
    aggregate_cpu: f32 = 0.0,
    aggregate_rss: u64 = 0,

    pub fn init(allocator: std.mem.Allocator, proc: types.ProcessInfo) !*ProcessTreeNode {
        const node = try allocator.create(ProcessTreeNode);
        node.* = .{
            .process = proc,
            .children = .empty,
            .parent = null,
            .depth = 0,
            .is_expanded = true,
            .aggregate_cpu = proc.cpu_percent,
            .aggregate_rss = proc.memory_rss,
        };
        return node;
    }

    pub fn deinit(self: *ProcessTreeNode, allocator: std.mem.Allocator) void {
        self.children.deinit(allocator);
        allocator.destroy(self);
    }
};

pub const ProcessTree = struct {
    allocator: std.mem.Allocator,
    all_nodes: std.ArrayList(*ProcessTreeNode) = .empty,
    roots: std.ArrayList(*ProcessTreeNode) = .empty,
    node_map: std.AutoHashMap(u32, *ProcessTreeNode),

    pub fn init(allocator: std.mem.Allocator) ProcessTree {
        return .{
            .allocator = allocator,
            .all_nodes = .empty,
            .roots = .empty,
            .node_map = std.AutoHashMap(u32, *ProcessTreeNode).init(allocator),
        };
    }

    fn clearTree(self: *ProcessTree) void {
        for (self.all_nodes.items) |node| {
            node.deinit(self.allocator);
        }
        self.all_nodes.clearRetainingCapacity();
        self.roots.clearRetainingCapacity();
        self.node_map.clearRetainingCapacity();
    }

    pub fn deinit(self: *ProcessTree) void {
        self.clearTree();
        self.all_nodes.deinit(self.allocator);
        self.roots.deinit(self.allocator);
        self.node_map.deinit();
    }

    fn wouldCreateCycle(child: *const ProcessTreeNode, candidate_parent: *const ProcessTreeNode) bool {
        var cur: ?*const ProcessTreeNode = candidate_parent;
        var d: usize = 0;
        while (cur) |p| : (d += 1) {
            if (p == child) return true;
            if (d > 128) break;
            cur = p.parent;
        }
        return false;
    }

    pub fn build(self: *ProcessTree, processes: []const types.ProcessInfo) !void {
        self.clearTree();

        // 1. Create nodes for each process
        for (processes) |proc| {
            if (self.node_map.contains(proc.pid)) continue;
            const node = try ProcessTreeNode.init(self.allocator, proc);
            try self.all_nodes.append(self.allocator, node);
            try self.node_map.put(proc.pid, node);
        }

        // 2. Link parent-child nodes
        for (processes) |proc| {
            const current_node = self.node_map.get(proc.pid) orelse continue;

            if (proc.ppid != 0 and proc.ppid != proc.pid) {
                if (self.node_map.get(proc.ppid)) |parent_node| {
                    if (!wouldCreateCycle(current_node, parent_node)) {
                        current_node.parent = parent_node;
                        try parent_node.children.append(self.allocator, current_node);
                    }
                }
            }
        }

        // 3. Populate roots with all top-level / unparented nodes
        for (self.all_nodes.items) |node| {
            if (node.parent == null) {
                try self.roots.append(self.allocator, node);
            }
        }

        // 4. Update depths and compute aggregate resource metrics
        for (self.roots.items) |root| {
            updateDepths(root, 0);
            calculateAggregates(root, 0);
        }
    }

    fn updateDepths(node: *ProcessTreeNode, depth: usize) void {
        node.depth = @min(depth, 64);
        for (node.children.items) |child| {
            updateDepths(child, depth + 1);
        }
    }


    fn calculateAggregates(node: *ProcessTreeNode, current_depth: usize) void {
        if (current_depth > 64) return;
        const raw_cpu = node.process.cpu_percent;
        var total_cpu = if (std.math.isNan(raw_cpu) or std.math.isInf(raw_cpu) or raw_cpu < 0.0) 0.0 else raw_cpu;
        var total_rss = node.process.memory_rss;

        for (node.children.items) |child| {
            calculateAggregates(child, current_depth + 1);
            if (!std.math.isNan(child.aggregate_cpu) and !std.math.isInf(child.aggregate_cpu) and child.aggregate_cpu > 0.0) {
                total_cpu += child.aggregate_cpu;
            }
            total_rss += child.aggregate_rss;
        }

        node.aggregate_cpu = total_cpu;
        node.aggregate_rss = total_rss;
    }


    pub fn flatten(self: *ProcessTree, out_list: *std.ArrayList(types.ProcessInfo)) !void {
        for (self.roots.items, 0..) |root, i| {
            const is_last = (i + 1 == self.roots.items.len);
            try self.flattenNode(root, out_list, is_last, 0);
        }
    }

    fn flattenNode(self: *ProcessTree, node: *ProcessTreeNode, out_list: *std.ArrayList(types.ProcessInfo), is_last: bool, depth: usize) !void {
        if (depth > 64) return;
        var info = node.process;
        info.tree_depth = @as(u16, @intCast(@min(node.depth, std.math.maxInt(u16))));
        info.is_last_child = is_last;
        try out_list.append(self.allocator, info);

        if (node.is_expanded) {
            for (node.children.items, 0..) |child, i| {
                const child_last = (i + 1 == node.children.items.len);
                try self.flattenNode(child, out_list, child_last, depth + 1);
            }
        }
    }
};
