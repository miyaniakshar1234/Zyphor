const std = @import("std");
const types = @import("../core/types.zig");
const theme_mod = @import("theme.zig");
const buffer_mod = @import("buffer.zig");
const graphs = @import("graphs.zig");
const history_mod = @import("../core/history.zig");
const alert_mod = @import("../alerts/engine.zig");

const ScreenBuffer = buffer_mod.ScreenBuffer;
const Theme = theme_mod.Theme;

pub const Tab = enum {
    overview,
    processes,
    disks,
    network,
    diagnostics,

    pub fn asText(self: Tab) []const u8 {
        return switch (self) {
            .overview => "1: Overview",
            .processes => "2: Processes",
            .disks => "3: Storage",
            .network => "4: Network",
            .diagnostics => "5: Diagnostics",
        };
    }
};

pub fn renderHeader(
    buf: *ScreenBuffer,
    theme: *const Theme,
    health: *const types.SystemHealth,
    plain: bool,
) void {
    _ = plain;
    const w = buf.width;

    // Header Background bar
    var x: u16 = 0;
    while (x < w) : (x += 1) {
        buf.setCell(x, 0, " ", theme.fg, theme.selected, false);
    }

    // Title
    const title = " ZYPHOR v0.1.0 - SYSTEM OBSERVATORY ";
    buf.writeString(1, 0, title, theme.accent, theme.selected, true);

    // Health Score Badge
    var health_buf: [48]u8 = undefined;
    const health_str = std.fmt.bufPrint(&health_buf, " HEALTH: {d}/100 [{s}] ", .{ health.overall_score, health.status.asText() }) catch "";

    const health_color = switch (health.status) {
        .excellent => theme.success,
        .good => theme.accent,
        .fair => theme.warning,
        .poor, .critical => theme.critical,
    };

    if (w > 60) {
        const h_x = w - @as(u16, @intCast(health_str.len)) - 2;
        buf.writeString(h_x, 0, health_str, health_color, theme.selected, true);
    }
}

pub fn renderTabs(
    buf: *ScreenBuffer,
    active_tab: Tab,
    theme: *const Theme,
) void {
    const tabs = [_]Tab{ .overview, .processes, .disks, .network, .diagnostics };
    var curr_x: u16 = 2;

    for (tabs) |tab| {
        const is_active = (tab == active_tab);
        const tab_text = tab.asText();

        if (is_active) {
            buf.writeString(curr_x, 1, "[ ", theme.accent, theme.bg, true);
            buf.writeString(curr_x + 2, 1, tab_text, theme.header, theme.bg, true);
            buf.writeString(curr_x + 2 + @as(u16, @intCast(tab_text.len)), 1, " ]", theme.accent, theme.bg, true);
            curr_x += @as(u16, @intCast(tab_text.len)) + 6;
        } else {
            buf.writeString(curr_x, 1, "  ", theme.muted, theme.bg, false);
            buf.writeString(curr_x + 2, 1, tab_text, theme.muted, theme.bg, false);
            buf.writeString(curr_x + 2 + @as(u16, @intCast(tab_text.len)), 1, "  ", theme.muted, theme.bg, false);
            curr_x += @as(u16, @intCast(tab_text.len)) + 4;
        }
    }
}

