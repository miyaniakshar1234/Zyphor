const std = @import("std");
const types = @import("../core/types.zig");
const theme_mod = @import("theme.zig");
const buffer_mod = @import("buffer.zig");
const graphs = @import("graphs.zig");
const history_mod = @import("../core/history.zig");
const alert_mod = @import("../alerts/engine.zig");

const ScreenBuffer = buffer_mod.ScreenBuffer;
const Theme = theme_mod.Theme;
const Color = theme_mod.Color;

pub const Tab = enum {
    overview,
    processes,
    disks,
    network,
    diagnostics,

    pub fn label(self: Tab) []const u8 {
        return switch (self) {
            .overview => "Overview",
            .processes => "Processes",
            .disks => "Storage",
            .network => "Network",
            .diagnostics => "Health",
        };
    }

    pub fn icon(self: Tab) []const u8 {
        return switch (self) {
            .overview => " ⬡",
            .processes => " ◈",
            .disks => " ⬡",
            .network => " ◈",
            .diagnostics => " ◉",
        };
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────

pub fn renderHeader(
    buf: *ScreenBuffer,
    theme: *const Theme,
    health: *const types.SystemHealth,
    plain: bool,
) void {
    _ = plain;
    const w = buf.width;

    // Full-width header bar (row 0)
    buf.fillRow(0, theme.fg, theme.header_bg);

    // Logo / title left side
    const logo = " ◈ ZYPHOR";
    buf.writeString(1, 0, logo, theme.accent, theme.header_bg, true);

    const version = " v0.1.0";
    buf.writeString(1 + @as(u16, @intCast(logo.len)), 0, version, theme.muted, theme.header_bg, false);

    // Center: empty or hostname placeholder
    const center_str = "— System Observatory —";
    if (w > 60) {
        const cx = (w -| @as(u16, @intCast(center_str.len))) / 2;
        buf.writeString(cx, 0, center_str, theme.muted, theme.header_bg, false);
    }

    // Right: health badge
    var hbuf: [32]u8 = undefined;
    const health_str = std.fmt.bufPrint(&hbuf, " ❤ {d}/100 {s} ", .{
        health.overall_score,
        health.status.asText(),
    }) catch " ❤ ??/100 ";

    const health_color = switch (health.status) {
        .excellent => theme.success,
        .good => Color.rgb(80, 200, 120),
        .fair => theme.warning,
        .poor, .critical => theme.critical,
    };

    if (w > @as(u16, @intCast(health_str.len + 4))) {
        const hx = w - @as(u16, @intCast(health_str.len));
        buf.writeString(hx, 0, health_str, health_color, theme.header_bg, true);
    }

    // Separator row 1 — thin accent line under header
    graphs.renderSeparator(buf, 0, 1, w, theme.accent_dim, theme.bg, false);
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB BAR
// ─────────────────────────────────────────────────────────────────────────────

pub fn renderTabs(
    buf: *ScreenBuffer,
    active_tab: Tab,
    theme: *const Theme,
) void {
    const w = buf.width;
    buf.fillRow(2, theme.muted, theme.tab_bg);

    const tabs = [_]Tab{ .overview, .processes, .disks, .network, .diagnostics };
    var cx: u16 = 1;

    for (tabs, 0..) |tab, idx| {
        const is_active = (tab == active_tab);
        var label_buf: [32]u8 = undefined;
        const label = std.fmt.bufPrint(&label_buf, " {d}: {s} ", .{ idx + 1, tab.label() }) catch tab.label();

        if (is_active) {
            // Active tab: accent background, bold, bottom indicator
            buf.writeString(cx, 2, label, theme.bg, theme.accent, true);
            // Draw accent underline marker on row 3
            var i: u16 = 0;
            while (i < label.len) : (i += 1) {
                buf.setCell(cx + i, 3, "▔", theme.accent, theme.bg, false);
            }
        } else {
            buf.writeString(cx, 2, label, theme.muted, theme.tab_bg, false);
            // Clear underline for inactive
            var i: u16 = 0;
            while (i < label.len) : (i += 1) {
                buf.setCell(cx + i, 3, " ", theme.muted, theme.bg, false);
            }
        }
        cx += @intCast(label.len + 1);
        if (cx >= w - 2) break;
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// OVERVIEW PANEL
// ─────────────────────────────────────────────────────────────────────────────

pub fn renderOverviewPanel(
    buf: *ScreenBuffer,
    snapshot: *const types.SystemSnapshot,
    history: *const history_mod.SystemHistory,
    theme: *const Theme,
    plain: bool,
) void {
    const w = buf.width;
    const h = buf.height;
    if (w < 60 or h < 14) return;

    const content_y: u16 = 4; // below header(0), sep(1), tabs(2), underline(3)
    const content_h = h - content_y - 2; // leave 2 for status bar

    // Split into left and right halves
    const half = (w - 3) / 2;
    const left_x: u16 = 1;
    const right_x = left_x + half + 1;

    // ── CPU Panel (left top) ──────────────────────────────────────────────
    const cpu_h: u16 = 9;
    buf.drawBox(left_x, content_y, half, cpu_h, " CPU ", theme.border, theme.accent, theme.bg, plain);

    // CPU Usage line
    var cpu_val_buf: [32]u8 = undefined;
    const cpu_val = std.fmt.bufPrint(&cpu_val_buf, "{d:.1}%", .{snapshot.cpu.total_usage}) catch "?%";
    graphs.renderLabel(buf, left_x + 2, content_y + 1, "  Usage: ", cpu_val,
        theme.muted, graphs.percentColor(snapshot.cpu.total_usage), theme.bg);

    // Wide gauge bar
    graphs.renderGaugeBar(buf, left_x + 2, content_y + 2, half - 4,
        snapshot.cpu.total_usage, theme.accent, theme.muted, theme.bg, plain);

    // CPU info line
    var info_buf: [64]u8 = undefined;
    const info = std.fmt.bufPrint(&info_buf, "  {d} cores  {d} MHz  {s}", .{
        snapshot.cpu.logical_cores,
        snapshot.cpu.frequency_mhz,
        snapshot.cpu.getModelName(),
    }) catch "  N/A";
    buf.writeString(left_x + 1, content_y + 3, info[0..@min(info.len, half - 3)],
        theme.muted, theme.bg, false);

    // Sparkline history (double row for more visual weight)
    var cpu_hist: [256]f32 = undefined;
    const hist_count = history.cpu_history.getChronological(&cpu_hist);
    buf.writeString(left_x + 2, content_y + 4, "History ", theme.muted, theme.bg, false);
    const spark_w = half - 12;
    if (hist_count > 0 and spark_w > 4) {
        graphs.renderSparklineDouble(buf, left_x + 10, content_y + 4,
            spark_w, cpu_hist[0..hist_count], theme.bg, plain);
    }

    // Per-core mini grid (if cores fit)
    renderCoreGrid(buf, snapshot, theme, left_x + 2, content_y + 6, half - 4, plain);

    // ── Memory Panel (right top) ──────────────────────────────────────────
    buf.drawBox(right_x, content_y, half, cpu_h, " Memory ", theme.border, theme.secondary, theme.bg, plain);

    const used_gb = @as(f32, @floatFromInt(snapshot.memory.used_bytes)) / (1024.0 * 1024.0 * 1024.0);
    const total_gb = @as(f32, @floatFromInt(snapshot.memory.total_bytes)) / (1024.0 * 1024.0 * 1024.0);
    const avail_gb = @as(f32, @floatFromInt(snapshot.memory.available_bytes)) / (1024.0 * 1024.0 * 1024.0);

    var mem_val_buf: [32]u8 = undefined;
    const mem_val = std.fmt.bufPrint(&mem_val_buf, "{d:.1} / {d:.1} GB", .{ used_gb, total_gb }) catch "?/?";
    graphs.renderLabel(buf, right_x + 2, content_y + 1, "  RAM:   ", mem_val,
        theme.muted, graphs.percentColor(snapshot.memory.used_percent), theme.bg);

    graphs.renderGaugeBar(buf, right_x + 2, content_y + 2, half - 4,
        snapshot.memory.used_percent, theme.secondary, theme.muted, theme.bg, plain);

    var swap_buf: [32]u8 = undefined;
    const swap_str = std.fmt.bufPrint(&swap_buf, "{d:.1}% used", .{snapshot.memory.swap_used_percent}) catch "?";
    graphs.renderLabel(buf, right_x + 2, content_y + 3, "  Swap:  ", swap_str,
        theme.muted, graphs.percentColor(snapshot.memory.swap_used_percent), theme.bg);

    graphs.renderGaugeBar(buf, right_x + 2, content_y + 4, half - 4,
        snapshot.memory.swap_used_percent, theme.secondary, theme.muted, theme.bg, plain);

    var avail_buf: [32]u8 = undefined;
    const avail_str = std.fmt.bufPrint(&avail_buf, "{d:.1} GB free  [{s}]", .{
        avail_gb, snapshot.memory.pressure_level.asText(),
    }) catch "";
    buf.writeString(right_x + 2, content_y + 5, avail_str[0..@min(avail_str.len, half - 4)],
        theme.muted, theme.bg, false);

    // Mem history sparkline
    var mem_hist: [256]f32 = undefined;
    const mem_hist_count = history.memory_history.getChronological(&mem_hist);
    buf.writeString(right_x + 2, content_y + 6, "History ", theme.muted, theme.bg, false);
    if (mem_hist_count > 0 and spark_w > 4) {
        graphs.renderSparklineDouble(buf, right_x + 10, content_y + 6,
            spark_w, mem_hist[0..mem_hist_count], theme.bg, plain);
    }

    // ── GPU + Network side-by-side (bottom row) ───────────────────────────
    const bottom_y = content_y + cpu_h + 1;
    const bottom_h = content_h - cpu_h - 1;
    if (bottom_h < 4) return;

    // GPU (left bottom)
    buf.drawBox(left_x, bottom_y, half, bottom_h, " GPU ", theme.border, theme.header, theme.bg, plain);
    if (snapshot.gpu.available) {
        graphs.renderLabel(buf, left_x + 2, bottom_y + 1, "  Name:  ",
            snapshot.gpu.getName()[0..@min(snapshot.gpu.getName().len, half - 12)],
            theme.muted, theme.fg, theme.bg);

        var gpu_pct_buf: [16]u8 = undefined;
        const gpu_pct = std.fmt.bufPrint(&gpu_pct_buf, "{d:.1}%", .{snapshot.gpu.utilization_pct}) catch "?%";
        graphs.renderLabel(buf, left_x + 2, bottom_y + 2, "  Load:  ", gpu_pct,
            theme.muted, graphs.percentColor(snapshot.gpu.utilization_pct), theme.bg);

        graphs.renderGaugeBar(buf, left_x + 2, bottom_y + 3, half - 4,
            snapshot.gpu.utilization_pct, theme.accent, theme.muted, theme.bg, plain);

        const vram_used_gb = @as(f32, @floatFromInt(snapshot.gpu.vram_used_bytes)) / (1024.0 * 1024.0 * 1024.0);
        const vram_total_gb = @as(f32, @floatFromInt(snapshot.gpu.vram_total_bytes)) / (1024.0 * 1024.0 * 1024.0);
        const vram_pct = if (vram_total_gb > 0) vram_used_gb / vram_total_gb * 100.0 else 0;
        var vram_buf: [32]u8 = undefined;
        const vram_str = std.fmt.bufPrint(&vram_buf, "{d:.1} / {d:.1} GB", .{ vram_used_gb, vram_total_gb }) catch "?";
        graphs.renderLabel(buf, left_x + 2, bottom_y + 4, "  VRAM:  ", vram_str,
            theme.muted, graphs.percentColor(vram_pct), theme.bg);
    } else {
        buf.writeString(left_x + 3, bottom_y + 2, "No discrete GPU detected",
            theme.muted, theme.bg, false);
    }

    // Network (right bottom)
    buf.drawBox(right_x, bottom_y, half, bottom_h, " Network ", theme.border, theme.header, theme.bg, plain);
    const rx_mb = @as(f32, @floatFromInt(snapshot.network.total_rx_sec)) / (1024.0 * 1024.0);
    const tx_mb = @as(f32, @floatFromInt(snapshot.network.total_tx_sec)) / (1024.0 * 1024.0);

    var rx_buf: [24]u8 = undefined;
    var tx_buf: [24]u8 = undefined;
    const rx_str = std.fmt.bufPrint(&rx_buf, "{d:.2} MB/s", .{rx_mb}) catch "?";
    const tx_str = std.fmt.bufPrint(&tx_buf, "{d:.2} MB/s", .{tx_mb}) catch "?";

    graphs.renderLabel(buf, right_x + 2, bottom_y + 1, "  ↓ RX:  ", rx_str,
        theme.muted, theme.success, theme.bg);
    graphs.renderLabel(buf, right_x + 2, bottom_y + 2, "  ↑ TX:  ", tx_str,
        theme.muted, theme.warning, theme.bg);

    buf.writeString(right_x + 2, bottom_y + 3, "  Interfaces:", theme.muted, theme.bg, false);
    var iface_y: u16 = bottom_y + 4;
    for (snapshot.network.interfaces) |iface| {
        if (iface_y >= bottom_y + bottom_h - 1) break;
        var iface_buf: [64]u8 = undefined;
        const iface_str = std.fmt.bufPrint(&iface_buf, "  {s:<14} {s}", .{
            iface.getName(), iface.getIp(),
        }) catch "";
        buf.writeString(right_x + 2, iface_y, iface_str[0..@min(iface_str.len, half - 4)],
            if (iface.is_up) theme.success else theme.muted, theme.bg, false);
        iface_y += 1;
    }
}

fn renderCoreGrid(
    buf: *ScreenBuffer,
    snapshot: *const types.SystemSnapshot,
    theme: *const Theme,
    x: u16,
    y: u16,
    avail_w: u16,
    plain: bool,
) void {
    const core_count = @min(snapshot.cpu.core_usage.len, 32);
    if (core_count == 0) {
        // Fallback: render a single total-CPU mini bar
        buf.writeString(x, y, "Load ", theme.muted, theme.bg, false);
        graphs.renderMiniBar(buf, x + 5, y, avail_w - 5, snapshot.cpu.total_usage, theme.bg, plain);
        return;
    }

    // Fit as many core bars as possible in available width
    // Each core bar: "C00[██░] " = ~11 chars
    const bar_w: u16 = 8;
    const cell_w: u16 = bar_w + 4; // "C0 " + bar
    const cols_fit = avail_w / cell_w;
    if (cols_fit == 0) return;

    var i: usize = 0;
    var col: u16 = 0;
    var row: u16 = 0;
    while (i < core_count) : (i += 1) {
        if (col >= cols_fit) {
            col = 0;
            row += 1;
            if (row > 1) break; // max 2 rows of core grid
        }
        const cx = x + col * cell_w;
        const cy = y + row;

        var core_label: [4]u8 = undefined;
        const lbl = std.fmt.bufPrint(&core_label, "C{d:<2}", .{i}) catch "C? ";
        buf.writeString(cx, cy, lbl, theme.muted, theme.bg, false);
        graphs.renderMiniBar(buf, cx + 3, cy, bar_w, snapshot.cpu.core_usage[i], theme.bg, plain);
        col += 1;
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROCESS PANEL
// ─────────────────────────────────────────────────────────────────────────────

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

    const panel_y: u16 = 4;
    const panel_h = h - panel_y - 2;

    const title = if (tree_mode) " Process Tree " else " Process Explorer ";
    buf.drawBox(1, panel_y, w - 2, panel_h, title, theme.border, theme.accent, theme.bg, plain);

    // Column header
    const hdr_y = panel_y + 1;
    buf.fillRow(hdr_y, theme.header, theme.selected);

    // Draw column headers with separator
    const hdr = "  PID     PPID    NAME                    CPU%    RAM MB   THRD  USER         STATE";
    buf.writeString(1, hdr_y, hdr[0..@min(hdr.len, w - 3)], theme.header, theme.selected, true);
    graphs.renderSeparator(buf, 1, hdr_y + 1, w - 2, theme.border, theme.bg, plain);

    const visible_y_start = hdr_y + 2;
    const visible_rows = h - visible_y_start - 2;
    var r: usize = 0;

    while (r < visible_rows and r < processes.len) : (r += 1) {
        const proc = processes[r];
        const row_y = visible_y_start + @as(u16, @intCast(r));
        const is_selected = (r == selected_idx);

        // Alternating row background
        const row_bg = if (is_selected)
            theme.selected
        else if (r % 2 == 0)
            theme.bg
        else
            Color.rgb(
                @intCast(@min(255, @as(u16, theme.bg.r) + 5)),
                @intCast(@min(255, @as(u16, theme.bg.g) + 5)),
                @intCast(@min(255, @as(u16, theme.bg.b) + 5)),
            );

        const name_fg = if (is_selected) theme.accent else theme.fg;

        // Fill row background
        var col: u16 = 2;
        while (col < w - 2) : (col += 1) {
            buf.setCell(col, row_y, " ", theme.fg, row_bg, false);
        }

        // PID
        var pidbuf: [8]u8 = undefined;
        const pid_str = std.fmt.bufPrint(&pidbuf, "{d}", .{proc.pid}) catch "?";
        buf.writeString(3, row_y, pid_str, theme.muted, row_bg, false);

        // PPID
        var ppidbuf: [8]u8 = undefined;
        const ppid_str = std.fmt.bufPrint(&ppidbuf, "{d}", .{proc.ppid}) catch "?";
        buf.writeString(11, row_y, ppid_str, theme.muted, row_bg, false);

        // Process name (truncated)
        const name = proc.getName();
        const name_trunc = name[0..@min(name.len, 22)];
        buf.writeString(19, row_y, name_trunc, name_fg, row_bg, is_selected);

        // CPU% with gradient color
        const cpu_color = if (is_selected) theme.accent else graphs.percentColor(proc.cpu_percent);
        var cpu_buf: [8]u8 = undefined;
        const cpu_str = std.fmt.bufPrint(&cpu_buf, "{d:>5.1}%", .{proc.cpu_percent}) catch "?%";
        buf.writeString(42, row_y, cpu_str, cpu_color, row_bg, proc.cpu_percent > 20.0);

        // RAM in MB
        const rss_mb = proc.memory_rss / (1024 * 1024);
        var ram_buf: [10]u8 = undefined;
        const ram_str = std.fmt.bufPrint(&ram_buf, "{d:>6}", .{rss_mb}) catch "?";
        buf.writeString(50, row_y, ram_str, theme.secondary, row_bg, false);

        // Thread count
        var thrd_buf: [6]u8 = undefined;
        const thrd_str = std.fmt.bufPrint(&thrd_buf, "{d:>4}", .{proc.threads_count}) catch "?";
        buf.writeString(58, row_y, thrd_str, theme.muted, row_bg, false);

        // User
        const user = proc.getUser();
        buf.writeString(64, row_y, user[0..@min(user.len, 12)], theme.muted, row_bg, false);

        // State with color
        const state_color: Color = switch (proc.state) {
            .running => theme.success,
            .sleeping => theme.muted,
            .disk_sleep => theme.warning,
            .stopped => theme.warning,
            .zombie => theme.critical,
            .unknown => theme.muted,
        };
        buf.writeString(78, row_y, proc.state.asText(), state_color, row_bg, false);

        // Selection indicator
        if (is_selected) {
            buf.setCell(2, row_y, "▶", theme.accent, row_bg, true);
        }
    }

    // Scroll hint at bottom
    if (processes.len > visible_rows) {
        var scroll_buf: [32]u8 = undefined;
        const scroll_str = std.fmt.bufPrint(&scroll_buf, " {d}/{d} processes  ↑↓ scroll ", .{
            @min(selected_idx + 1, processes.len),
            processes.len,
        }) catch "";
        buf.writeString(3, panel_y + panel_h - 1, scroll_str,
            theme.muted, theme.bg, false);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// DISK PANEL
// ─────────────────────────────────────────────────────────────────────────────

pub fn renderDiskPanel(
    buf: *ScreenBuffer,
    disk: *const types.DiskMetrics,
    theme: *const Theme,
    plain: bool,
) void {
    const w = buf.width;
    const h = buf.height;

    const panel_y: u16 = 4;
    const panel_h = h - panel_y - 2;

    buf.drawBox(1, panel_y, w - 2, panel_h, " Storage & Filesystems ", theme.border, theme.accent, theme.bg, plain);

    // Disk I/O summary row
    var io_buf: [64]u8 = undefined;
    const io_str = std.fmt.bufPrint(&io_buf, "  Disk I/O:  ↓ Read {d:.1} MB/s    ↑ Write {d:.1} MB/s", .{
        @as(f32, @floatFromInt(disk.read_bytes_sec)) / (1024.0 * 1024.0),
        @as(f32, @floatFromInt(disk.write_bytes_sec)) / (1024.0 * 1024.0),
    }) catch "";
    buf.writeString(2, panel_y + 1, io_str, theme.muted, theme.bg, false);
    graphs.renderSeparator(buf, 2, panel_y + 2, w - 4, theme.border, theme.bg, plain);

    // Column header
    const hdr = "  MOUNT          FS         USED      TOTAL     FREE     UTILIZATION";
    buf.writeString(2, panel_y + 3, hdr[0..@min(hdr.len, w - 4)], theme.header, theme.bg, true);
    graphs.renderSeparator(buf, 2, panel_y + 4, w - 4, theme.border, theme.bg, plain);

    var r: u16 = 0;
    for (disk.partitions) |part| {
        const row_y = panel_y + 5 + r * 3;
        if (row_y + 2 >= panel_y + panel_h) break;

        const used_gb = @as(f32, @floatFromInt(part.used_bytes)) / (1024.0 * 1024.0 * 1024.0);
        const total_gb = @as(f32, @floatFromInt(part.total_bytes)) / (1024.0 * 1024.0 * 1024.0);
        const free_gb = @as(f32, @floatFromInt(part.free_bytes)) / (1024.0 * 1024.0 * 1024.0);

        // Mount + FS
        const disk_color = graphs.percentColor(part.used_percent);
        buf.writeString(3, row_y, part.getMount(), theme.accent, theme.bg, true);
        buf.writeString(19, row_y, part.getFs(), theme.muted, theme.bg, false);

        // Sizes
        var sz_buf: [64]u8 = undefined;
        const sz_str = std.fmt.bufPrint(&sz_buf, "{d:>6.1} GB  {d:>6.1} GB  {d:>6.1} GB", .{
            used_gb, total_gb, free_gb,
        }) catch "";
        buf.writeString(30, row_y, sz_str, disk_color, theme.bg, false);

        // Gauge bar on next row
        const gauge_w = @min(w - 6, 70);
        graphs.renderGaugeBar(buf, 3, row_y + 1, gauge_w, part.used_percent,
            theme.accent, theme.muted, theme.bg, plain);

        // Separator between drives
        if (r + 1 < disk.partitions.len) {
            graphs.renderSeparator(buf, 2, row_y + 2, w - 4, theme.border, theme.bg, plain);
        }

        r += 1;
    }

    if (disk.partitions.len == 0) {
        buf.writeString(4, panel_y + 5, "No partitions detected.", theme.muted, theme.bg, false);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// NETWORK PANEL
// ─────────────────────────────────────────────────────────────────────────────

pub fn renderNetworkPanel(
    buf: *ScreenBuffer,
    net: *const types.NetworkMetrics,
    theme: *const Theme,
    plain: bool,
) void {
    const w = buf.width;
    const h = buf.height;

    const panel_y: u16 = 4;
    const panel_h = h - panel_y - 2;

    buf.drawBox(1, panel_y, w - 2, panel_h, " Network Adapters & Throughput ", theme.border, theme.accent, theme.bg, plain);

    // Aggregate row
    const total_rx = @as(f32, @floatFromInt(net.total_rx_sec)) / (1024.0 * 1024.0);
    const total_tx = @as(f32, @floatFromInt(net.total_tx_sec)) / (1024.0 * 1024.0);
    var agg_buf: [80]u8 = undefined;
    const agg_str = std.fmt.bufPrint(&agg_buf, "  Total  ↓ Receive: {d:.2} MB/s    ↑ Transmit: {d:.2} MB/s", .{
        total_rx, total_tx,
    }) catch "";
    buf.writeString(2, panel_y + 1, agg_str, theme.fg, theme.bg, true);

    // RX gauge
    const rx_pct = @min(total_rx / 100.0 * 100.0, 100.0); // scale: 100 MB/s = 100%
    const tx_pct = @min(total_tx / 100.0 * 100.0, 100.0);
    const gauge_w = @min(w - 20, 60);
    buf.writeString(3, panel_y + 2, "↓ RX ", Color.rgb(80, 200, 120), theme.bg, false);
    graphs.renderGaugeBar(buf, 8, panel_y + 2, gauge_w, rx_pct, theme.success, theme.muted, theme.bg, plain);
    buf.writeString(3, panel_y + 3, "↑ TX ", Color.rgb(255, 180, 60), theme.bg, false);
    graphs.renderGaugeBar(buf, 8, panel_y + 3, gauge_w, tx_pct, theme.warning, theme.muted, theme.bg, plain);

    graphs.renderSeparator(buf, 2, panel_y + 4, w - 4, theme.border, theme.bg, plain);

    const hdr = "  INTERFACE               IP ADDRESS          ↓ RX          ↑ TX       STATUS";
    buf.writeString(2, panel_y + 5, hdr[0..@min(hdr.len, w - 4)], theme.header, theme.bg, true);
    graphs.renderSeparator(buf, 2, panel_y + 6, w - 4, theme.border, theme.bg, plain);

    var r: u16 = 0;
    for (net.interfaces) |iface| {
        const row_y = panel_y + 7 + r * 2;
        if (row_y + 1 >= panel_y + panel_h) break;

        const state_color = if (iface.is_up) theme.success else theme.critical;
        const state_str = if (iface.is_up) "● UP  " else "○ DOWN";

        buf.writeString(3, row_y, iface.getName(), theme.accent, theme.bg, true);
        buf.writeString(27, row_y, iface.getIp(), theme.fg, theme.bg, false);

        const rx_mb = @as(f32, @floatFromInt(iface.rx_bytes_sec)) / (1024.0 * 1024.0);
        const tx_mb = @as(f32, @floatFromInt(iface.tx_bytes_sec)) / (1024.0 * 1024.0);

        var rx_if_buf: [16]u8 = undefined;
        var tx_if_buf: [16]u8 = undefined;
        const rx_if = std.fmt.bufPrint(&rx_if_buf, "{d:.3} MB/s", .{rx_mb}) catch "?";
        const tx_if = std.fmt.bufPrint(&tx_if_buf, "{d:.3} MB/s", .{tx_mb}) catch "?";

        buf.writeString(47, row_y, rx_if, theme.success, theme.bg, false);
        buf.writeString(60, row_y, tx_if, theme.warning, theme.bg, false);
        buf.writeString(73, row_y, state_str, state_color, theme.bg, true);

        r += 1;
    }

    if (net.interfaces.len == 0) {
        buf.writeString(4, panel_y + 7, "No network interfaces detected.", theme.muted, theme.bg, false);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIAGNOSTICS PANEL
// ─────────────────────────────────────────────────────────────────────────────

pub fn renderDiagnosticsPanel(
    buf: *ScreenBuffer,
    health: *const types.SystemHealth,
    alerts: []const alert_mod.Alert,
    theme: *const Theme,
    plain: bool,
) void {
    const w = buf.width;
    const h = buf.height;

    const panel_y: u16 = 4;
    const panel_h = h - panel_y - 2;

    buf.drawBox(1, panel_y, w - 2, panel_h, " System Health & Diagnostics ", theme.border, theme.accent, theme.bg, plain);

    // Health score display
    const score_color = switch (health.status) {
        .excellent => theme.success,
        .good => Color.rgb(80, 200, 120),
        .fair => theme.warning,
        .poor, .critical => theme.critical,
    };

    var score_buf: [64]u8 = undefined;
    const score_str = std.fmt.bufPrint(&score_buf, " {d}/100  {s}", .{
        health.overall_score, health.status.asText(),
    }) catch "";
    buf.writeString(3, panel_y + 1, "Overall Health:", theme.header, theme.bg, true);
    buf.writeString(19, panel_y + 1, score_str, score_color, theme.bg, true);

    // Score bar
    graphs.renderGaugeBar(buf, 3, panel_y + 2, @min(w - 6, 60),
        @floatFromInt(health.overall_score), theme.accent, theme.muted, theme.bg, plain);

    // Sub-scores grid
    graphs.renderSeparator(buf, 2, panel_y + 3, w - 4, theme.border, theme.bg, plain);
    buf.writeString(3, panel_y + 4, "Sub-system Scores:", theme.header, theme.bg, true);

    const sub_w: u16 = @min((w - 6) / 3, 30);
    renderSubScore(buf, 3, panel_y + 5, "  CPU    ", health.cpu_score, sub_w, theme, plain);
    renderSubScore(buf, 3 + sub_w, panel_y + 5, "  Memory ", health.memory_score, sub_w, theme, plain);
    renderSubScore(buf, 3 + sub_w * 2, panel_y + 5, "  Disk   ", health.disk_score, sub_w, theme, plain);
    renderSubScore(buf, 3, panel_y + 7, "  Network", health.network_score, sub_w, theme, plain);
    renderSubScore(buf, 3 + sub_w, panel_y + 7, "  Thermal", health.thermal_score, sub_w, theme, plain);

    // Summary
    graphs.renderSeparator(buf, 2, panel_y + 9, w - 4, theme.border, theme.bg, plain);
    buf.writeString(3, panel_y + 10, "Analysis: ", theme.header, theme.bg, true);
    buf.writeString(13, panel_y + 10, health.getSummary()[0..@min(health.getSummary().len, w - 16)],
        theme.fg, theme.bg, false);

    // Active alerts
    graphs.renderSeparator(buf, 2, panel_y + 11, w - 4, theme.border, theme.bg, plain);
    buf.writeString(3, panel_y + 12, "Active Alerts:", theme.header, theme.bg, true);

    if (alerts.len == 0) {
        buf.writeString(5, panel_y + 13, "✓  No active alerts — all subsystems within nominal thresholds.",
            theme.success, theme.bg, false);
    } else {
        for (alerts, 0..) |alert, idx| {
            const alert_y = panel_y + 13 + @as(u16, @intCast(idx * 2));
            if (alert_y + 1 >= panel_y + panel_h) break;

            const sev_color = switch (alert.severity) {
                .critical => theme.critical,
                .warning => theme.warning,
                .info => theme.accent,
            };

            var sev_buf: [12]u8 = undefined;
            const sev_str = std.fmt.bufPrint(&sev_buf, "[{s}]", .{alert.severity.asText()}) catch "[ ? ]";
            buf.writeString(5, alert_y, sev_str, sev_color, theme.bg, true);
            buf.writeString(5 + @as(u16, @intCast(sev_str.len)) + 1, alert_y,
                alert.getTitle(), theme.header, theme.bg, true);

            const msg = alert.getMessage();
            buf.writeString(7, alert_y + 1, msg[0..@min(msg.len, w - 10)],
                theme.muted, theme.bg, false);
        }
    }
}

fn renderSubScore(
    buf: *ScreenBuffer,
    x: u16,
    y: u16,
    label: []const u8,
    score: u8,
    avail_w: u16,
    theme: *const Theme,
    plain: bool,
) void {
    if (avail_w < 12) return;
    const score_pct = @as(f32, @floatFromInt(score));
    // For health, invert: high score = green
    const display_color = graphs.percentColor(100.0 - score_pct);
    buf.writeString(x, y, label, theme.muted, theme.bg, false);
    var sbuf: [6]u8 = undefined;
    const sstr = std.fmt.bufPrint(&sbuf, " {d:>3}", .{score}) catch "  ?";
    buf.writeString(x + @as(u16, @intCast(label.len)), y, sstr, display_color, theme.bg, true);
    if (avail_w > 16) {
        const bar_w = avail_w - 16;
        graphs.renderMiniBar(buf, x + @as(u16, @intCast(label.len)) + 4, y,
            bar_w, score_pct, theme.bg, plain);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS BAR
// ─────────────────────────────────────────────────────────────────────────────

pub fn renderStatusBar(
    buf: *ScreenBuffer,
    theme: *const Theme,
    status_text: []const u8,
) void {
    const w = buf.width;
    const y = buf.height - 1;

    // Background fill
    buf.fillRow(y, theme.muted, theme.tab_bg);
    graphs.renderSeparator(buf, 0, y - 1, w, theme.accent_dim, theme.bg, false);

    const hints = "  [Tab] Panels  [1-5] Jump  [t] Tree  [c] CPU  [m] Mem  [/] Search  [T] Theme  [?] Help  [q] Quit";
    buf.writeString(0, y, hints[0..@min(hints.len, w - 1)], theme.muted, theme.tab_bg, false);

    if (status_text.len > 0) {
        const offset = w -| @as(u16, @intCast(status_text.len + 3));
        buf.writeString(offset, y, status_text, theme.warning, theme.tab_bg, true);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELP MODAL
// ─────────────────────────────────────────────────────────────────────────────

pub fn renderHelpModal(
    buf: *ScreenBuffer,
    theme: *const Theme,
    plain: bool,
) void {
    const w = buf.width;
    const h = buf.height;

    const modal_w: u16 = @min(w - 4, 64);
    const modal_h: u16 = 22;
    const modal_x = (w -| modal_w) / 2;
    const modal_y = (h -| modal_h) / 2;

    // Shadow + backdrop
    buf.fillRect(modal_x, modal_y, modal_w, modal_h, theme.bg);
    buf.drawAccentBox(modal_x, modal_y, modal_w, modal_h, " Keyboard Shortcuts ", theme.accent, theme.accent, theme.bg, plain);

    const bindings = [_][2][]const u8{
        .{ "Tab / Shift+Tab", "Cycle panels forward / backward" },
        .{ "1 / 2 / 3 / 4 / 5", "Jump to Overview / Processes / Disk / Net / Health" },
        .{ "↑ ↓ / j k", "Navigate process list" },
        .{ "Enter", "Inspect selected process" },
        .{ "t", "Toggle flat / tree process view" },
        .{ "c / m / p / n", "Sort by CPU / Memory / PID / Name" },
        .{ "x", "Kill selected process (with confirm)" },
        .{ "s / u", "Suspend / Resume selected process" },
        .{ "/", "Open fuzzy search filter" },
        .{ "Space", "Pause / Resume live polling" },
        .{ "T", "Cycle color theme" },
        .{ "PgUp / PgDn", "Scroll process list by page" },
        .{ "?", "Toggle this help overlay" },
        .{ "q / Ctrl+C", "Exit Zyphor" },
    };

    const key_col = modal_x + 3;
    const val_col = modal_x + 22;

    buf.writeString(key_col, modal_y + 1, "KEY", theme.header, theme.bg, true);
    buf.writeString(val_col, modal_y + 1, "ACTION", theme.header, theme.bg, true);
    graphs.renderSeparator(buf, modal_x + 1, modal_y + 2, modal_w - 2, theme.border, theme.bg, plain);

    for (bindings, 0..) |binding, idx| {
        const row_y = modal_y + 3 + @as(u16, @intCast(idx));
        buf.writeString(key_col, row_y, binding[0], theme.accent, theme.bg, true);
        buf.writeString(val_col, row_y, binding[1], theme.fg, theme.bg, false);
    }

    graphs.renderSeparator(buf, modal_x + 1, modal_y + modal_h - 2, modal_w - 2, theme.border, theme.bg, plain);
    buf.writeString(modal_x + 3, modal_y + modal_h - 1, "  Press any key to close  ",
        theme.muted, theme.bg, false);
}
