# Zyphor Development Walkthrough

## What we accomplished:
1. **Theme Shortcut Fix**: Fixed the theme toggle shortcut. You can now cycle themes using Shift+T or the ] bracket key. 
2. **Benchmark Mode & Overhead Profiler (PRD §47)**: Created a new CLI command zyphor overhead that repeatedly samples the engine to empirically measure and prove Zyphor's lightweight performance.
3. **Root/Admin Mode (PRD §81)**: Added an automatic elevation check across platforms (AllocateAndInitializeSid on Windows, getuid on Unix). Zyphor now dynamically displays a [ROOT] or [USER] badge in the header without needing hardcoded arguments.

## Validation
* Run .\zig-out\bin\zyphor.exe overhead to see Zyphor's self-profiling results (averaging ~14ms per snapshot and using ~3MB RAM).
* Open the UI and press ] or Shift+T to instantly cycle through the built-in color themes.