pub fn renderOverviewPanel(
    buf: *ScreenBuffer,
    snapshot: *const types.SystemSnapshot,
    history: *const history_mod.SystemHistory,
    theme: *const Theme,
    plain: bool,
) void {
    const w = buf.width;
    const h = buf.height;
    if (w < 40 or h < 10) return;

    const col_w = (w - 3) / 2;
    const box_h: u16 = 8;

    // 1. CPU Box (Top Left)
    buf.drawBox(1, 2, col_w, box_h, " CPU Activity ", theme.border, theme.header, theme.bg, plain);
    var cpu_str_buf: [64]u8 = undefined;
    const cpu_str = std.fmt.bufPrint(&cpu_str_buf, "Load: {d:.1}% | {d} MHz ({d} Cores)", .{
        snapshot.cpu.total_usage,
        snapshot.cpu.frequency_mhz,
        snapshot.cpu.logical_cores,
    }) catch "";
    buf.writeString(3, 3, cpu_str, theme.fg, theme.bg, true);

    const gauge_w = col_w - 6;
    graphs.renderGaugeBar(buf, 3, 4, gauge_w, snapshot.cpu.total_usage, theme.accent, theme.muted, theme.bg, plain);

    // CPU Sparkline
    var cpu_hist: [120]f32 = undefined;
    const hist_count = history.cpu_history.getChronological(&cpu_hist);
    buf.writeString(3, 6, "History: ", theme.muted, theme.bg, false);
    if (gauge_w > 12) {
        graphs.renderSparkline(buf, 12, 6, gauge_w - 10, cpu_hist[0..hist_count], theme.accent, theme.bg, plain);
    }

    // 2. Memory Box (Top Right)
    buf.drawBox(col_w + 2, 2, col_w, box_h, " Memory & Swap ", theme.border, theme.header, theme.bg, plain);
    var mem_str_buf: [64]u8 = undefined;
    const used_gb = @as(f32, @floatFromInt(snapshot.memory.used_bytes)) / (1024.0 * 1024.0 * 1024.0);
    const total_gb = @as(f32, @floatFromInt(snapshot.memory.total_bytes)) / (1024.0 * 1024.0 * 1024.0);
    const mem_str = std.fmt.bufPrint(&mem_str_buf, "RAM: {d:.1}/{d:.1} GB ({d:.1}%)", .{ used_gb, total_gb, snapshot.memory.used_percent }) catch "";
    buf.writeString(col_w + 4, 3, mem_str, theme.fg, theme.bg, true);

    graphs.renderGaugeBar(buf, col_w + 4, 4, gauge_w, snapshot.memory.used_percent, theme.secondary, theme.muted, theme.bg, plain);

    var swap_str_buf: [64]u8 = undefined;
    const swap_str = std.fmt.bufPrint(&swap_str_buf, "Swap: {d:.1}% | Pressure: {s}", .{ snapshot.memory.swap_used_percent, snapshot.memory.pressure_level.asText() }) catch "";
    buf.writeString(col_w + 4, 6, swap_str, theme.muted, theme.bg, false);

    // 3. Top Processes Table (Bottom)
    const proc_box_y = box_h + 2;
    const proc_box_h = h - proc_box_y - 2;
    buf.drawBox(1, proc_box_y, w - 2, proc_box_h, " Top Processes ", theme.border, theme.header, theme.bg, plain);

    // Table Header
    const hdr = " PID     NAME                   CPU%     RAM (MB)   THREADS  STATE";
    buf.writeString(3, proc_box_y + 1, hdr, theme.header, theme.bg, true);

    var r: u16 = 0;
    const max_rows = @min(snapshot.top_processes.len, @as(usize, proc_box_h - 3));
    while (r < max_rows) : (r += 1) {
        const proc = snapshot.top_processes[r];
        const row_y = proc_box_y + 2 + r;

        var row_buf: [128]u8 = undefined;
        const row_str = std.fmt.bufPrint(&row_buf, " {d:<7} {s:<22} {d:>5.1}%   {d:>8}   {d:>7}  {s}", .{
            proc.pid,
            proc.getName(),
            proc.cpu_percent,
            proc.memory_rss / (1024 * 1024),
            proc.threads_count,
            proc.state.asText(),
        }) catch "";

        buf.writeString(3, row_y, row_str, theme.fg, theme.bg, false);
    }
}

