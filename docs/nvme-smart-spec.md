# NVMe SMART Health & Spare Capacity Analyzer

## 1. NVMe Log Page 0x02 Fields
Zyphor extracts raw telemetry from the standard NVMe 1.4+ SMART / Health Information Log (Log Identifier `0x02`):

| Byte Offset | Field Description | Unit / Encoding |
|---|---|---|
| `0` | Critical Warning | Bitmask (Spare, Temp, Reliability, Read Only, Backup) |
| `1:2` | Composite Temperature | Kelvin ($T_C = K - 273.15$) |
| `3` | Available Spare | Percentage (0–100%) |
| `4` | Available Spare Threshold | Threshold below which warning alert triggers |
| `5` | Percentage Used | Endurance estimate (0–100%, can exceed 100%) |
| `32:47` | Data Units Read | Units of 1,000 sectors of 512 bytes (~500 KB) |
| `48:63` | Data Units Written | Units of 1,000 sectors of 512 bytes (~500 KB) |
| `96:111`| Power On Hours | Cumulative run hours |
| `112:127`| Unsafe Shutdowns | Power cycles without flush notification |

## 2. Health Threshold Alerting
- If `Available Spare < Available Spare Threshold`: Critical disk exhaustion alert emitted.
- If `Critical Warning != 0`: Hardware anomaly diagnostic logged to Observability event stream.
