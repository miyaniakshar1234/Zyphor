# Theming & Customization Guide

Zyphor offers complete customization of color themes, keyboard mappings, dashboard layouts, and diagnostic rules via simple TOML configuration files.

---

## 📁 Configuration File Locations

Zyphor searches for configuration in standard OS directories:

* **Linux:** `~/.config/zyphor/config.toml` (respects `$XDG_CONFIG_HOME`)
* **macOS:** `~/Library/Application Support/zyphor/config.toml`
* **Windows:** `%APPDATA%\zyphor\config.toml`

---

## 🎨 Built-in Color Themes

Zyphor ships with six high-contrast, beautiful color palettes. You can cycle between them on the fly by pressing <kbd>T</kbd> inside the TUI:

| Theme Name | Description | Recommended Background |
| :--- | :--- | :--- |
| `midnight` | Deep navy and cyan accent palette *(Default)* | Dark `#0d1117` |
| `cyber` | Neon magenta, bright yellow, and cyber blue | Pure Black `#000000` |
| `aurora` | Emerald green, teal, and soft violet | Dark Slate `#1e222a` |
| `nord` | Arctic cold blues, frost accents, and snow whites | Nord Dark `#2e3440` |
| `solarized` | Warm amber, solar yellow, and cyan | Solarized Dark `#002b36` |
| `high_contrast`| Pure white, bright yellow, red, and cyan | Any Dark Terminal |
| `plain` | Monochrome ASCII without ANSI color escapes | Any / Accessibility |

---

## 🛠️ Custom Theme Definition

You can create a custom theme in `~/.config/zyphor/themes/my_theme.toml`:

```toml
[theme]
name = "Dracula"
author = "Community"

[colors]
background    = "#282a36"
foreground    = "#f8f8f2"
accent        = "#bd93f9" # Purple
secondary     = "#8be9fd" # Cyan
success       = "#50fa7b" # Green
warning       = "#ffb86c" # Orange
critical      = "#ff5555" # Red
border        = "#6272a4" # Comment blue
table_header  = "#ff79c6" # Pink
selected_row  = "#44475a" # Highlight bar
```

---

## ⌨️ Custom Keybindings

Override default hotkeys in `~/.config/zyphor/keybindings.toml`:

```toml
[keybindings]
quit              = ["q", "ctrl+c"]
help              = ["?"]
refresh           = ["r"]
pause             = ["space"]
theme_cycle       = ["T"]
search            = ["/"]
tree_toggle       = ["t"]
process_kill      = ["x", "k"]
process_suspend   = ["s"]
process_resume    = ["u"]
sort_cpu          = ["c"]
sort_memory       = ["m"]
sort_pid          = ["p"]
```

---

## ⚙️ General Configuration (`config.toml`)

```toml
[general]
refresh_rate_ms = 1000
default_panel = "overview" # "overview", "processes", "disks", "network", "diagnostics"
default_theme = "midnight"
enable_mouse = true
history_length_sec = 300   # 5 minutes of historical retention

[thresholds]
cpu_warning_pct    = 80.0
cpu_critical_pct   = 95.0
memory_warning_pct = 85.0
memory_critical_pct= 95.0
disk_warning_pct   = 85.0
disk_critical_pct  = 95.0
temp_warning_c     = 80.0
temp_critical_c    = 90.0
```