pub fn renderProcessPanel(
    buf: *ScreenBuffer,
    processes: []const types.ProcessInfo,
    selected_idx: usize,
    tree_mode: bool,
    theme: *const Theme,
    plain: bool,
) void {
    const w = buf.width;
    const h = buf.height;
    if (w < 40 or h < 8) return;

    const title = if (tree_mode) " Process Lineage Tree (t: Flat Mode) " else " Process Explorer (t: Tree Mode) ";
    buf.drawBox(1, 2, w - 2, h - 4, title, theme.border, theme.header, theme.bg, plain);

    const hdr = " PID     PPID    NAME                   CPU%     RAM (MB)   THREADS  USER       STATE";
    buf.writeString(3, 3, hdr, theme.header, theme.bg, true);

    const visible_rows = h - 6;
    var r: u16 = 0;
    while (r < visible_rows and r < processes.len) : (r += 1) {
        const proc = processes[r];
        const row_y = 4 + r;
        const is_selected = (r == selected_idx);

        const row_bg = if (is_selected) theme.selected else theme.bg;
        const row_fg = if (is_selected) theme.accent else theme.fg;

        var row_buf: [160]u8 = undefined;
        const row_str = std.fmt.bufPrint(&row_buf, " {d:<7} {d:<7} {s:<22} {d:>5.1}%   {d:>8}   {d:>7}  {s:<10} {s}", .{
            proc.pid,
            proc.ppid,
            proc.getName(),
            proc.cpu_percent,
            proc.memory_rss / (1024 * 1024),
            proc.threads_count,
            proc.getUser(),
            proc.state.asText(),
        }) catch "";

        var col: u16 = 2;
        while (col < w - 2) : (col += 1) {
            buf.setCell(col, row_y, " ", row_fg, row_bg, false);
        }
        buf.writeString(3, row_y, row_str, row_fg, row_bg, is_selected);
    }
}

pub fn renderDiskPanel(
    buf: *ScreenBuffer,
    disk: *const types.DiskMetrics,
    theme: *const Theme,
    plain: bool,
) void {
    const w = buf.width;
    const h = buf.height;
    buf.drawBox(1, 2, w - 2, h - 4, " Storage & Filesystems ", theme.border, theme.header, theme.bg, plain);

    const hdr = " MOUNT POINT    FILESYSTEM    USED / TOTAL GB         UTILIZATION";
    buf.writeString(3, 3, hdr, theme.header, theme.bg, true);

    var r: u16 = 0;
    while (r < disk.partitions.len and r < h - 6) : (r += 1) {
        const part = disk.partitions[r];
        const row_y = 5 + r * 2;

        const used_gb = @as(f32, @floatFromInt(part.used_bytes)) / (1024.0 * 1024.0 * 1024.0);
        const total_gb = @as(f32, @floatFromInt(part.total_bytes)) / (1024.0 * 1024.0 * 1024.0);

        var row_buf: [128]u8 = undefined;
        const row_str = std.fmt.bufPrint(&row_buf, " {s:<14} {s:<12} {d:>6.1} / {d:>6.1} GB ({d:>4.1}%)", .{
            part.getMount(),
            part.getFs(),
            used_gb,
            total_gb,
            part.used_percent,
        }) catch "";

        buf.writeString(3, row_y, row_str, theme.fg, theme.bg, false);
        graphs.renderGaugeBar(buf, 55, row_y, 25, part.used_percent, theme.accent, theme.muted, theme.bg, plain);
    }
}

pub fn renderNetworkPanel(
    buf: *ScreenBuffer,
    net: *const types.NetworkMetrics,
    theme: *const Theme,
    plain: bool,
) void {
    const w = buf.width;
    const h = buf.height;
    buf.drawBox(1, 2, w - 2, h - 4, " Network Adapters & Throughput ", theme.border, theme.header, theme.bg, plain);

    const hdr = " INTERFACE                   IP ADDRESS       RX SPEED     TX SPEED     STATE";
    buf.writeString(3, 3, hdr, theme.header, theme.bg, true);

    var r: u16 = 0;
    while (r < net.interfaces.len and r < h - 6) : (r += 1) {
        const iface = net.interfaces[r];
        const row_y = 5 + r * 2;

        const rx_mb = @as(f32, @floatFromInt(iface.rx_bytes_sec)) / (1024.0 * 1024.0);
        const tx_mb = @as(f32, @floatFromInt(iface.tx_bytes_sec)) / (1024.0 * 1024.0);

        var row_buf: [160]u8 = undefined;
        const row_str = std.fmt.bufPrint(&row_buf, " {s:<27} {s:<16} ↓ {d:>5.2} MB/s  ↑ {d:>5.2} MB/s  {s}", .{
            iface.getName(),
            iface.getIp(),
            rx_mb,
            tx_mb,
            if (iface.is_up) "UP" else "DOWN",
        }) catch "";

        buf.writeString(3, row_y, row_str, theme.fg, theme.bg, false);
    }
}

