# Zyphor Troubleshooting Guide

## Terminal Display Issues

### Unicode Box Drawing Misalignment
- **Cause**: Outdated terminal font lacking box-drawing glyphs (`╭`, `╮`, `─`, `│`).
- **Resolution**: Install modern developer fonts such as **Cascadia Code**, **JetBrains Mono**, or **Fira Code**, and enable UTF-8 mode in your shell (`chcp 65001`).

### Plain Mode Fallback
If running on a restricted console or serial link without TrueColor support, start Zyphor in plain ASCII mode:
```bash
zyphor --plain
```

### Access Denied on Binary Overwrite
If compiling Zyphor while an instance is running, stop the active process:
```powershell
Stop-Process -Name zyphor -Force
```
