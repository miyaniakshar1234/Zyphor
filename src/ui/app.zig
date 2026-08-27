const std = @import("std");
const builtin = @import("builtin");
const engine_mod = @import("../core/engine.zig");
const types = @import("../core/types.zig");
const terminal_mod = @import("terminal.zig");
const buffer_mod = @import("buffer.zig");
const theme_mod = @import("theme.zig");
const widgets = @import("widgets.zig");
const speedtest_mod = @import("../net/speedtest.zig");
const profiler_mod = @import("../process/profiler.zig");

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
    show_profiler_modal: bool = false,
    process_profiler: profiler_mod.ProcessProfiler = .{},
    show_kill_modal: bool = false,
    show_speedtest_modal: bool = false,
    show_stress_modal: bool = false,
    speedtest_result: ?speedtest_mod.SpeedTestResult = null,
    stress_result: ?speedtest_mod.StressTestResult = null,
    speedtest_tracker: speedtest_mod.LiveSpeedTestTracker = .{},
    stress_tracker: speedtest_mod.LiveStressTestTracker = .{},
    speedtest_thread: ?std.Thread = null,
    stress_thread: ?std.Thread = null,
    stress_duration_secs: u32 = 10,
    stress_streams: u32 = 8,
    search_input_active: bool = false,
    search_buffer: [64]u8 = @splat(0),
    search_len: usize = 0,
    show_palette: bool = false,
    palette_idx: usize = 0,
    plain_mode: bool = false,
    frame_count: u64 = 0,
    status_msg: [128]u8 = @splat(0),
    status_len: usize = 0,

    pub fn init(allocator: std.mem.Allocator, engine: *engine_mod.SystemEngine, plain: bool) !App {
        var term = terminal_mod.Terminal.init();
        if (builtin.os.tag == .windows) {
            const win = std.os.windows;
            const DWORD = win.DWORD;
            const STD_OUTPUT_HANDLE: DWORD = @bitCast(@as(i32, -11));
            const STD_INPUT_HANDLE: DWORD = @bitCast(@as(i32, -10));
            const kernel32 = struct {
                extern "kernel32" fn GetStdHandle(n: DWORD) callconv(.winapi) ?win.HANDLE;
            };
            term.h_in  = kernel32.GetStdHandle(STD_INPUT_HANDLE);
            term.h_out = kernel32.GetStdHandle(STD_OUTPUT_HANDLE);
        }

        const size = term.getSize();
        const buf = try buffer_mod.ScreenBuffer.init(allocator, size.width, size.height);
        const th = if (plain) theme_mod.BuiltinThemes.no_color else theme_mod.BuiltinThemes.anthropic;

        return App{
            .allocator = allocator,
            .engine = engine,
            .terminal = term,
            .buffer = buf,
            .theme = th,
            .theme_idx = 0,
            .plain_mode = plain,
        };
    }

    pub fn triggerSpeedTest(self: *App) void {
        if (!self.speedtest_tracker.is_running) {
            self.show_speedtest_modal = true;
            self.speedtest_result = null;
            self.speedtest_tracker = .{};
            if (self.speedtest_thread) |t| t.detach();
            self.speedtest_thread = speedtest_mod.startSpeedTestThread(self.allocator, &self.speedtest_tracker) catch null;
            self.setStatus("⚡ Speedtest probing initiated in background...");
        }
    }

    pub fn triggerStressTest(self: *App, dur: u32, streams: u32) void {
        if (!self.stress_tracker.is_running) {
            self.show_stress_modal = true;
            self.stress_result = null;
            self.stress_tracker = .{};
            if (self.stress_thread) |t| t.detach();
            self.stress_thread = speedtest_mod.startStressTestThread(self.allocator, dur, streams, &self.stress_tracker) catch null;
            self.setStatus("🌪️ Multi-stream stress test initiated in background...");
        }
    }

    pub fn deinit(self: *App) void {
        if (self.speedtest_thread) |t| t.detach();
        if (self.stress_thread) |t| t.detach();
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
                self.buffer.resize(cur_size.width, cur_size.height) catch {};
            }

            // 1. Sample system telemetry snapshot
            const snapshot = if (self.is_paused)
                self.engine.lastSnapshot()
            else
                try self.engine.sampleSnapshot();

            if (self.process_profiler.state == .running) {
                var found = false;
                for (snapshot.top_processes) |p| {
                    if (p.pid == self.process_profiler.target_pid) {
                        self.process_profiler.addSample(p.cpu_percent, p.memory_vsize);
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    self.process_profiler.addSample(0.0, 0);
                }
                
                // Add fixed 33ms or 200ms depending on modals (approximate tick time)
                const tick_ms = if (self.show_speedtest_modal or self.show_stress_modal or self.show_profiler_modal) @as(u64, 33) else @as(u64, 200);
                self.process_profiler.elapsed_ms += tick_ms;
                
                if (self.process_profiler.elapsed_ms >= self.process_profiler.duration_secs * 1000) {
                    self.process_profiler.state = .finished;
                }
            }

            // 2. Render UI Layers
            self.buffer.clear(self.theme.bg);

            const current_search = if (self.search_len > 0) self.search_buffer[0..self.search_len] else null;

            widgets.renderBackgroundGrid(&self.buffer, &self.theme);

            widgets.renderHeader(&self.buffer, &self.theme, &snapshot, self.plain_mode);
            widgets.renderTabs(&self.buffer, self.active_tab, &self.theme, current_search);

            switch (self.active_tab) {
                .overview => {
                    widgets.renderOverviewPanel(&self.buffer, &snapshot, &self.engine.history, &self.theme, self.plain_mode);
                },
                .processes => {
                    widgets.renderProcessPanel(&self.buffer, snapshot.top_processes, self.selected_proc_idx, self.tree_mode, &self.theme, self.plain_mode, current_search);
                },
                .disks => {
                    widgets.renderDiskPanel(&self.buffer, &snapshot.disk, &self.engine.history, &self.theme, self.plain_mode);
                },
                .network => {
                    const net_res_ptr: ?*const speedtest_mod.SpeedTestResult = if (self.speedtest_result) |*r| r else null; widgets.renderNetworkPanel(&self.buffer, &snapshot.network, &self.engine.history, &self.theme, self.plain_mode, &self.speedtest_tracker, net_res_ptr);
                },
                                .diagnostics => {
                    widgets.renderDiagnosticsPanel(&self.buffer, &snapshot, self.engine.alert_engine.alerts.items, &self.theme, self.plain_mode);
                },
                                .services => {
                    widgets.renderServicesPanel(&self.buffer, snapshot.services, self.selected_proc_idx, &self.theme, self.plain_mode, current_search);
                },
                .containers => {
                    widgets.renderContainersPanel(&self.buffer, snapshot.containers, self.selected_proc_idx, &self.theme, self.plain_mode, current_search);
                },
            }

            if (self.is_paused) {
                self.setStatus("⏸ PAUSED — Press Space to resume");
            }

            const status = if (self.status_len > 0) self.status_msg[0..self.status_len] else "";
            const search_str = if (self.search_len > 0) self.search_buffer[0..self.search_len] else "";
            widgets.renderStatusBar(&self.buffer, &self.theme, status, self.search_input_active, search_str);

            // Modals rendered on top
            if (self.show_palette) {
                widgets.renderCommandPalette(&self.buffer, self.palette_idx, &self.theme, self.plain_mode);
            } else if (self.show_inspect_modal) {
                if (snapshot.top_processes.len > 0 and self.selected_proc_idx < snapshot.top_processes.len) {
                    const proc = &snapshot.top_processes[self.selected_proc_idx];
                    widgets.renderProcessInspectModal(&self.buffer, proc, &self.theme, self.plain_mode);
                }
            } else if (self.show_kill_modal) {
                if (snapshot.top_processes.len > 0 and self.selected_proc_idx < snapshot.top_processes.len) {
                    const proc = &snapshot.top_processes[self.selected_proc_idx];
                    widgets.renderKillConfirmModal(&self.buffer, proc, &self.theme, self.plain_mode);
                }
            } else if (self.show_profiler_modal) {
                widgets.renderProfilerModal(&self.buffer, &self.process_profiler, &self.theme, self.plain_mode);
            } else if (self.show_speedtest_modal) {
                if (self.speedtest_tracker.has_result and self.speedtest_result == null) {
                    self.speedtest_result = self.speedtest_tracker.final_result;
                }
                const res_ptr: ?*const speedtest_mod.SpeedTestResult = if (self.speedtest_result) |*r| r else null;
                widgets.renderSpeedTestModal(&self.buffer, &self.speedtest_tracker, res_ptr, self.frame_count, &self.theme, self.plain_mode);
            } else if (self.show_stress_modal) {
                if (self.stress_tracker.has_result and self.stress_result == null) {
                    self.stress_result = self.stress_tracker.final_result;
                }
                const res_ptr: ?*const speedtest_mod.StressTestResult = if (self.stress_result) |*r| r else null;
                widgets.renderStressTestModal(&self.buffer, &self.stress_tracker, res_ptr, self.frame_count, &self.theme, self.plain_mode, self.stress_duration_secs, self.stress_streams);
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
                        if (self.show_speedtest_modal or self.show_stress_modal or self.show_profiler_modal) {
                            std.Thread.sleep(33 * std.time.ns_per_ms);
                        } else {
                std.Thread.sleep(200 * std.time.ns_per_ms);
            }
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

                if (self.show_profiler_modal) {
                    switch (key) {
                        .escape, .enter => self.show_profiler_modal = false,
                        .char => |c| switch (c) {
                            'q' => self.show_profiler_modal = false,
                            else => {},
                        },
                        else => {},
                    }
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

                if (self.show_speedtest_modal) {
                    switch (key) {
                        .escape, .enter => self.show_speedtest_modal = false,
                        .char => |c| switch (c) {
                            'r', 'R' => self.triggerSpeedTest(),
                            'S' => {
                                self.show_speedtest_modal = false;
                                self.triggerStressTest(self.stress_duration_secs, self.stress_streams);
                            },
                            'q' => self.show_speedtest_modal = false,
                            else => {},
                        },
                        else => {},
                    }
                    continue;
                }

                if (self.show_stress_modal) {
                    switch (key) {
                        .escape => self.show_stress_modal = false,
                        .enter => {
                            if (!self.stress_tracker.is_running and !self.stress_tracker.has_result) {
                                self.triggerStressTest(self.stress_duration_secs, self.stress_streams);
                            } else {
                                self.show_stress_modal = false;
                            }
                        },
                        .char => |c| switch (c) {
                            'r', 'R' => {
                                if (self.stress_tracker.has_result or self.stress_tracker.is_running) {
                                    self.triggerStressTest(self.stress_duration_secs, self.stress_streams);
                                }
                            },
                            '1' => self.stress_duration_secs = 10,
                            '2' => self.stress_duration_secs = 30,
                            '3' => self.stress_duration_secs = 60,
                            '4' => self.stress_duration_secs = 300,
                            '5' => self.stress_duration_secs = 900,
                            '6' => self.stress_duration_secs = 3600,
                            '+', '=' => self.stress_streams = @min(32, self.stress_streams + 2),
                            '-', '_' => self.stress_streams = @max(1, self.stress_streams - 2),
                            'q' => self.show_stress_modal = false,
                            else => {},
                        },
                        else => {},
                    }
                    continue;
                }

                if (self.show_palette) {
                    const total_cmds = widgets.PALETTE_COMMANDS.len;
                    switch (key) {
                        .char => |c| switch (c) {
                            'j' => self.palette_idx = (self.palette_idx + 1) % total_cmds,
                            'k' => self.palette_idx = if (self.palette_idx > 0) self.palette_idx - 1 else total_cmds - 1,
                            'q', 3 => should_quit = true,
                            else => {},
                        },
                        .down => self.palette_idx = (self.palette_idx + 1) % total_cmds,
                        .up => self.palette_idx = if (self.palette_idx > 0) self.palette_idx - 1 else total_cmds - 1,
                        .escape => self.show_palette = false,
                        .enter => {
                            self.show_palette = false;
                            switch (self.palette_idx) {
                                0 => self.active_tab = .overview,
                                1 => self.active_tab = .processes,
                                2 => self.active_tab = .disks,
                                3 => self.active_tab = .network,
                                4 => self.active_tab = .diagnostics,
                                5 => self.active_tab = .services,
                                6 => self.active_tab = .containers,
                                7 => self.cycleTheme(),
                                8 => {
                                    try self.engine.process_mgr.setSort(.cpu, .descending);
                                    self.setStatus("Sort: CPU% descending");
                                },
                                9 => {
                                    try self.engine.process_mgr.setSort(.memory, .descending);
                                    self.setStatus("Sort: Memory RSS descending");
                                },
                                10 => {
                                    try self.engine.process_mgr.setSort(.pid, .ascending);
                                    self.setStatus("Sort: PID ascending");
                                },
                                11 => {
                                    self.tree_mode = !self.tree_mode;
                                    try self.engine.process_mgr.toggleTreeMode();
                                    self.setStatus(if (self.tree_mode) "Tree view enabled" else "Flat view enabled");
                                },
                                12 => {
                                    self.is_paused = !self.is_paused;
                                    if (!self.is_paused) self.status_len = 0;
                                },
                                13 => {
                                    if (proc_count > 0 and self.selected_proc_idx < proc_count) {
                                        self.show_kill_modal = true;
                                    }
                                },
                                14 => {
                                    if (proc_count > 0 and self.selected_proc_idx < proc_count) {
                                        const proc = &snapshot.top_processes[self.selected_proc_idx];
                                        var col = self.engine.platform.getCollector();
                                        col.suspendProcess(proc.pid) catch {};
                                        self.setStatus("Process suspended (SIGSTOP)");
                                    }
                                },
                                15 => {
                                    if (proc_count > 0 and self.selected_proc_idx < proc_count) {
                                        const proc = &snapshot.top_processes[self.selected_proc_idx];
                                        var col = self.engine.platform.getCollector();
                                        col.resumeProcess(proc.pid) catch {};
                                        self.setStatus("Process resumed (SIGCONT)");
                                    }
                                },
                                16 => should_quit = true,
                                else => {},
                            }
                        },
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
                        ':', 16 => {
                            self.show_palette = true;
                            self.palette_idx = 0;
                        },
                        '/' => {
                            self.search_input_active = true;
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
                        '6' => self.active_tab = .services,
                        '7' => self.active_tab = .containers,
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
                        'T', ']' => self.cycleTheme(),
                        'x', 'K' => {
                            if (self.active_tab == .processes and proc_count > 0 and self.selected_proc_idx < proc_count) {
                                self.show_kill_modal = true;
                            }
                        },
                        'P' => {
                            if (self.active_tab == .processes and proc_count > 0 and self.selected_proc_idx < proc_count) {
                                const proc = &snapshot.top_processes[self.selected_proc_idx];
                                self.process_profiler.start(proc.pid, proc.getName(), 10);
                                self.show_profiler_modal = true;
                            }
                        },
                        's' => {
                            if (self.active_tab == .network) {
                                self.triggerSpeedTest();
                            } else if (self.active_tab == .processes and proc_count > 0 and self.selected_proc_idx < proc_count) {
                                const proc = &snapshot.top_processes[self.selected_proc_idx];
                                var col = self.engine.platform.getCollector();
                                if (col.suspendProcess(proc.pid)) |_| {
                                    self.setStatus("Process suspended (SIGSTOP)");
                                } else |_| {
                                    self.setStatus("Failed to suspend process (Access Denied)");
                                }
                            }
                        },
                        'S' => {
                            if (self.active_tab == .network) {
                                self.triggerStressTest(self.stress_duration_secs, self.stress_streams);
                            }
                        },
                        'r', 'u' => {
                            if (self.active_tab == .processes and proc_count > 0 and self.selected_proc_idx < proc_count) {
                                const proc = &snapshot.top_processes[self.selected_proc_idx];
                                var col = self.engine.platform.getCollector();
                                if (col.resumeProcess(proc.pid)) |_| {
                                    self.setStatus("Process resumed (SIGCONT)");
                                } else |_| {
                                    self.setStatus("Failed to resume process (Access Denied)");
                                }
                            }
                        },
                        'j' => {
                            const max_items = if (self.active_tab == .services) snapshot.services.len else if (self.active_tab == .containers) snapshot.containers.len else proc_count;
                            if (self.selected_proc_idx + 1 < max_items) self.selected_proc_idx += 1;
                        },
                        'k' => {
                            if (self.selected_proc_idx > 0) self.selected_proc_idx -= 1;
                        },
                        'g' => self.selected_proc_idx = 0,
                        'G' => {
                            const max_items = if (self.active_tab == .services) snapshot.services.len else if (self.active_tab == .containers) snapshot.containers.len else proc_count;
                            self.selected_proc_idx = if (max_items > 0) max_items - 1 else 0;
                        },
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
                            .diagnostics => .services,
                            .services    => .containers,
                            .containers  => .overview,
                        };
                        self.selected_proc_idx = 0;
                    },
                    .shift_tab => {
                        self.active_tab = switch (self.active_tab) {
                            .overview    => .containers,
                            .processes   => .overview,
                            .disks       => .processes,
                            .network     => .disks,
                            .diagnostics => .network,
                            .services    => .diagnostics,
                            .containers  => .services,
                        };
                        self.selected_proc_idx = 0;
                    },
                    .down => {
                        const max_items = if (self.active_tab == .services) snapshot.services.len else if (self.active_tab == .containers) snapshot.containers.len else proc_count;
                        if (self.selected_proc_idx + 1 < max_items) self.selected_proc_idx += 1;
                    },
                    .up => {
                        if (self.selected_proc_idx > 0) self.selected_proc_idx -= 1;
                    },
                    .page_down => {
                        const max_items = if (self.active_tab == .services) snapshot.services.len else if (self.active_tab == .containers) snapshot.containers.len else proc_count;
                        const page = @as(usize, self.buffer.height / 2);
                        self.selected_proc_idx = @min(self.selected_proc_idx + page, if (max_items > 0) max_items - 1 else 0);
                    },
                    .page_up => {
                        const page = @as(usize, self.buffer.height / 2);
                        self.selected_proc_idx = if (self.selected_proc_idx > page) self.selected_proc_idx - page else 0;
                    },
                    .home => self.selected_proc_idx = 0,
                    .end  => {
                        const max_items = if (self.active_tab == .services) snapshot.services.len else if (self.active_tab == .containers) snapshot.containers.len else proc_count;
                        self.selected_proc_idx = if (max_items > 0) max_items - 1 else 0;
                    },
                    .escape => {
                        if (self.show_help) self.show_help = false;
                        if (self.show_inspect_modal) self.show_inspect_modal = false;
                        if (self.show_kill_modal) self.show_kill_modal = false;
                        if (self.show_profiler_modal) self.show_profiler_modal = false;
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
        
        var temp_buf: [128]u8 = undefined;
        const msg = std.fmt.bufPrint(&temp_buf, "Theme: {s}", .{self.theme.name}) catch "Theme changed";
        self.setStatus(msg);
    }

    fn setStatus(self: *App, msg: []const u8) void {
        const len = @min(msg.len, self.status_msg.len);
        @memcpy(self.status_msg[0..len], msg[0..len]);
        self.status_len = len;
        self.frame_count = 0;
    }
};


