pub fn renderDiagnosticsPanel(
    buf: *ScreenBuffer,
    health: *const types.SystemHealth,
    alerts: []const alert_mod.Alert,
    theme: *const Theme,
    plain: bool,
) void {
    const w = buf.width;
    const h = buf.height;
    buf.drawBox(1, 2, w - 2, h - 4, " System Diagnostics & Root-Cause Analysis ", theme.border, theme.header, theme.bg, plain);

    // Health Summary
    buf.writeString(3, 4, "HEALTH ASSESSMENT:", theme.header, theme.bg, true);
    buf.writeString(23, 4, health.getSummary(), theme.fg, theme.bg, false);

    // Active Alerts Box
    buf.writeString(3, 7, "ACTIVE DIAGNOSTIC ALERTS:", theme.header, theme.bg, true);

    if (alerts.len == 0) {
        buf.writeString(5, 9, "✓ Zero active alerts. All subsystems are healthy and within nominal limits.", theme.success, theme.bg, false);
    } else {
        for (alerts, 0..) |alert, idx| {
            const alert_y = 9 + @as(u16, @intCast(idx * 2));
            if (alert_y >= h - 4) break;

            const sev_color = switch (alert.severity) {
                .critical => theme.critical,
                .warning => theme.warning,
                .info => theme.accent,
            };

            buf.writeString(5, alert_y, "[", theme.muted, theme.bg, false);
            buf.writeString(6, alert_y, alert.severity.asText(), sev_color, theme.bg, true);
            buf.writeString(10, alert_y, "]", theme.muted, theme.bg, false);

            buf.writeString(13, alert_y, alert.getTitle(), theme.header, theme.bg, true);
            buf.writeString(38, alert_y, alert.getMessage(), theme.fg, theme.bg, false);
        }
    }
}

pub fn renderStatusBar(
    buf: *ScreenBuffer,
    theme: *const Theme,
    status_text: []const u8,
) void {
    const w = buf.width;
    const y = buf.height - 1;

    var x: u16 = 0;
    while (x < w) : (x += 1) {
        buf.setCell(x, y, " ", theme.fg, theme.selected, false);
    }

    // Default hotkeys hint
    const hints = " [Tab] Switch Tab | [t] Tree | [c] CPU | [m] Mem | [k] Kill | [T] Theme | [?] Help | [q] Quit";
    buf.writeString(1, y, hints, theme.muted, theme.selected, false);

    if (status_text.len > 0) {
        const offset = w -| @as(u16, @intCast(status_text.len + 3));
        buf.writeString(offset, y, status_text, theme.warning, theme.selected, true);
    }
}

pub fn renderHelpModal(
    buf: *ScreenBuffer,
    theme: *const Theme,
    plain: bool,
) void {
    const w = buf.width;
    const h = buf.height;

    const modal_w: u16 = 60;
    const modal_h: u16 = 18;
    const modal_x = (w -| modal_w) / 2;
    const modal_y = (h -| modal_h) / 2;

    // Fill background
    var my = modal_y;
    while (my < modal_y + modal_h) : (my += 1) {
        var mx = modal_x;
        while (mx < modal_x + modal_w) : (mx += 1) {
            buf.setCell(mx, my, " ", theme.fg, theme.bg, false);
        }
    }

    buf.drawBox(modal_x, modal_y, modal_w, modal_h, " Keyboard Shortcuts Help ", theme.accent, theme.header, theme.bg, plain);

    const help_lines = [_][]const u8{
        "Tab / Shift+Tab   : Switch active panel",
        "1 - 5             : Jump directly to panel (Overview..Diag)",
        "↑ / ↓ / j / k     : Navigate process list",
        "t                 : Toggle hierarchical Process Tree view",
        "c / m / p         : Sort by CPU%, Memory RSS, or PID",
        "x / k             : Terminate/kill selected process",
        "s / u             : Suspend / Resume process",
        "T                 : Cycle color themes",
        "Space             : Pause / Resume real-time polling",
        "?                 : Toggle this help dialog",
        "q / Ctrl+C        : Exit Zyphor",
        "",
        "Press any key to close this modal...",
    };

    for (help_lines, 0..) |line, idx| {
        buf.writeString(modal_x + 3, modal_y + 2 + @as(u16, @intCast(idx)), line, theme.fg, theme.bg, false);
    }
}
