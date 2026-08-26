# Theming & Customization Guide

Zyphor features a 24-bit TrueColor rendering pipeline supporting complete palette switching, custom theme definitions, layout geometry overrides, and plain ASCII fallbacks.

---

## 🎨 Built-in Color Themes

You can cycle through themes at runtime inside the TUI by pressing <kbd>T</kbd>.

### 1. Midnight (Default)
Designed for low eye strain in modern dark developer environments:
* **Background (`bg`):** `#0D1117` (Deep GitHub Slate)
* **Foreground (`fg`):** `#DCE4EE` (Crisp Light Gray)
* **Accent (`accent`):** `#58A6FF` (Electric Azure Blue)
* **Secondary (`secondary`):** `#38BDF8` (Sky Blue)
* **Success (`success`):** `#3FB950` (Emerald Green)
* **Warning (`warning`):** `#D29922` (Amber)
* **Critical (`critical`):** `#F85149` (Vibrant Coral Red)

### 2. Cyber
A high-contrast neon palette tuned for high-energy synthwave/cyberpunk setups:
* **Background:** `#06060C`
* **Accent:** `#FF0080` (Hot Pink)
* **Secondary:** `#00F0FF` (Cyan)
* **Success:** `#00FF88` (Neon Green)

### 3. Aurora
Inspired by northern lights:
* **Background:** `#0E1620`
* **Accent:** `#34D399` (Seafoam Mint)
* **Secondary:** `#A78BFA` (Soft Violet)

### 4. Nord
Based on the arctic palette:
* **Background:** `#2E3440` (Polar Night)
* **Foreground:** `#ECEFF4` (Snow Storm)
* **Accent:** `#88C0D0` (Frost Blue)

### 5. Solarized Dark
Classic low-contrast palette designed for reduced visual fatigue during extended diagnostic shifts:
* **Background:** `#002B36`
* **Accent:** `#268BD2` (Blue)
* **Secondary:** `#2AA198` (Cyan)

### 6. Gruvbox
Warm retro contrast palette:
* **Background:** `#1D2021` (Dark Hard)
* **Foreground:** `#EBDBB2` (Light Cream)
* **Accent:** `#FABD2F` (Bright Yellow/Gold)
* **Secondary:** `#D65D0E` (Cinnamon Orange)

### 7. High Contrast (Accessibility / Monochrome)
Pure contrast for accessibility or monochrome monitors:
* **Background:** `#000000`
* **Foreground:** `#FFFFFF`
* **Accent:** `#00FFFF`

---

## ⚙️ Plain ASCII Fallback Mode (`--plain`)

When running on vintage terminals, serial consoles over UART, or remote SSH tunnels without 24-bit TrueColor support, start Zyphor with the `--plain` flag:

```bash
zyphor --plain
```

In Plain Mode:
* All ANSI color escape sequences are suppressed.
* Box borders switch from Unicode rounded lines (`╭─╮`) to standard ASCII (`+--+`, `|`).
* Gauges switch from Unicode blocks (`█░`) to standard ASCII characters (`[####....]`).
* Sparklines use ASCII height markers (`. - = # !`).

---

## 🛠️ Color Token Reference

Every theme is represented as a structured data type in `src/ui/theme.zig`:

| Token | Semantic Role |
| :--- | :--- |
| `bg` | Main viewport background |
| `fg` | Primary body text and values |
| `header_bg` | Top-level full-width header bar background |
| `tab_bg` | Tab navigation strip & status bar background |
| `accent` | Primary focus indicators, active tab, CPU gauge highlights |
| `accent_dim` | Thin horizontal/vertical separator lines |
| `secondary` | Memory/Swap metrics, RAM gauge highlights |
| `success` | Nominal health indicators, UP network interfaces |
| `warning` | Moderately elevated metrics, warning alerts |
| `critical` | Resource saturation, critical alerts, DOWN interfaces |
| `border` | Box-drawing container borders |
| `selected` | Highlighted process row background cursor |
| `muted` | Secondary labels, timestamps, inactive tabs |
