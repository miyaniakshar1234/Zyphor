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
            .diagnostics => "Health & Alerts",
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

    // Center: System tag
    const center_str = "— Native System Observatory & Diagnostics —";
    if (w > 70) {
        const cx = (w -| @as(u16, @intCast(center_str.len))) / 2;
        buf.writeString(cx, 0, center_str, theme.muted, theme.header_bg, false);
    }

    // Right: health score badge
    var hbuf: [48]u8 = undefined;
    const health_str = std.fmt.bufPrint(&hbuf, " ❤ {d}/100 [{s}] ", .{
        health.overall_score,
        health.status.asText(),
    }) catch " ❤ ??/100 ";

    const health_color = switch (health.status) {
        .excellent => theme.success,
        .good => Color.rgb(80, 210, 130),
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
    search_query: ?[]const u8,
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
            // Active tab: accent background, bold
            buf.writeString(cx, 2, label, theme.bg, theme.accent, true);
            // Draw accent underline marker on row 3
            var i: u16 = 0;
            while (i < label.len) : (i += 1) {
                buf.setCell(cx + i, 3, "▔", theme.accent, theme.bg, false);
            }
        } else {
            buf.writeString(cx, 2, label, theme.muted, theme.tab_bg, false);
            var i: u16 = 0;
            while (i < label.len) : (i += 1) {
                buf.setCell(cx + i, 3, " ", theme.muted, theme.bg, false);
            }
        }
        cx += @intCast(label.len + 1);
        if (cx >= w - 25) break;
    }

    // Search query badge if active
    if (search_query) |query| {
        if (query.len > 0 and w > 60) {
            var sbuf: [64]u8 = undefined;
            const sstr = std.fmt.bufPrint(&sbuf, " 🔍 \"{s}\" ", .{query}) catch "";
            const sx = w -| @as(u16, @intCast(sstr.len + 2));
            buf.writeString(sx, 2, sstr, theme.warning, theme.selected, true);
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// OVERVIEW PANEL (4-Quadrant Responsive Layout)
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
    if (w < 60 or h < 20) return;

    const content_y: u16 = 4;
    const content_h = h - content_y - 2;

    const pane_w = (w - 4) / 3;
    const left_x: u16 = 1;
    const center_x: u16 = left_x + pane_w + 1;
    const right_x: u16 = center_x + pane_w + 1;

    // ── 1. CPU Command Center (Left Pane) ──────────────────────────────────
    buf.drawBox(left_x, content_y, pane_w, content_h, " CPU CORE MATRIX ", theme.border, theme.accent, theme.bg, plain);

    const dial_radius = @min(pane_w / 2 - 2, 8);
    const dial_cx = left_x + pane_w / 2 - dial_radius;
    
    // Draw Radial Dial
    graphs.renderRadialDial(buf, dial_cx, content_y + 1, dial_radius, 4.0, snapshot.cpu.total_usage, theme.accent, theme.bg, plain);
    
    // Center text inside dial
    var cpu_val_buf: [16]u8 = undefined;
    const cpu_val = std.fmt.bufPrint(&cpu_val_buf, "{d:>4.1}%", .{snapshot.cpu.total_usage}) catch "?%";
    buf.writeString(dial_cx + dial_radius - 3, content_y + 1 + dial_radius / 2, cpu_val, theme.fg, theme.bg, true);

    var cy: u16 = content_y + dial_radius + 2;

    var info_buf: [80]u8 = undefined;
    const info = std.fmt.bufPrint(&info_buf, "{d}C @ {d} MHz", .{
        snapshot.cpu.logical_cores, snapshot.cpu.frequency_mhz,
    }) catch "";
    buf.writeStringMax(left_x + 2, cy, info, pane_w - 4, theme.muted, theme.bg, false);
    cy += 2;

    var cpu_hist: [256]f32 = undefined;
    const hist_count = history.cpu_history.getChronological(&cpu_hist);
    const spark_w = pane_w - 4;
    if (hist_count > 0 and spark_w > 4) {
        graphs.renderBrailleGraph(buf, left_x + 2, cy, spark_w, 4, cpu_hist[0..hist_count], null, theme.bg, plain);
        cy += 5;
    }

    renderCoreGrid(buf, snapshot, theme, left_x + 2, cy, pane_w - 4, plain);

    // ── 2. Memory & Page Cache (Center Pane) ──────────────────────────────
    buf.drawBox(center_x, content_y, pane_w, content_h, " MEMORY SUBSYSTEM ", theme.border, theme.secondary, theme.bg, plain);

    graphs.renderRadialDial(buf, center_x + pane_w / 2 - dial_radius, content_y + 1, dial_radius, 4.0, snapshot.memory.used_percent, theme.secondary, theme.bg, plain);

    var mem_val_buf: [16]u8 = undefined;
    const mem_val = std.fmt.bufPrint(&mem_val_buf, "{d:>4.1}%", .{snapshot.memory.used_percent}) catch "?%";
    buf.writeString(center_x + pane_w / 2 - 3, content_y + 1 + dial_radius / 2, mem_val, theme.fg, theme.bg, true);

    var my: u16 = content_y + dial_radius + 2;

    const used_gb = @as(f32, @floatFromInt(snapshot.memory.used_bytes)) / (1024.0 * 1024.0 * 1024.0);
    const total_gb = @as(f32, @floatFromInt(snapshot.memory.total_bytes)) / (1024.0 * 1024.0 * 1024.0);
    var ram_buf: [32]u8 = undefined;
    const ram_str = std.fmt.bufPrint(&ram_buf, "RAM: {d:.1} / {d:.1} GB", .{ used_gb, total_gb }) catch "?";
    buf.writeStringMax(center_x + 2, my, ram_str, pane_w - 4, theme.muted, theme.bg, false);
    my += 2;

    var mem_hist: [256]f32 = undefined;
    const mem_hist_count = history.memory_history.getChronological(&mem_hist);
    if (mem_hist_count > 0 and spark_w > 4) {
        graphs.renderBrailleGraph(buf, center_x + 2, my, spark_w, 4, mem_hist[0..mem_hist_count], null, theme.bg, plain);
        my += 5;
    }

    graphs.renderLabel(buf, center_x + 2, my, "Swap Usage: ", "", theme.muted, theme.fg, theme.bg);
    my += 1;
    graphs.renderGaugeBar(buf, center_x + 2, my, pane_w - 4, snapshot.memory.swap_used_percent, theme.secondary, theme.muted, theme.bg, plain);

    // ── 3. Sensors & Edge (Right Pane) ──────────────────────────────────
    buf.drawBox(right_x, content_y, pane_w, content_h, " SYSTEM EDGE & I/O ", theme.border, theme.header, theme.bg, plain);
    
    var ry = content_y + 2;
    buf.writeString(right_x + 2, ry, "▼ NETWORK INGRESS/EGRESS", theme.muted, theme.bg, true);
    ry += 2;

    const rx_mb = @as(f32, @floatFromInt(snapshot.network.total_rx_sec)) / (1024.0 * 1024.0);
    const tx_mb = @as(f32, @floatFromInt(snapshot.network.total_tx_sec)) / (1024.0 * 1024.0);
    
    var rx_hist: [256]f32 = undefined;
    var tx_hist: [256]f32 = undefined;
    const rx_count = history.net_rx_history.getChronological(&rx_hist);
    const tx_count = history.net_tx_history.getChronological(&tx_hist);

    if (rx_count > 0 and spark_w > 4) {
        var nbuf: [32]u8 = undefined;
        const rx_s = std.fmt.bufPrint(&nbuf, "RX: {d:.2} MB/s", .{rx_mb}) catch "?";
        graphs.renderLabel(buf, right_x + 2, ry, "", rx_s, theme.muted, theme.success, theme.bg);
        ry += 1;
        graphs.renderBrailleGraph(buf, right_x + 2, ry, spark_w, 2, rx_hist[0..rx_count], theme.success, theme.bg, plain);
        ry += 3;
        
        const tx_s = std.fmt.bufPrint(&nbuf, "TX: {d:.2} MB/s", .{tx_mb}) catch "?";
        graphs.renderLabel(buf, right_x + 2, ry, "", tx_s, theme.muted, theme.warning, theme.bg);
        ry += 1;
        graphs.renderBrailleGraph(buf, right_x + 2, ry, spark_w, 2, tx_hist[0..tx_count], theme.warning, theme.bg, plain);
        ry += 3;
    }

    buf.writeString(right_x + 2, ry, "▼ HARDWARE SENSORS", theme.muted, theme.bg, true);
    ry += 2;
    if (snapshot.gpu.available) {
        buf.writeStringMax(right_x + 2, ry, snapshot.gpu.getName(), pane_w - 4, theme.accent, theme.bg, false);
        ry += 1;
        graphs.renderGaugeBar(buf, right_x + 2, ry, pane_w - 4, snapshot.gpu.utilization_pct, theme.accent, theme.muted, theme.bg, plain);
    } else {
        buf.writeString(right_x + 2, ry, "No discrete GPU detected.", theme.muted, theme.bg, false);
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
    if (core_count == 0) return;

    // Format: "C00 [██░░] " = 12 chars
    const bar_w: u16 = 6;
    const cell_w: u16 = bar_w + 5;
    const cols_fit = @max(1, avail_w / cell_w);

    var i: usize = 0;
    var col: u16 = 0;
    var row: u16 = 0;
    while (i < core_count) : (i += 1) {
        if (col >= cols_fit) {
            col = 0;
            row += 1;
            if (row > 2) break; // max 3 rows of cores
        }
        const cx = x + col * cell_w;
        const cy = y + row;

        var core_label: [5]u8 = undefined;
        const lbl = std.fmt.bufPrint(&core_label, "C{d:<2}", .{i}) catch "C? ";
        buf.writeString(cx, cy, lbl, theme.muted, theme.bg, false);
        graphs.renderMiniBar(buf, cx + 4, cy, bar_w, snapshot.cpu.core_usage[i], theme.bg, plain);
        col += 1;
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROCESS EXPLORER & LINEAGE TREE PANEL
// ─────────────────────────────────────────────────────────────────────────────

pub fn renderProcessPanel(
    buf: *ScreenBuffer,
    processes: []const types.ProcessInfo,
    selected_idx: usize,
    tree_mode: bool,
    theme: *const Theme,
    plain: bool,
    search_query: ?[]const u8,
) void {
    const w = buf.width;
    const h = buf.height;
    if (w < 40 or h < 8) return;

    const panel_y: u16 = 4;
    const panel_h = h - panel_y - 2;

    var title_buf: [64]u8 = undefined;
    const title = if (search_query) |q|
        std.fmt.bufPrint(&title_buf, " Processes (Filter: \"{s}\") [Esc: Clear] ", .{q}) catch " Process Explorer "
    else if (tree_mode)
        " Process Lineage Tree (t: Flat Mode) "
    else
        " Process Explorer (t: Tree Mode | Enter: Inspect | x: Kill) ";

    buf.drawBox(1, panel_y, w - 2, panel_h, title, theme.border, theme.accent, theme.bg, plain);

    // Column header bar
    const hdr_y = panel_y + 1;
    buf.fillRow(hdr_y, theme.header, theme.selected);

    const hdr = "  PID     PPID    NAME                    CPU%     RAM MB   THRD  USER         STATE";
    buf.writeString(1, hdr_y, hdr[0..@min(hdr.len, w - 3)], theme.header, theme.selected, true);
    graphs.renderSeparator(buf, 1, hdr_y + 1, w - 2, theme.border, theme.bg, plain);

    const visible_y_start = hdr_y + 2;
    const visible_rows = h - visible_y_start - 2;
    var r: usize = 0;

    while (r < visible_rows and r < processes.len) : (r += 1) {
        const proc = processes[r];
        const row_y = visible_y_start + @as(u16, @intCast(r));
        const is_selected = (r == selected_idx);

        // Alternating row styling
        const row_bg = if (is_selected)
            theme.selected
        else if (r % 2 == 0)
            theme.bg
        else
            Color.rgb(
                @intCast(@min(255, @as(u16, theme.bg.r) + 6)),
                @intCast(@min(255, @as(u16, theme.bg.g) + 6)),
                @intCast(@min(255, @as(u16, theme.bg.b) + 6)),
            );

        const name_fg = if (is_selected) theme.accent else theme.fg;

        // Fill row background
        var col: u16 = 2;
        while (col < w - 2) : (col += 1) {
            buf.setCell(col, row_y, " ", theme.fg, row_bg, false);
        }

        // Selection arrow
        if (is_selected) {
            buf.setCell(2, row_y, "▶", theme.accent, row_bg, true);
        }

        // PID
        var pidbuf: [8]u8 = undefined;
        const pid_str = std.fmt.bufPrint(&pidbuf, "{d}", .{proc.pid}) catch "?";
        buf.writeString(3, row_y, pid_str, theme.muted, row_bg, false);

        // PPID
        var ppidbuf: [8]u8 = undefined;
        const ppid_str = std.fmt.bufPrint(&ppidbuf, "{d}", .{proc.ppid}) catch "?";
        buf.writeString(11, row_y, ppid_str, theme.muted, row_bg, false);

        // Process name
        var name_buf: [128]u8 = undefined;
        var name_len: usize = 0;
        const plain_char = plain;
        
        if (tree_mode and proc.tree_depth > 0) {
            var i: u16 = 0;
            while (i < proc.tree_depth and name_len < 60) : (i += 1) {
                if (i == proc.tree_depth - 1) {
                    const branch = if (plain_char) "+-" else if (proc.is_last_child) "└─" else "├─";
                    @memcpy(name_buf[name_len..name_len+branch.len], branch);
                    name_len += branch.len;
                } else {
                    const pipe = if (plain_char) "| " else "│ ";
                    @memcpy(name_buf[name_len..name_len+pipe.len], pipe);
                    name_len += pipe.len;
                }
            }
        }
        
        const name = proc.getName();
        const copy_len = @min(name.len, 128 - name_len);
        @memcpy(name_buf[name_len..name_len+copy_len], name[0..copy_len]);
        name_len += copy_len;
        
        // Write the tree+name string with max 22 columns
        buf.writeStringMax(19, row_y, name_buf[0..name_len], 22, name_fg, row_bg, is_selected);

        // CPU% with gradient
        const cpu_color = if (is_selected) theme.accent else graphs.percentColor(proc.cpu_percent);
        var cpu_buf: [8]u8 = undefined;
        const cpu_str = std.fmt.bufPrint(&cpu_buf, "{d:>5.1}%", .{proc.cpu_percent}) catch "?%";
        buf.writeString(42, row_y, cpu_str, cpu_color, row_bg, proc.cpu_percent > 15.0);

        // RAM in MB
        const rss_mb = proc.memory_rss / (1024 * 1024);
        var ram_buf: [10]u8 = undefined;
        const ram_str = std.fmt.bufPrint(&ram_buf, "{d:>6}", .{rss_mb}) catch "?";
        buf.writeString(51, row_y, ram_str, theme.secondary, row_bg, false);

        // Threads
        var thrd_buf: [6]u8 = undefined;
        const thrd_str = std.fmt.bufPrint(&thrd_buf, "{d:>4}", .{proc.threads_count}) catch "?";
        buf.writeString(60, row_y, thrd_str, theme.muted, row_bg, false);

        // User
        const user = proc.getUser();
        buf.writeString(66, row_y, user[0..@min(user.len, 12)], theme.muted, row_bg, false);

        // State with color tag
        const state_color: Color = switch (proc.state) {
            .running => theme.success,
            .sleeping => theme.muted,
            .disk_sleep => theme.warning,
            .stopped => theme.warning,
            .zombie => theme.critical,
            .unknown => theme.muted,
        };
        buf.writeString(79, row_y, proc.state.asText(), state_color, row_bg, false);
    }

    // Bottom counter
    var scroll_buf: [64]u8 = undefined;
    const scroll_str = std.fmt.bufPrint(&scroll_buf, " {d}/{d} processes | ↑↓ Scroll | Enter: Inspect | /: Search ", .{
        if (processes.len > 0) selected_idx + 1 else 0,
        processes.len,
    }) catch "";
    buf.writeString(3, panel_y + panel_h - 1, scroll_str, theme.muted, theme.bg, false);
}

// ─────────────────────────────────────────────────────────────────────────────
// STORAGE & FILESYSTEMS PANEL
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

    buf.drawBox(1, panel_y, w - 2, panel_h, " Storage Drives & Filesystem Partitions ", theme.border, theme.accent, theme.bg, plain);

    // Disk I/O throughput row
    var io_buf: [80]u8 = undefined;
    const io_str = std.fmt.bufPrint(&io_buf, "  Disk Throughput:  ↓ Read {d:.1} MB/s    ↑ Write {d:.1} MB/s    IOPS: {d}", .{
        @as(f32, @floatFromInt(disk.read_bytes_sec)) / (1024.0 * 1024.0),
        @as(f32, @floatFromInt(disk.write_bytes_sec)) / (1024.0 * 1024.0),
        disk.iops,
    }) catch "";
    buf.writeString(2, panel_y + 1, io_str, theme.header, theme.bg, true);
    graphs.renderSeparator(buf, 2, panel_y + 2, w - 4, theme.border, theme.bg, plain);

    var r: u16 = 0;
    var c: u16 = 0;
    
    const card_w: u16 = 36;
    const card_h: u16 = 6;
    const padding_x: u16 = 2;
    const padding_y: u16 = 1;
    
    const max_cols = @max(1, (w - 4) / (card_w + padding_x));

    for (disk.partitions) |part| {
        const cx = 3 + c * (card_w + padding_x);
        const cy = panel_y + 4 + r * (card_h + padding_y);
        if (cy + card_h >= panel_y + panel_h) break;

        const used_gb = @as(f32, @floatFromInt(part.used_bytes)) / (1024.0 * 1024.0 * 1024.0);
        const total_gb = @as(f32, @floatFromInt(part.total_bytes)) / (1024.0 * 1024.0 * 1024.0);
        
        buf.drawBox(cx, cy, card_w, card_h, part.getMount(), theme.border, theme.accent, theme.bg, plain);
        
        const disk_color = graphs.percentColor(part.used_percent);
        
        var fs_buf: [32]u8 = undefined;
        const fs_str = std.fmt.bufPrint(&fs_buf, "FS: {s}", .{part.getFs()}) catch "";
        buf.writeString(cx + 2, cy + 1, fs_str, theme.muted, theme.bg, false);
        
        var sz_buf: [64]u8 = undefined;
        const sz_str = std.fmt.bufPrint(&sz_buf, "{d:.1} GB / {d:.1} GB", .{used_gb, total_gb}) catch "";
        buf.writeString(cx + card_w - 2 - @as(u16, @intCast(sz_str.len)), cy + 1, sz_str, disk_color, theme.bg, true);

        graphs.renderGaugeBar(buf, cx + 2, cy + 3, card_w - 4, part.used_percent,
            theme.accent, theme.muted, theme.bg, plain);
            
        var pct_buf: [16]u8 = undefined;
        const pct_str = std.fmt.bufPrint(&pct_buf, "Usage: {d:.1}%", .{part.used_percent}) catch "";
        buf.writeString(cx + 2, cy + 4, pct_str, disk_color, theme.bg, false);

        c += 1;
        if (c >= max_cols) {
            c = 0;
            r += 1;
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// NETWORK PANEL
// ─────────────────────────────────────────────────────────────────────────────

pub fn renderNetworkPanel(
    buf: *ScreenBuffer,
    net: *const types.NetworkMetrics,
    history: *const history_mod.SystemHistory,
    theme: *const Theme,
    plain: bool,
) void {
    const w = buf.width;
    const h = buf.height;

    const panel_y: u16 = 4;
    const panel_h = h - panel_y - 2;

    buf.drawBox(1, panel_y, w - 2, panel_h, " GLOBAL NETWORK INGRESS/EGRESS MATRIX ", theme.border, theme.accent, theme.bg, plain);

    const total_rx = @as(f32, @floatFromInt(net.total_rx_sec)) / (1024.0 * 1024.0);
    const total_tx = @as(f32, @floatFromInt(net.total_tx_sec)) / (1024.0 * 1024.0);

    // Left pane for graphs, Right pane for interfaces
    const left_w = (w - 4) / 2;
    const right_w = w - 4 - left_w - 1;
    const right_x = 2 + left_w + 1;

    // --- LEFT PANE (Global Graphs) ---
    var rx_buf: [32]u8 = undefined;
    var tx_buf: [32]u8 = undefined;
    const rx_str = std.fmt.bufPrint(&rx_buf, "↓ INGRESS {d:.2} MB/s", .{total_rx}) catch "?";
    const tx_str = std.fmt.bufPrint(&tx_buf, "↑ EGRESS  {d:.2} MB/s", .{total_tx}) catch "?";

    buf.writeString(3, panel_y + 2, rx_str, theme.success, theme.bg, true);
    buf.writeString(3, panel_y + 9, tx_str, theme.warning, theme.bg, true);

    var rx_hist: [256]f32 = undefined;
    var tx_hist: [256]f32 = undefined;
    const rx_count = history.net_rx_history.getChronological(&rx_hist);
    const tx_count = history.net_tx_history.getChronological(&tx_hist);

    const spark_w = left_w - 2;
    if (rx_count > 0 and spark_w > 4) {
        graphs.renderBrailleGraph(buf, 3, panel_y + 3, spark_w, 5, rx_hist[0..rx_count], theme.success, theme.bg, plain);
    }
    if (tx_count > 0 and spark_w > 4) {
        graphs.renderBrailleGraph(buf, 3, panel_y + 10, spark_w, 5, tx_hist[0..tx_count], theme.warning, theme.bg, plain);
    }
    
    // Vertical separator
    graphs.renderSeparatorVertical(buf, left_w + 2, panel_y + 1, panel_h - 2, theme.border, theme.bg, plain);

    // --- RIGHT PANE (Interfaces) ---
    buf.writeString(right_x, panel_y + 1, " ADAPTERS ", theme.header, theme.bg, true);
    
    var r: u16 = 0;
    for (net.interfaces) |iface| {
        const row_y = panel_y + 3 + r * 4;
        if (row_y + 3 >= panel_y + panel_h) break;

        const state_color = if (iface.is_up) theme.success else theme.critical;
        const state_str = if (iface.is_up) "● UP" else "○ DOWN";

        buf.drawBox(right_x, row_y, right_w, 4, iface.getName(), theme.border, theme.accent, theme.bg, plain);
        buf.writeString(right_x + 2, row_y + 1, iface.getIp(), theme.fg, theme.bg, false);
        buf.writeString(right_x + right_w - 8, row_y + 1, state_str, state_color, theme.bg, true);

        const i_rx = @as(f32, @floatFromInt(iface.rx_bytes_sec)) / (1024.0 * 1024.0);
        const i_tx = @as(f32, @floatFromInt(iface.tx_bytes_sec)) / (1024.0 * 1024.0);
        
        var stats_buf: [64]u8 = undefined;
        const stats_str = std.fmt.bufPrint(&stats_buf, "↓ {d:.2} MB/s    ↑ {d:.2} MB/s", .{i_rx, i_tx}) catch "";
        buf.writeString(right_x + 2, row_y + 2, stats_str, theme.muted, theme.bg, false);
        
        r += 1;
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIAGNOSTICS & ROOT-CAUSE ANALYSIS PANEL
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

    buf.drawBox(1, panel_y, w - 2, panel_h, " Explainable Root-Cause Diagnostics & Health Scoring ", theme.border, theme.accent, theme.bg, plain);

    const score_color = switch (health.status) {
        .excellent => theme.success,
        .good => Color.rgb(80, 210, 130),
        .fair => theme.warning,
        .poor, .critical => theme.critical,
    };

    const dial_radius = 4;
    graphs.renderRadialDial(buf, 4, panel_y + 1, dial_radius, 4.0, @floatFromInt(health.overall_score), score_color, theme.bg, plain);
    
    var score_buf: [64]u8 = undefined;
    const score_str = std.fmt.bufPrint(&score_buf, " {d}/100 [{s}]", .{
        health.overall_score, health.status.asText(),
    }) catch "";
    
    buf.writeString(15, panel_y + 1, "Composite Health Assessment:", theme.header, theme.bg, true);
    buf.writeString(15, panel_y + 3, score_str, score_color, theme.bg, true);
    graphs.renderGaugeBar(buf, 15, panel_y + 5, @min(w - 20, 50),
        @floatFromInt(health.overall_score), theme.accent, theme.muted, theme.bg, plain);
        
    graphs.renderSeparator(buf, 2, panel_y + 7, w - 4, theme.border, theme.bg, plain);
    buf.writeString(3, panel_y + 8, "Subsystem Score Breakdown:", theme.header, theme.bg, true);

    const sub_w: u16 = @min((w - 6) / 3, 30);
    renderSubScore(buf, 3, panel_y + 9, "  CPU Compute", health.cpu_score, sub_w, theme, plain);
    renderSubScore(buf, 3 + sub_w, panel_y + 9, "  Physical RAM", health.memory_score, sub_w, theme, plain);
    renderSubScore(buf, 3 + sub_w * 2, panel_y + 9, "  Storage I/O", health.disk_score, sub_w, theme, plain);
    renderSubScore(buf, 3, panel_y + 11, "  Network Link", health.network_score, sub_w, theme, plain);
    renderSubScore(buf, 3 + sub_w, panel_y + 11, "  Thermal Zone", health.thermal_score, sub_w, theme, plain);

    graphs.renderSeparator(buf, 2, panel_y + 13, w - 4, theme.border, theme.bg, plain);
    buf.writeString(3, panel_y + 14, "Summary: ", theme.header, theme.bg, true);
    buf.writeString(12, panel_y + 14, health.getSummary()[0..@min(health.getSummary().len, w - 15)], theme.fg, theme.bg, false);

    graphs.renderSeparator(buf, 2, panel_y + 11, w - 4, theme.border, theme.bg, plain);
    buf.writeString(3, panel_y + 12, "Active Root-Cause Alerts & Recommendations:", theme.header, theme.bg, true);

    if (alerts.len == 0) {
        buf.writeString(5, panel_y + 13, "✓ Zero active alerts. All kernel subsystems operating within nominal thresholds.",
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
            buf.writeString(5 + @as(u16, @intCast(sev_str.len)) + 1, alert_y, alert.getTitle(), theme.header, theme.bg, true);

            const msg = alert.getMessage();
            buf.writeString(7, alert_y + 1, msg[0..@min(msg.len, w - 10)], theme.muted, theme.bg, false);
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
    const display_color = graphs.percentColor(100.0 - score_pct);
    buf.writeString(x, y, label, theme.muted, theme.bg, false);
    var sbuf: [6]u8 = undefined;
    const sstr = std.fmt.bufPrint(&sbuf, " {d:>3}", .{score}) catch "  ?";
    buf.writeString(x + @as(u16, @intCast(label.len)), y, sstr, display_color, theme.bg, true);
    if (avail_w > 18) {
        const bar_w = avail_w - 18;
        graphs.renderMiniBar(buf, x + @as(u16, @intCast(label.len)) + 5, y, bar_w, score_pct, theme.bg, plain);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROCESS DEEP INSPECTION MODAL (Enter)
// ─────────────────────────────────────────────────────────────────────────────

pub fn renderProcessInspectModal(
    buf: *ScreenBuffer,
    proc: *const types.ProcessInfo,
    theme: *const Theme,
    plain: bool,
) void {
    const w = buf.width;
    const h = buf.height;

    const modal_w: u16 = @min(w - 4, 72);
    const modal_h: u16 = @min(h - 4, 20);
    const modal_x = (w -| modal_w) / 2;
    const modal_y = (h -| modal_h) / 2;

    buf.fillRect(modal_x, modal_y, modal_w, modal_h, theme.bg);

    var title_buf: [64]u8 = undefined;
    const title = std.fmt.bufPrint(&title_buf, " Inspect: {s} (PID: {d}) ", .{ proc.getName(), proc.pid }) catch " Process Inspector ";
    buf.drawAccentBox(modal_x, modal_y, modal_w, modal_h, title, theme.accent, theme.accent, theme.bg, plain);

    var y = modal_y + 2;

    // Header metadata
    var pid_buf: [64]u8 = undefined;
    const pid_line = std.fmt.bufPrint(&pid_buf, "  Process ID: {d:<8} Parent ID: {d:<8} State: {s}", .{
        proc.pid, proc.ppid, proc.state.asText(),
    }) catch "";
    buf.writeString(modal_x + 2, y, pid_line, theme.fg, theme.bg, false);
    y += 1;

    var usr_buf: [64]u8 = undefined;
    const usr_line = std.fmt.bufPrint(&usr_buf, "  Owner User: {s:<12} Active Threads: {d}", .{
        proc.getUser(), proc.threads_count,
    }) catch "";
    buf.writeString(modal_x + 2, y, usr_line, theme.muted, theme.bg, false);
    y += 2;

    // Resource section
    graphs.renderSeparator(buf, modal_x + 2, y - 1, modal_w - 4, theme.border, theme.bg, plain);
    buf.writeString(modal_x + 2, y, "  RESOURCE FOOTPRINT:", theme.header, theme.bg, true);
    y += 1;

    const rss_mb = proc.memory_rss / (1024 * 1024);
    const virt_mb = proc.memory_vsize / (1024 * 1024);

    var cpu_line_buf: [16]u8 = undefined;
    const cpu_line = std.fmt.bufPrint(&cpu_line_buf, "{d:>5.1}%", .{proc.cpu_percent}) catch "?%";
    graphs.renderLabel(buf, modal_x + 2, y, "  CPU Load:      ", cpu_line, theme.muted, graphs.percentColor(proc.cpu_percent), theme.bg);
    
    // Mini CPU bar inside the modal
    graphs.renderGaugeBar(buf, modal_x + 30, y, 24, proc.cpu_percent, theme.accent, theme.muted, theme.bg, plain);
    y += 2;

    var ram_line_buf: [64]u8 = undefined;
    const ram_line = std.fmt.bufPrint(&ram_line_buf, "  Resident Set (RSS): {d} MB ({d:.2} GB)", .{ rss_mb, @as(f32, @floatFromInt(rss_mb)) / 1024.0 }) catch "";
    buf.writeString(modal_x + 2, y, ram_line, theme.secondary, theme.bg, false);
    y += 1;

    var virt_line_buf: [64]u8 = undefined;
    const virt_line = std.fmt.bufPrint(&virt_line_buf, "  Virtual / Pagefile: {d} MB", .{virt_mb}) catch "";
    buf.writeString(modal_x + 2, y, virt_line, theme.muted, theme.bg, false);
    y += 2;

    // Action Hotkeys
    graphs.renderSeparator(buf, modal_x + 2, y - 1, modal_w - 4, theme.accent_dim, theme.bg, plain);
    buf.writeString(modal_x + 2, y, "  DEFENSIVE ACTIONS:", theme.header, theme.bg, true);
    y += 2;

    buf.writeString(modal_x + 4, y, "[x] Kill   [s] Suspend   [u] Resume   [Esc] Close", theme.warning, theme.bg, true);
}

// ─────────────────────────────────────────────────────────────────────────────
// KILL CONFIRMATION MODAL (x)
// ─────────────────────────────────────────────────────────────────────────────

pub fn renderKillConfirmModal(
    buf: *ScreenBuffer,
    proc: *const types.ProcessInfo,
    theme: *const Theme,
    plain: bool,
) void {
    const w = buf.width;
    const h = buf.height;

    const modal_w: u16 = @min(w - 4, 58);
    const modal_h: u16 = 8;
    const modal_x = (w -| modal_w) / 2;
    const modal_y = (h -| modal_h) / 2;

    buf.fillRect(modal_x, modal_y, modal_w, modal_h, theme.bg);
    buf.drawAccentBox(modal_x, modal_y, modal_w, modal_h, " Confirm Process Termination ", theme.critical, theme.critical, theme.bg, plain);

    var prompt_buf: [80]u8 = undefined;
    const prompt = std.fmt.bufPrint(&prompt_buf, "Terminate \"{s}\" (PID {d})?", .{ proc.getName(), proc.pid }) catch "Terminate process?";
    buf.writeString(modal_x + 4, modal_y + 2, prompt, theme.fg, theme.bg, true);

    buf.writeString(modal_x + 4, modal_y + 4, "Press [y] to terminate  |  Press [n] / [Esc] to cancel", theme.warning, theme.bg, true);
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS BAR
// ─────────────────────────────────────────────────────────────────────────────

pub fn renderStatusBar(
    buf: *ScreenBuffer,
    theme: *const Theme,
    status_text: []const u8,
    search_input_active: bool,
    current_search_input: []const u8,
) void {
    const w = buf.width;
    const y = buf.height - 1;

    buf.fillRow(y, theme.muted, theme.tab_bg);
    graphs.renderSeparator(buf, 0, y - 1, w, theme.accent_dim, theme.bg, false);

    if (search_input_active) {
        var sbuf: [128]u8 = undefined;
        const prompt = std.fmt.bufPrint(&sbuf, " 🔍 Search Filter: {s}█ [Enter: Done | Esc: Cancel]", .{current_search_input}) catch "";
        buf.writeString(0, y, prompt, theme.warning, theme.selected, true);
        return;
    }

    const hints = " [Tab] Tab | [t] Tree | [c] CPU | [m] Mem | [/] Search | [Enter] Inspect | [x] Kill | [T] Theme | [?] Help | [q] Quit";
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

    const modal_w: u16 = @min(w - 4, 68);
    const modal_h: u16 = 22;
    const modal_x = (w -| modal_w) / 2;
    const modal_y = (h -| modal_h) / 2;

    buf.fillRect(modal_x, modal_y, modal_w, modal_h, theme.bg);
    buf.drawAccentBox(modal_x, modal_y, modal_w, modal_h, " Keyboard Shortcuts & Navigation ", theme.accent, theme.accent, theme.bg, plain);

    const bindings = [_][2][]const u8{
        .{ "Tab / Shift+Tab", "Cycle forward / backward across 5 subsystem tabs" },
        .{ "1 / 2 / 3 / 4 / 5", "Directly jump to Overview / Processes / Disk / Net / Health" },
        .{ "↑ ↓ / j k", "Navigate highlighted row in process list" },
        .{ "Enter", "Open deep process inspector modal with metrics" },
        .{ "/", "Open live interactive search filter" },
        .{ "t", "Toggle hierarchical process lineage tree mode" },
        .{ "c / m / p / n", "Sort processes by CPU / Memory RSS / PID / Name" },
        .{ "x", "Terminate / kill selected process (with confirmation)" },
        .{ "s / u", "Suspend (SIGSTOP) / Resume (SIGCONT) process" },
        .{ "Space", "Freeze / unfreeze live telemetry sampling" },
        .{ "T", "Cycle 7 built-in 24-bit TrueColor themes" },
        .{ "PgUp / PgDn", "Scroll process list by half page" },
        .{ "Home / End / g / G", "Jump directly to top / bottom of process list" },
        .{ "?", "Toggle this shortcuts guide" },
        .{ "q / Ctrl+C", "Restore console and exit cleanly" },
    };

    const key_col = modal_x + 3;
    const val_col = modal_x + 24;

    buf.writeString(key_col, modal_y + 1, "KEYBINDING", theme.header, theme.bg, true);
    buf.writeString(val_col, modal_y + 1, "ACTION", theme.header, theme.bg, true);
    graphs.renderSeparator(buf, modal_x + 1, modal_y + 2, modal_w - 2, theme.border, theme.bg, plain);

    for (bindings, 0..) |binding, idx| {
        const row_y = modal_y + 3 + @as(u16, @intCast(idx));
        buf.writeString(key_col, row_y, binding[0], theme.accent, theme.bg, true);
        buf.writeString(val_col, row_y, binding[1], theme.fg, theme.bg, false);
    }

    graphs.renderSeparator(buf, modal_x + 1, modal_y + modal_h - 2, modal_w - 2, theme.border, theme.bg, plain);
    buf.writeString(modal_x + 3, modal_y + modal_h - 1, "  Press [Esc] or any key to close help  ", theme.muted, theme.bg, false);
}


pub fn renderBackgroundGrid(buf: *ScreenBuffer, theme: *const Theme) void {
    var y: u16 = 3;
    const dot_color = theme.bg.brighten(10);
    while (y < buf.height - 1) : (y += 2) {
        var x: u16 = 2;
        while (x < buf.width) : (x += 4) {
            buf.writeString(x, y, ".", dot_color, theme.bg, false);
        }
    }
}
