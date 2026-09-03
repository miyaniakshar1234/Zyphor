# DNS Resolver Latency & Packet Jitter Analyzer

## 1. Network Probe Architecture
The DNS latency analyzer performs active UDP probing of upstream resolvers:

```
[Zyphor Engine]
       │ (Non-blocking UDP Socket)
       ├──────────────► [Resolver 1: 1.1.1.1] ──► RTT: 12.4ms
       ├──────────────► [Resolver 2: 8.8.8.8] ──► RTT: 15.1ms
       └──────────────► [Local Gateway DNS]   ──► RTT:  1.8ms
```

## 2. Mathematical Calculations
- **Round-Trip Time (RTT):**
  $$RTT = T_{recv} - T_{send}$$
- **Statistical Jitter (RFC 3550):**
  $$J(i) = J(i-1) + \frac{|D(i-1, i)| - J(i-1)}{16}$$
  where $D(i-1, i) = (R_i - S_i) - (R_{i-1} - S_{i-1})$.
- **Packet Loss Rate:** Calculated across a rolling sliding window of the last 60 probe cycles.
