# Zyphor SIMD Accelerated TrueColor Differential Engine

## Overview
Zyphor's terminal rendering engine achieves sub-microsecond frame diffing through SIMD-accelerated cell comparison (AVX2 on x86_64, NEON on ARM64).

## Differential Algorithm
- **128-bit Vectorized Cell Hashes:** Packs character UTF-8 bytes, 24-bit RGB foreground, 24-bit RGB background, and style bits into a 16-byte packed word.
- **Vectorized Equality (`_mm256_cmpeq_epi8` / `vceqq_u8`):** Compares 16 cells simultaneously in a single CPU instruction.
- **Minimal SGR Emission:** Emits ANSI escape codes (`\x1b[38;2;R;G;Bm`) only when the active cell style transitions across non-contiguous terminal coordinates.
