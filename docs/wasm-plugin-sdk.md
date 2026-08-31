# Zyphor WebAssembly (Wasm) Plugin SDK & Widget Extensions

## Overview
Zyphor provides an extensible sandbox runtime allowing developers to author custom telemetry visualizers, protocol analyzers, and panel widgets in Rust, Zig, C, or Go compiled to WebAssembly (`wasm32-wasi`).

## Plugin API Interface

```zig
pub const ZyphorPluginHeader = extern struct {
    magic: u32 = 0x5A595048, // 'ZYPH'
    abi_version: u16 = 1,
    widget_name: [32]u8,
    preferred_tab: u8,
};

pub const PluginCallbacks = struct {
    init: *const fn() callconv(.c) i32,
    sample: *const fn(snapshot_ptr: [*]const u8, len: usize) callconv(.c) void,
    render: *const fn(buf_ptr: [*]u8, width: u16, height: u16) callconv(.c) void,
    deinit: *const fn() callconv(.c) void,
};
```

## Security Sandbox
- **Memory Isolation:** Plugins execute within strict 16 MB WebAssembly linear memory bounds.
- **Capability-Based I/O:** Network and filesystem access require explicit user permissions via `zyphor.json`.
- **Preemptive Execution Limits:** 5ms execution budget per frame to prevent TUI rendering stalls.
