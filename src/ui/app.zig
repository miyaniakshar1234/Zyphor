const std = @import("std");
const engine_mod = @import("../core/engine.zig");
const types = @import("../core/types.zig");
const terminal_mod = @import("terminal.zig");
const buffer_mod = @import("buffer.zig");
const theme_mod = @import("theme.zig");
const widgets = @import("widgets.zig");

pub const App = struct {
    allocator: std.mem.Allocator,
    engine: *engine_mod.SystemEngine,
    terminal: terminal_mod.Terminal,
    buffer: buffer_mod.ScreenBuffer,
    theme: theme_mod.Theme,
    theme_idx: usize = 0,
    active_tab: widgets.Tab = .overview,
    selected_proc_idx: usize = 0,
    tree_mode: bool = false,
    is_paused: bool = false,
    show_help: bool = false,
    show_inspect_modal: bool = false,
    show_kill_modal: bool = false,
    search_input_active: bool = false,
    search_buffer: [64]u8 = [_]u8{0} ** 64,
    search_len: usize = 0,
    plain_mode: bool = false,
    frame_count: u64 = 0,
    status_msg: [128]u8 = [_]u8{0} ** 128,
    status_len: usize = 0,

    pub fn init(allocator: std.mem.Allocator, engine: *engine_mod.SystemEngine, plain: bool) !App {
        var term = terminal_mod.Terminal.init();
        const win = std.os.windows;
        const DWORD = win.DWORD;
        const STD_OUTPUT_HANDLE: DWORD = @bitCast(@as(i32, -11));
        const STD_INPUT_HANDLE: DWORD = @bitCast(@as(i32, -10));
        const kernel32 = struct {
            extern "kernel32" fn GetStdHandle(n: DWORD) callconv(.winapi) ?win.HANDLE;
        };
        term.h_in  = kernel32.GetStdHandle(STD_INPUT_HANDLE);
        term.h_out = kernel32.GetStdHandle(STD_OUTPUT_HANDLE);

        const size = term.getSize();
        const buf = try buffer_mod.ScreenBuffer.init(allocator, size.width, size.height);
        const th = if (plain) theme_mod.BuiltinThemes.no_color else theme_mod.BuiltinThemes.midnight;

        return App{
            .allocator = allocator,
            .engine = engine,
            .terminal = term,
            .buffer = buf,
            .theme = th,
            .plain_mode = plain,
        };
    }

    pub fn deinit(self: *App) void {
        self.terminal.exitRawMode();
        self.buffer.deinit();
    }

    pub fn run(self: *App) !void {
        try self.terminal.enterRawMode();
        defer self.terminal.exitRawMode();

        const stdout = types.getStdout();
        var should_quit = false;
        var last_size = self.terminal.getSize();

        while (!should_quit) {
            // 0. Check for terminal resize
            const cur_size = self.terminal.getSize();
            if (cur_size.width != last_size.width or cur_size.height != last_size.height) {
                last_size = cur_size;
                try self.buffer.resize(cur_size.width, cur_size.height);
                try stdout.writeAll("\x1b[2J\x1b[H");
            }

            // 1. Sample telemetry
            const snapshot = if (!self.is_paused)
                try self.engine.sampleSnapshot()
            else
                self.engine.lastSnapshot();

            const current_search = if (self.search_len > 0) self.search_buffer[0..self.search_len] else null;

            // 2. Render viewport into double buffer
            self.buffer.clear(self.theme.bg);
            widgets.renderBackgroundGrid(&self.buffer, &self.theme);

            widgets.renderHeader(&self.buffer, &self.theme, &snapshot.health, self.plain_mode);
            widgets.renderTabs(&self.buffer, self.active_tab, &self.theme, current_search);

            switch (self.active_tab) {
                .overview => {
                    widgets.renderOverviewPanel(&self.buffer, &snapshot, &self.engine.history, &self.theme, self.plain_mode);
                },
                .processes => {
                    widgets.renderProcessPanel(&self.buffer, snapshot.top_processes, self.selected_proc_idx, self.tree_mode, &self.theme, self.plain_mode, current_search);
                },
                .disks => {
                    widgets.renderDiskPanel(&self.buffer, &snapshot.disk, &self.theme, self.plain_mode);
                },
                .network => {
                    widgets.renderNetworkPanel(&self.buffer, &snapshot.network, &self.engine.history, &self.theme, self.plain_mode);
                },
                .diagnostics => {
                    widgets.renderDiagnosticsPanel(&self.buffer, &snapshot.health, self.engine.alert_engine.alerts.items, &self.theme, self.plain_mode);
                },
            }

            if (self.is_paused) {
                self.setStatus("⏸ PAUSED — Press Space to resume");
            }

            const status = if (self.status_len > 0) self.status_msg[0..self.status_len] else "";
            const search_str = if (self.search_len > 0) self.search_buffer[0..self.search_len] else "";
            widgets.renderStatusBar(&self.buffer, &self.theme, status, self.search_input_active, search_str);

            // Modals rendered on top
            if (self.show_inspect_modal) {
                if (snapshot.top_processes.len > 0 and self.selected_proc_idx < snapshot.top_processes.len) {
                    const proc = &snapshot.top_processes[self.selected_proc_idx];
                    widgets.renderProcessInspectModal(&self.buffer, proc, &self.theme, self.plain_mode);
                }
            } else if (self.show_kill_modal) {
                if (snapshot.top_processes.len > 0 and self.selected_proc_idx < snapshot.top_processes.len) {
                    const proc = &snapshot.top_processes[self.selected_proc_idx];
                    widgets.renderKillConfirmModal(&self.buffer, proc, &self.theme, self.plain_mode);
                }
            } else if (self.show_help) {
                widgets.renderHelpModal(&self.buffer, &self.theme, self.plain_mode);
            }

            // 3. Differential flush to terminal
            try self.buffer.flush(stdout);

            self.frame_count += 1;

            if (self.status_len > 0 and self.frame_count % 8 == 0 and !self.is_paused) {
                self.status_len = 0;
            }

            // 4. Non-blocking input handling
            std.Thread.sleep(200 * std.time.ns_per_ms);
            if (self.terminal.readKey()) |key| {
                const proc_count = snapshot.top_processes.len;

                // Mode A: Search input mode
                if (self.search_input_active) {
                    switch (key) {
                        .char => |c| {
                            if (c >= 32 and c < 127 and self.search_len < self.search_buffer.len) {
                                self.search_buffer[self.search_len] = c;
                                self.search_len += 1;
                                try self.engine.process_mgr.setFilter(self.search_buffer[0..self.search_len]);
                                self.selected_proc_idx = 0;
                            }
                        },
                        .backspace => {
                            if (self.search_len > 0) {
                                self.search_len -= 1;
                                const filter_slice = if (self.search_len > 0) self.search_buffer[0..self.search_len] else null;
                                try self.engine.process_mgr.setFilter(filter_slice);
                                self.selected_proc_idx = 0;
                            }
                        },
                        .enter => {
                            self.search_input_active = false;
                            self.setStatus("Search filter applied");
                        },
                        .escape => {
                            self.search_input_active = false;
                            self.search_len = 0;
                            try self.engine.process_mgr.setFilter(null);
                            self.setStatus("Search cleared");
                        },
                        else => {},
                    }
                    continue;
                }

                // Mode B: Modal active
                if (self.show_inspect_modal) {
                    switch (key) {
                        .escape, .enter => self.show_inspect_modal = false,
                        .char => |c| switch (c) {
                            'x' => {
                                self.show_inspect_modal = false;
                                self.show_kill_modal = true;
                            },
                            's' => {
                                if (snapshot.top_processes.len > 0 and self.selected_proc_idx < snapshot.top_processes.len) {
                                    const proc = &snapshot.top_processes[self.selected_proc_idx];
                                    var col = self.engine.platform.getCollector();
                                    col.suspendProcess(proc.pid) catch {};
                                    self.setStatus("Process suspended (SIGSTOP)");
                                }
                            },
                            'u' => {
                                if (snapshot.top_processes.len > 0 and self.selected_proc_idx < snapshot.top_processes.len) {
                                    const proc = &snapshot.top_processes[self.selected_proc_idx];
                                    var col = self.engine.platform.getCollector();
                                    col.resumeProcess(proc.pid) catch {};
                                    self.setStatus("Process resumed (SIGCONT)");
                                }
                            },
                            else => {},
                        },
                        else => {},
                    }
                    continue;
                }

                if (self.show_kill_modal) {
                    switch (key) {
                        .char => |c| switch (c) {
                            'y', 'Y' => {
                                if (snapshot.top_processes.len > 0 and self.selected_proc_idx < snapshot.top_processes.len) {
                                    const proc = &snapshot.top_processes[self.selected_proc_idx];
                                    var col = self.engine.platform.getCollector();
                                    if (col.killProcess(proc.pid)) |_| {
                                        self.setStatus("✓ Process terminated");
                                    } else |_| {
                                        self.setStatus("✗ Failed to terminate process (Access Denied)");
                                    }
                                }
                                self.show_kill_modal = false;
                            },
                            'n', 'N' => self.show_kill_modal = false,
                            else => {},
                        },
                        .escape => self.show_kill_modal = false,
                        else => {},
                    }
                    continue;
                }

                if (self.show_help) {
                    self.show_help = false;
                    continue;
                }

                // Mode C: Standard Navigation
                switch (key) {
                    .char => |c| switch (c) {
                        'q', 3 => should_quit = true,
                        '?' => self.show_help = true,
                        '/' => {
                            self.search_input_active = true;
                            self.active_tab = .processes;
                        },
                        't' => {
                            self.tree_mode = !self.tree_mode;
                            try self.engine.process_mgr.toggleTreeMode();
                            self.setStatus(if (self.tree_mode) "Tree view enabled" else "Flat view enabled");
                        },
                        ' ' => {
                            self.is_paused = !self.is_paused;
                            if (!self.is_paused) self.status_len = 0;
                        },
                        '1' => self.active_tab = .overview,
                        '2' => self.active_tab = .processes,
                        '3' => self.active_tab = .disks,
                        '4' => self.active_tab = .network,
                        '5' => self.active_tab = .diagnostics,
                        'c' => {
                            try self.engine.process_mgr.setSort(.cpu, .descending);
                            self.setStatus("Sort: CPU% descending");
                        },
                        'm' => {
                            try self.engine.process_mgr.setSort(.memory, .descending);
                            self.setStatus("Sort: Memory RSS descending");
                        },
                        'p' => {
                            try self.engine.process_mgr.setSort(.pid, .ascending);
                            self.setStatus("Sort: PID ascending");
                        },
                        'n' => {
                            try self.engine.process_mgr.setSort(.name, .ascending);
                            self.setStatus("Sort: Name A-Z");
                        },
                        'T' => self.cycleTheme(),
                        'x' => {
                            if (proc_count > 0 and self.selected_proc_idx < proc_count) {
                                self.show_kill_modal = true;
                            }
                        },
                        'j' => {
                            if (self.selected_proc_idx + 1 < proc_count) self.selected_proc_idx += 1;
                        },
                        'k' => {
                            if (self.selected_proc_idx > 0) self.selected_proc_idx -= 1;
                        },
                        'g' => self.selected_proc_idx = 0,
                        'G' => self.selected_proc_idx = if (proc_count > 0) proc_count - 1 else 0,
                        else => {},
                    },
                    .enter => {
                        if (self.active_tab == .processes and proc_count > 0 and self.selected_proc_idx < proc_count) {
                            self.show_inspect_modal = true;
                        }
                    },
                    .tab => {
                        self.active_tab = switch (self.active_tab) {
                            .overview    => .processes,
                            .processes   => .disks,
                            .disks       => .network,
                            .network     => .diagnostics,
                            .diagnostics => .overview,
                        };
                        self.selected_proc_idx = 0;
                    },
                    .shift_tab => {
                        self.active_tab = switch (self.active_tab) {
                            .overview    => .diagnostics,
                            .processes   => .overview,
                            .disks       => .processes,
                            .network     => .disks,
                            .diagnostics => .network,
                        };
                    },
                    .down => {
                        if (self.selected_proc_idx + 1 < proc_count) self.selected_proc_idx += 1;
                    },
                    .up => {
                        if (self.selected_proc_idx > 0) self.selected_proc_idx -= 1;
                    },
                    .page_down => {
                        const page = @as(usize, self.buffer.height / 2);
                        self.selected_proc_idx = @min(self.selected_proc_idx + page, if (proc_count > 0) proc_count - 1 else 0);
                    },
                    .page_up => {
                        const page = @as(usize, self.buffer.height / 2);
                        self.selected_proc_idx = if (self.selected_proc_idx > page) self.selected_proc_idx - page else 0;
                    },
                    .home => self.selected_proc_idx = 0,
                    .end  => self.selected_proc_idx = if (proc_count > 0) proc_count - 1 else 0,
                    .escape => {
                        if (self.show_help) self.show_help = false;
                        if (self.show_inspect_modal) self.show_inspect_modal = false;
                        if (self.show_kill_modal) self.show_kill_modal = false;
                        if (self.search_len > 0) {
                            self.search_len = 0;
                            try self.engine.process_mgr.setFilter(null);
                            self.setStatus("Filter cleared");
                        }
                    },
                    else => {},
                }
            }
        }
    }

    fn cycleTheme(self: *App) void {
        if (self.plain_mode) return;
        self.theme_idx = (self.theme_idx + 1) % theme_mod.ALL_THEMES.len;
        self.theme = theme_mod.ALL_THEMES[self.theme_idx];
        const sentinel = buffer_mod.Cell{
            .char = .{ 0, 0, 0, 0 },
            .char_len = 1,
            .fg = theme_mod.Color.rgb(1, 1, 1),
            .bg = theme_mod.Color.rgb(2, 2, 2),
            .dirty = true,
        };
        @memset(self.buffer.prev_cells, sentinel);
        self.setStatus(std.fmt.bufPrint(&self.status_msg, "Theme: {s}", .{self.theme.name}) catch "Theme changed");
        self.status_len = std.mem.indexOfScalar(u8, &self.status_msg, 0) orelse self.status_msg.len;
    }

    fn setStatus(self: *App, msg: []const u8) void {
        const len = @min(msg.len, self.status_msg.len);
        @memcpy(self.status_msg[0..len], msg[0..len]);
        self.status_len = len;
        self.frame_count = 0;
    }
};
