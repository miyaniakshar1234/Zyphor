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
    plain_mode: bool = false,
    status_msg: [64]u8 = [_]u8{0} ** 64,
    status_len: usize = 0,

    pub fn init(allocator: std.mem.Allocator, engine: *engine_mod.SystemEngine, plain: bool) !App {
        var term = terminal_mod.Terminal.init();
        const size = term.getSize();
        const buf = try buffer_mod.ScreenBuffer.init(allocator, size.width, size.height);
        const th = if (plain) theme_mod.BuiltinThemes.plain else theme_mod.BuiltinThemes.midnight;

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

        while (!should_quit) {
            // 1. Sample Engine State
            const snapshot = try self.engine.sampleSnapshot();

            // 2. Render Screen
            self.buffer.clear(self.theme.bg);
            widgets.renderHeader(&self.buffer, &self.theme, &snapshot.health, self.plain_mode);
            widgets.renderTabs(&self.buffer, self.active_tab, &self.theme);

            switch (self.active_tab) {
                .overview => {
                    widgets.renderOverviewPanel(&self.buffer, &snapshot, &self.engine.history, &self.theme, self.plain_mode);
                },
                .processes => {
                    widgets.renderProcessPanel(&self.buffer, snapshot.top_processes, self.selected_proc_idx, self.tree_mode, &self.theme, self.plain_mode);
                },
                .disks => {
                    widgets.renderDiskPanel(&self.buffer, &snapshot.disk, &self.theme, self.plain_mode);
                },
                .network => {
                    widgets.renderNetworkPanel(&self.buffer, &snapshot.network, &self.theme, self.plain_mode);
                },
                .diagnostics => {
                    widgets.renderDiagnosticsPanel(&self.buffer, &snapshot.health, self.engine.alert_engine.alerts.items, &self.theme, self.plain_mode);
                },
            }

            const status = if (self.status_len > 0) self.status_msg[0..self.status_len] else "";
            widgets.renderStatusBar(&self.buffer, &self.theme, status);

            if (self.show_help) {
                widgets.renderHelpModal(&self.buffer, &self.theme, self.plain_mode);
            }

            // 3. Flush to Terminal
            try self.buffer.flush(stdout);

            // 4. Handle Input (wait up to 500ms)
            std.Thread.sleep(500 * std.time.ns_per_ms);
            if (self.terminal.readKey()) |key| {
                if (self.show_help) {
                    self.show_help = false;
                    continue;
                }

                switch (key) {
                    .char => |c| switch (c) {
                        'q' => should_quit = true,
                        '?' => self.show_help = true,
                        't' => self.tree_mode = !self.tree_mode,
                        ' ' => self.is_paused = !self.is_paused,
                        '1' => self.active_tab = .overview,
                        '2' => self.active_tab = .processes,
                        '3' => self.active_tab = .disks,
                        '4' => self.active_tab = .network,
                        '5' => self.active_tab = .diagnostics,
                        'c' => try self.engine.process_mgr.setSort(.cpu, .descending),
                        'm' => try self.engine.process_mgr.setSort(.memory, .descending),
                        'p' => try self.engine.process_mgr.setSort(.pid, .ascending),
                        'T' => self.cycleTheme(),
                        'j' => {
                            if (self.selected_proc_idx + 1 < snapshot.top_processes.len) {
                                self.selected_proc_idx += 1;
                            }
                        },
                        'k' => {
                            if (self.selected_proc_idx > 0) {
                                self.selected_proc_idx -= 1;
                            }
                        },
                        else => {},
                    },
                    .tab => {
                        self.active_tab = switch (self.active_tab) {
                            .overview => .processes,
                            .processes => .disks,
                            .disks => .network,
                            .network => .diagnostics,
                            .diagnostics => .overview,
                        };
                    },
                    .shift_tab => {
                        self.active_tab = switch (self.active_tab) {
                            .overview => .diagnostics,
                            .processes => .overview,
                            .disks => .processes,
                            .network => .disks,
                            .diagnostics => .network,
                        };
                    },
                    .down => {
                        if (self.selected_proc_idx + 1 < snapshot.top_processes.len) {
                            self.selected_proc_idx += 1;
                        }
                    },
                    .up => {
                        if (self.selected_proc_idx > 0) {
                            self.selected_proc_idx -= 1;
                        }
                    },
                    .escape => {
                        if (self.show_help) self.show_help = false;
                    },
                    else => {},
                }
            }
        }
    }

    fn cycleTheme(self: *App) void {
        if (self.plain_mode) return;
        const themes = [_]theme_mod.Theme{
            theme_mod.BuiltinThemes.midnight,
            theme_mod.BuiltinThemes.cyber,
            theme_mod.BuiltinThemes.aurora,
            theme_mod.BuiltinThemes.nord,
            theme_mod.BuiltinThemes.solarized,
            theme_mod.BuiltinThemes.high_contrast,
        };
        self.theme_idx = (self.theme_idx + 1) % themes.len;
        self.theme = themes[self.theme_idx];
    }
};
