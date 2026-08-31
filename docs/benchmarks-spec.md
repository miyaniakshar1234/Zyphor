# Zyphor Hardware Benchmark Specification (PRD §25)

## Overview
The Zyphor benchmark suite evaluates system compute throughput, multi-threaded vector arithmetic, memory sequential bandwidth, and memory access latency under synthetic memory-pressure profiles.

## Benchmark Metrics & Formulas

### 1. Single-Core Integer Throughput (MOP/s)
- **Algorithm:** 50,000,000 non-linear integer bit-manipulation iterations.
- **Formula:** `(Iterations / 1,000,000) / Elapsed_Seconds`

### 2. Multi-Core Floating-Point Rate (GFLOPS)
- **Algorithm:** Parallel thread pool (up to 64 hardware worker threads) performing fused multiply-add operations.
- **Formula:** `(Total_Operations / 1,000,000,000) / Elapsed_Seconds`

### 3. Memory Sequential Bandwidth (GB/s)
- **Algorithm:** 64 MB sequential contiguous memory allocation with memory barrier invalidation.
- **Read Throughput:** `Buffer_Size_GB / Read_Duration_Seconds`
- **Write Throughput:** `Buffer_Size_GB / Write_Duration_Seconds`

### 4. Memory Pointer-Chasing Latency (ns)
- **Algorithm:** 256K node pseudo-random stride chasing across a 16 MB span to defeat L1/L2 hardware prefetchers.
- **Formula:** `Elapsed_Nanoseconds / Stride_Iterations`

### 5. Composite Zyphor Hardware Index
- `Composite_Score = (CPU_Single_MOPs * 1.5) + (CPU_Multi_GFLOPS * 250.0) + ((RAM_Read + RAM_Write) * 60.0)`
