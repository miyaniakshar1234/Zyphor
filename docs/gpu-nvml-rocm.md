# NVIDIA NVML & AMD ROCm SMI Hardware Telemetry Specification

## 1. Dynamic Library Binding
Zyphor dynamically detects and binds GPU vendor telemetry libraries at runtime to avoid hard link-time dependencies:

- **NVIDIA:**
  - Windows: `nvml.dll` in `%ProgramFiles%\NVIDIA Corporation\NVSMI\` or `%SystemRoot%\System32\`
  - Linux: `libnvidia-ml.so.1` or `libnvidia-ml.so`
- **AMD:**
  - Windows: `rocm_smi64.dll`
  - Linux: `librocm_smi64.so.1` or `librocm_smi64.so`

## 2. Telemetry Fields & Units
| Metric | Type | Unit | Description |
|---|---|---|---|
| `utilization_gpu` | `f32` | % (0.0–100.0) | Percent of time graphics/compute kernels were active |
| `utilization_memory`| `f32` | % (0.0–100.0) | Percent of time memory controller was reading/writing |
| `vram_used` | `u64` | Bytes | Dedicated framebuffer VRAM allocation |
| `vram_total` | `u64` | Bytes | Total physical VRAM capacity |
| `temperature_edge` | `f32` | °C | GPU die core temperature |
| `temperature_hotspot`| `?f32`| °C | Maximum junction temperature hotspot |
| `fan_speed_pct` | `?u8` | % (0–100) | PWM fan speed percentage |
| `power_draw_watts` | `?f32`| Watts | Instantaneous board power consumption |
| `clock_graphics_mhz`| `?u32`| MHz | Core graphics shader frequency |

## 3. Sampling Cadence & Overhead
- GPU metrics are polled on a background thread at 1000ms intervals.
- NVML calls are batched into a single context query to restrict kernel mode context-switch latency under 150 microseconds per sample.
