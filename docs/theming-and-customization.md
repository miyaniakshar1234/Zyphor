# 🎨 Zyphor Theming & Visual Customization Guide

*Author: Akshar Miyani • Version: 1.0.0 • TrueColor Palette Guide*

---

## Table of Contents
1. [24-Bit TrueColor Rendering Pipeline](#1-24-bit-truecolor-rendering-pipeline)
2. [Built-in Palette Catalog (10 Curated Themes)](#2-built-in-palette-catalog-10-curated-themes)
3. [Runtime Theme Cycling (`]` or `Shift+T`)](#3-runtime-theme-cycling--or-shiftt)
4. [Plain ASCII Fallback Mode (`--plain`)](#4-plain-ascii-fallback-mode---plain)
5. [Semantic Color Token Architecture](#5-semantic-color-token-architecture)

---

## 1. 24-Bit TrueColor Rendering Pipeline

Zyphor renders in authentic 24-bit TrueColor (16.7 million RGB colors) using direct ANSI escape sequences (`\x1b[38;2;R;G;Bm` for foreground and `\x1b[48;2;R;G;Bm` for background). 

Because the differential rendering engine caches cell attributes, color escapes are only emitted when transitioning between different foreground/background color tokens, minimizing terminal latency.

---

## 2. Built-in Palette Catalog (10 Curated Themes)

### 1. Anthropic (Default Warm Aesthetic)
*A sophisticated, warm dark palette inspired by modern AI research interfaces.*
* **Background (`bg`):** `#1F1D1C` (Warm Charcoal)
* **Foreground (`fg`):** `#E6E4E2` (Soft Ivory)
* **Accent (`accent`):** `#D97757` (Terracotta Coral)
* **Secondary (`secondary`):** `#E5C07B` (Sand Amber)
* **Success (`success`):** `#718E75` (Sage Green)
* **Warning (`warning`):** `#E59866` (Warm Tangerine)
* **Critical (`critical`):** `#E06C75` (Muted Crimson)

### 2. Cyber (High-Contrast Neon)
*Designed for cyberpunk setups and OLED screens.*
* **Background:** `#06060C`
* **Accent:** `#00F0FF` (Electric Cyan)
* **Secondary:** `#FF0080` (Neon Magenta)
* **Success:** `#00FF88` (Radioactive Green)

### 3. Tokyo Night
*Deep indigo night palette with high legibility.*
* **Background:** `#1A1B26` (Deep Indigo)
* **Foreground:** `#A9B1D6` (Silver Lavender)
* **Accent:** `#7DCFFF` (Ice Cyan)
* **Secondary:** `#BB9AF7` (Soft Purple)

### 4. Hacker (CRT Phosphor)
*Classic retro monochrome computing aesthetic.*
* **Background:** `#0C100C` (Obsidian)
* **Foreground:** `#20C20E` (Phosphor Green)
* **Accent:** `#39FF14` (Neon Green)

### 5. Midnight
*Modern dark slate foundation.*
* **Background:** `#0D1117`
* **Accent:** `#58A6FF` (Azure Blue)
* **Secondary:** `#38BDF8` (Sky Blue)

### 6. Aurora
*Nordic evening glow.*
* **Background:** `#0E1620`
* **Accent:** `#34D399` (Seafoam Mint)
* **Secondary:** `#A78BFA` (Soft Violet)

### 7. Nord
*Authentic arctic design tokens.*
* **Background:** `#2E3440` (Polar Night)
* **Foreground:** `#ECEFF4` (Snow Storm)
* **Accent:** `#88C0D0` (Frost Blue)

### 8. Solarized Dark
*Classic low-contrast palette tuned for reduced visual fatigue.*
* **Background:** `#002B36`
* **Accent:** `#268BD2` (Solar Blue)
* **Secondary:** `#2AA198` (Solar Cyan)

### 9. Gruvbox
*Warm retro contrast with earthy tones.*
* **Background:** `#1D2021` (Dark Hard)
* **Foreground:** `#EBDBB2` (Light Cream)
* **Accent:** `#FABD2F` (Bright Gold)

### 10. High Contrast (Monochrome)
*Pure black/white contrast for accessibility.*
* **Background:** `#000000`
* **Foreground:** `#FFFFFF`
* **Accent:** `#00FFFF`

---

## 3. Runtime Theme Cycling (`]` or `Shift+T`)

At any time during active TUI monitoring, press <kbd>]</kbd> or <kbd>Shift+T</kbd> to cycle instantly to the next theme. 
The differential engine marks all screen cells as dirty and re-paints the entire viewport with the new color tokens on the next tick without interrupting process polling.

You can also start Zyphor directly with your preferred theme:
```bash
zyphor --theme cyber
zyphor --theme tokyo_night
zyphor --theme nord
```

---

## 4. Plain ASCII Fallback Mode (`--plain`)

When monitoring vintage hardware, serial consoles (UART), or remote SSH tunnels lacking TrueColor support, launch with:
```bash
zyphor --plain
```

* Suppresses all ANSI color codes.
* Switches borders from Unicode curves (`╭─╮`) to standard ASCII (`+--+`, `|`).
* Uses standard bracket gauges (`[####....]`) instead of Unicode blocks (`█░`).
* Replaces Braille graphs with ASCII sparklines (`. - = # !`).

---

## 5. Semantic Color Token Architecture

Themes in Zyphor conform to the `Theme` struct (`src/ui/theme.zig`):

| Token | Semantic Role |
| :--- | :--- |
| `bg` | Viewport canvas background color. |
| `fg` | Standard body typography and numerical data. |
| `header_bg` | Top full-width application header background. |
| `tab_bg` | Navigation strip and status bar background. |
| `accent` | Primary focal points, active tab highlights, and CPU meters. |
| `accent_dim` | Dividers, container boundaries, and inactive elements. |
| `secondary` | Physical Memory metrics and RAM gauge highlights. |
| `success` | Nominal health indicators (100–90 score) and active network links. |
| `warning` | Moderately elevated metrics (75–89 score) and caution alerts. |
| `critical` | Resource saturation (<75 score), thermal throttling, and down links. |
| `border` | CyberBox and AccentBox container border lines. |
| `selected` | Highlighted process/service row background cursor. |
| `muted` | Secondary labels, timestamps, units (`MB`, `GHz`), and inactive tabs. |

---

*Authored with precision by Akshar Miyani.*
