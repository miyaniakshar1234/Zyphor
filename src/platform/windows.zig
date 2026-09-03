const std = @import("std");
const types = @import("../core/types.zig");
const PlatformCollector = @import("interface.zig").PlatformCollector;

const windows = std.os.windows;
const BOOL = i32;
const DWORD = windows.DWORD;
const HANDLE = windows.HANDLE;

// ═══════════════════════════════════════════════════════════════════════════
// Win32 Struct Definitions
// ═══════════════════════════════════════════════════════════════════════════

pub const FILETIME = extern struct {
    dwLowDateTime: DWORD = 0,
    dwHighDateTime: DWORD = 0,

    pub fn toU64(self: FILETIME) u64 {
        return (@as(u64, self.dwHighDateTime) << 32) | @as(u64, self.dwLowDateTime);
    }
};

pub const MEMORYSTATUSEX = extern struct {
    dwLength: DWORD = @sizeOf(MEMORYSTATUSEX),
    dwMemoryLoad: DWORD = 0,
    ullTotalPhys: u64 = 0,
    ullAvailPhys: u64 = 0,
    ullTotalPageFile: u64 = 0,
    ullAvailPageFile: u64 = 0,
    ullTotalVirtual: u64 = 0,
    ullAvailVirtual: u64 = 0,
    ullAvailExtendedVirtual: u64 = 0,
};

pub const SYSTEM_POWER_STATUS = extern struct {
    ACLineStatus: u8 = 255,
    BatteryFlag: u8 = 255,
    BatteryLifePercent: u8 = 255,
    SystemStatusFlag: u8 = 0,
    BatteryLifeTime: DWORD = 0,
    BatteryFullLifeTime: DWORD = 0,
};

pub const PROCESSENTRY32W = extern struct {
    dwSize: DWORD = @sizeOf(PROCESSENTRY32W),
    cntUsage: DWORD = 0,
    th32ProcessID: DWORD = 0,
    th32DefaultHeapID: usize = 0,
    th32ModuleID: DWORD = 0,
    cntThreads: DWORD = 0,
    th32ParentProcessID: DWORD = 0,
    pcPriClassBase: i32 = 0,
    dwFlags: DWORD = 0,
    szExeFile: [260]u16 = @splat(0),
};

pub const PROCESS_MEMORY_COUNTERS_EX = extern struct {
    cb: DWORD = @sizeOf(PROCESS_MEMORY_COUNTERS_EX),
    PageFaultCount: DWORD = 0,
    PeakWorkingSetSize: usize = 0,
    WorkingSetSize: usize = 0,
    QuotaPeakPagedPoolUsage: usize = 0,
    QuotaPagedPoolUsage: usize = 0,
    QuotaPeakNonPagedPoolUsage: usize = 0,
    QuotaNonPagedPoolUsage: usize = 0,
    PagefileUsage: usize = 0,
    PeakPagefileUsage: usize = 0,
    PrivateUsage: usize = 0,
};

// Per-core CPU times from NtQuerySystemInformation(class 8)
pub const SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION = extern struct {
    IdleTime: i64 = 0, // 100-nanosecond ticks
    KernelTime: i64 = 0, // Includes IdleTime!
    UserTime: i64 = 0,
    DpcTime: i64 = 0,
    InterruptTime: i64 = 0,
    InterruptCount: u32 = 0,
    _padding: u32 = 0,
};

// TCP connection with owning PID
pub const MIB_TCPROW_OWNER_PID = extern struct {
    dwState: u32 = 0,
    dwLocalAddr: u32 = 0,
    dwLocalPort: u32 = 0,
    dwRemoteAddr: u32 = 0,
    dwRemotePort: u32 = 0,
    dwOwningPid: u32 = 0,
};

pub const MIB_TCPTABLE_OWNER_PID = extern struct {
    dwNumEntries: u32 = 0,
    table: [1]MIB_TCPROW_OWNER_PID = undefined,
};

// Service enumeration
pub const SERVICE_STATUS_PROCESS = extern struct {
    dwServiceType: u32 = 0,
    dwCurrentState: u32 = 0,
    dwControlsAccepted: u32 = 0,
    dwWin32ExitCode: u32 = 0,
    dwServiceSpecificExitCode: u32 = 0,
    dwCheckPoint: u32 = 0,
    dwWaitHint: u32 = 0,
    dwProcessId: u32 = 0,
    dwServiceFlags: u32 = 0,
};

pub const ENUM_SERVICE_STATUS_PROCESSW = extern struct {
    lpServiceName: [*:0]u16 = undefined,
    lpDisplayName: [*:0]u16 = undefined,
    ServiceStatusProcess: SERVICE_STATUS_PROCESS = .{},
};

// GPU adapter detection
pub const DISPLAY_DEVICEW = extern struct {
    cb: DWORD = @sizeOf(DISPLAY_DEVICEW),
    DeviceName: [32]u16 = @splat(0),
    DeviceString: [128]u16 = @splat(0),
    StateFlags: DWORD = 0,
    DeviceID: [128]u16 = @splat(0),
    DeviceKey: [128]u16 = @splat(0),
};

// Network interface (MIB_IFROW - simpler v1 API for reliable struct layout)
pub const MIB_IFROW = extern struct {
    wszName: [256]u16 = @splat(0),
    dwIndex: DWORD = 0,
    dwType: DWORD = 0,
    dwMtu: DWORD = 0,
    dwSpeed: DWORD = 0,
    dwPhysAddrLen: DWORD = 0,
    bPhysAddr: [8]u8 = @splat(0),
    dwAdminStatus: DWORD = 0,
    dwOperStatus: DWORD = 0,
    dwLastChange: DWORD = 0,
    dwInOctets: DWORD = 0,
    dwInUcastPkts: DWORD = 0,
    dwInNUcastPkts: DWORD = 0,
    dwInDiscards: DWORD = 0,
    dwInErrors: DWORD = 0,
    dwInUnknownProtos: DWORD = 0,
    dwOutOctets: DWORD = 0,
    dwOutUcastPkts: DWORD = 0,
    dwOutNUcastPkts: DWORD = 0,
    dwOutDiscards: DWORD = 0,
    dwOutErrors: DWORD = 0,
    dwOutQLen: DWORD = 0,
    dwDescrLen: DWORD = 0,
    bDescr: [256]u8 = @splat(0),
};

pub const MIB_IFTABLE = extern struct {
    dwNumEntries: DWORD = 0,
    table: [1]MIB_IFROW = undefined,
};

// Registry
pub const HKEY = *anyopaque;

// ═══════════════════════════════════════════════════════════════════════════
// Constants
// ═══════════════════════════════════════════════════════════════════════════

const TH32CS_SNAPPROCESS: DWORD = 0x00000002;
const PROCESS_QUERY_LIMITED_INFORMATION: DWORD = 0x1000;
const PROCESS_TERMINATE: DWORD = 0x0001;
const PROCESS_SUSPEND_RESUME: DWORD = 0x0800;
const INVALID_HANDLE_VALUE = @as(HANDLE, @ptrFromInt(std.math.maxInt(usize)));
const SystemProcessorPerformanceInformation: u32 = 8;
const KEY_QUERY_VALUE: u32 = 0x0001;
const REG_SZ: u32 = 1;
const REG_DWORD: u32 = 4;
const HKEY_LOCAL_MACHINE: HKEY = @ptrFromInt(0x80000002);
const TCP_TABLE_OWNER_PID_ALL: u32 = 5;
const AF_INET: u32 = 2;
const ERROR_INSUFFICIENT_BUFFER: u32 = 122;
const SC_MANAGER_CONNECT: u32 = 0x0001;
const SC_MANAGER_ENUMERATE_SERVICE: u32 = 0x0004;
const SERVICE_WIN32: u32 = 0x00000030;
const SERVICE_STATE_ALL: u32 = 0x00000003;
const SC_ENUM_PROCESS_INFO: u32 = 0;
const DISPLAY_DEVICE_ACTIVE: DWORD = 0x00000001;

// ═══════════════════════════════════════════════════════════════════════════
// Extern Function Declarations
// ═══════════════════════════════════════════════════════════════════════════

// kernel32
extern "kernel32" fn GetSystemTimes(
    lpIdleTime: ?*FILETIME,
    lpKernelTime: ?*FILETIME,
    lpUserTime: ?*FILETIME,
) callconv(.winapi) BOOL;

extern "kernel32" fn GlobalMemoryStatusEx(
    lpBuffer: *MEMORYSTATUSEX,
) callconv(.winapi) BOOL;

extern "kernel32" fn GetSystemPowerStatus(
    lpSystemPowerStatus: *SYSTEM_POWER_STATUS,
) callconv(.winapi) BOOL;

extern "kernel32" fn CreateToolhelp32Snapshot(
    dwFlags: DWORD,
    th32ProcessID: DWORD,
) callconv(.winapi) HANDLE;

extern "kernel32" fn Process32FirstW(
    hSnapshot: HANDLE,
    lppe: *PROCESSENTRY32W,
) callconv(.winapi) BOOL;

extern "kernel32" fn Process32NextW(
    hSnapshot: HANDLE,
    lppe: *PROCESSENTRY32W,
) callconv(.winapi) BOOL;

extern "kernel32" fn OpenProcess(
    dwDesiredAccess: DWORD,
    bInheritHandle: BOOL,
    dwProcessId: DWORD,
) callconv(.winapi) ?HANDLE;

extern "kernel32" fn CloseHandle(
    hObject: HANDLE,
) callconv(.winapi) BOOL;

extern "kernel32" fn TerminateProcess(
    hProcess: HANDLE,
    uExitCode: c_uint,
) callconv(.winapi) BOOL;

extern "kernel32" fn GetProcessTimes(
    hProcess: HANDLE,
    lpCreationTime: *FILETIME,
    lpExitTime: *FILETIME,
    lpKernelTime: *FILETIME,
    lpUserTime: *FILETIME,
) callconv(.winapi) BOOL;

extern "kernel32" fn GetDiskFreeSpaceExW(
    lpDirectoryName: ?[*:0]const u16,
    lpFreeBytesAvailableToCaller: ?*u64,
    lpTotalNumberOfBytes: ?*u64,
    lpTotalNumberOfFreeBytes: ?*u64,
) callconv(.winapi) BOOL;

extern "kernel32" fn GetLogicalDriveStringsW(
    nBufferLength: DWORD,
    lpBuffer: [*]u16,
) callconv(.winapi) DWORD;

extern "kernel32" fn GetDriveTypeW(
    lpRootPathName: ?[*:0]const u16,
) callconv(.winapi) c_uint;

extern "kernel32" fn GetVolumeInformationW(
    lpRootPathName: ?[*:0]const u16,
    lpVolumeNameBuffer: ?[*]u16,
    nVolumeNameSize: DWORD,
    lpVolumeSerialNumber: ?*DWORD,
    lpMaximumComponentLength: ?*DWORD,
    lpFileSystemFlags: ?*DWORD,
    lpFileSystemNameBuffer: ?[*]u16,
    nFileSystemNameSize: DWORD,
) callconv(.winapi) BOOL;

// ntdll
extern "ntdll" fn NtSuspendProcess(
    hProcess: HANDLE,
) callconv(.winapi) windows.NTSTATUS;

extern "ntdll" fn NtResumeProcess(
    hProcess: HANDLE,
) callconv(.winapi) windows.NTSTATUS;

extern "ntdll" fn NtQuerySystemInformation(
    SystemInformationClass: u32,
    SystemInformation: *anyopaque,
    SystemInformationLength: u32,
    ReturnLength: ?*u32,
) callconv(.winapi) windows.NTSTATUS;

// psapi
extern "psapi" fn GetProcessMemoryInfo(
    Process: HANDLE,
    ppsmemCounters: *PROCESS_MEMORY_COUNTERS_EX,
    cb: DWORD,
) callconv(.winapi) BOOL;

// advapi32 — Registry
extern "advapi32" fn RegOpenKeyExW(
    hKey: HKEY,
    lpSubKey: [*:0]const u16,
    ulOptions: u32,
    samDesired: u32,
    phkResult: *HKEY,
) callconv(.winapi) i32;

extern "advapi32" fn RegQueryValueExW(
    hKey: HKEY,
    lpValueName: ?[*:0]const u16,
    lpReserved: ?*u32,
    lpType: ?*u32,
    lpData: ?[*]u8,
    lpcbData: ?*u32,
) callconv(.winapi) i32;

extern "advapi32" fn RegCloseKey(
    hKey: HKEY,
) callconv(.winapi) i32;

// advapi32 — Service Control Manager
extern "advapi32" fn OpenSCManagerW(
    lpMachineName: ?[*:0]const u16,
    lpDatabaseName: ?[*:0]const u16,
    dwDesiredAccess: u32,
) callconv(.winapi) ?HANDLE;

extern "advapi32" fn EnumServicesStatusExW(
    hSCManager: HANDLE,
    InfoLevel: u32,
    dwServiceType: u32,
    dwServiceState: u32,
    lpServices: ?[*]u8,
    cbBufSize: u32,
    pcbBytesNeeded: *u32,
    lpServicesReturned: *u32,
    lpResumeHandle: ?*u32,
    pszGroupName: ?[*:0]const u16,
) callconv(.winapi) BOOL;

extern "advapi32" fn CloseServiceHandle(
    hSCObject: HANDLE,
) callconv(.winapi) BOOL;

// iphlpapi — Network
extern "iphlpapi" fn GetIfTable(
    pIfTable: ?*MIB_IFTABLE,
    pdwSize: *DWORD,
    bOrder: BOOL,
) callconv(.winapi) DWORD;

extern "iphlpapi" fn GetExtendedTcpTable(
    pTcpTable: ?*anyopaque,
    pdwSize: *DWORD,
    bOrder: BOOL,
    ulAf: u32,
    TableClass: u32,
    Reserved: u32,
) callconv(.winapi) DWORD;

// user32 — Display device (GPU name)
extern "user32" fn EnumDisplayDevicesW(
    lpDevice: ?[*:0]const u16,
    iDevNum: DWORD,
    lpDisplayDevice: *DISPLAY_DEVICEW,
    dwFlags: DWORD,
) callconv(.winapi) BOOL;

// ═══════════════════════════════════════════════════════════════════════════
// Helper Types
// ═══════════════════════════════════════════════════════════════════════════

const ProcessTimeEntry = struct {
    pid: DWORD = 0,
    total_time: u64 = 0,
    used: bool = false,
};

const IfState = struct {
    index: DWORD = 0,
    prev_in: u64 = 0,
    prev_out: u64 = 0,
    used: bool = false,
};

const MAX_CORES = 256;
const MAX_IFACES = 32;

// ═══════════════════════════════════════════════════════════════════════════
// WindowsCollector — All Real Data
// ═══════════════════════════════════════════════════════════════════════════

pub const WindowsCollector = struct {
    // CPU aggregate state
    prev_idle: u64 = 0,
    prev_kernel: u64 = 0,
    prev_user: u64 = 0,
    last_system_delta: u64 = 1,
    num_cores: u32 = 1,
    initialized: bool = false,
    proc_times: [2048]ProcessTimeEntry = @splat(.{}),

    // Per-core CPU state (real via NtQuerySystemInformation)
    prev_core_info: [MAX_CORES]SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION = @splat(.{}),
    core_info_initialized: bool = false,

    // CPU identity (read once from registry at init)
    cpu_name: [128]u8 = @splat(0),
    cpu_name_len: usize = 0,
    cpu_freq_mhz: u32 = 0,

    // Network interface state for delta computation
    if_states: [MAX_IFACES]IfState = @splat(.{}),
    if_state_count: usize = 0,
    net_prev_timestamp: i128 = 0,

    // GPU name (read once at init via EnumDisplayDevices)
    gpu_name: [64]u8 = @splat(0),
    gpu_name_len: usize = 0,
    gpu_detected: bool = false,

    pub fn init() WindowsCollector {
        var num_cores: u32 = 1;
        if (std.Thread.getCpuCount()) |count| {
            num_cores = @as(u32, @intCast(count));
        } else |_| {
            num_cores = 4;
        }

        var col = WindowsCollector{
            .num_cores = num_cores,
        };

        // Initialize aggregate CPU timing
        var idle_ft: FILETIME = .{};
        var kernel_ft: FILETIME = .{};
        var user_ft: FILETIME = .{};
        if (GetSystemTimes(&idle_ft, &kernel_ft, &user_ft) != 0) {
            col.prev_idle = idle_ft.toU64();
            col.prev_kernel = kernel_ft.toU64();
            col.prev_user = user_ft.toU64();
            col.initialized = true;
        }

        // Read real CPU name and frequency from registry
        col.readCpuInfoFromRegistry();

        // Read GPU adapter name
        col.readGpuName();

        // Initialize per-core CPU baseline
        col.initPerCoreCpu();

        return col;
    }

    fn readCpuInfoFromRegistry(self: *WindowsCollector) void {
        const subkey = std.unicode.utf8ToUtf16LeStringLiteral("HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0");
        var hKey: HKEY = undefined;
        if (RegOpenKeyExW(HKEY_LOCAL_MACHINE, subkey, 0, KEY_QUERY_VALUE, &hKey) != 0) return;
        defer _ = RegCloseKey(hKey);

        // Read ProcessorNameString (REG_SZ, UTF-16)
        const name_val = std.unicode.utf8ToUtf16LeStringLiteral("ProcessorNameString");
        var name_buf: [256]u8 = @splat(0);
        var name_size: u32 = @sizeOf(@TypeOf(name_buf));
        var name_type: u32 = 0;
        if (RegQueryValueExW(hKey, name_val, null, &name_type, &name_buf, &name_size) == 0 and name_type == REG_SZ) {
            // name_buf contains UTF-16LE data, convert to UTF-8
            const u16_ptr: [*]const u16 = @ptrCast(@alignCast(&name_buf));
            const u16_len = name_size / 2;
            if (u16_len > 0) {
                // Find actual string length (exclude null terminator)
                var actual_len: usize = 0;
                while (actual_len < u16_len and u16_ptr[actual_len] != 0) : (actual_len += 1) {}
                if (std.unicode.utf16LeToUtf8(&self.cpu_name, u16_ptr[0..actual_len])) |converted| {
                    // Trim leading/trailing whitespace
                    var start: usize = 0;
                    while (start < converted and self.cpu_name[start] == ' ') : (start += 1) {}
                    var end: usize = converted;
                    while (end > start and self.cpu_name[end - 1] == ' ') : (end -= 1) {}
                    if (start > 0 and end > start) {
                        const trimmed_len = end - start;
                        std.mem.copyForwards(u8, self.cpu_name[0..trimmed_len], self.cpu_name[start..end]);
                        self.cpu_name_len = trimmed_len;
                    } else {
                        self.cpu_name_len = end;
                    }
                } else |_| {}
            }
        }

        // Read ~MHz (REG_DWORD)
        const mhz_val = std.unicode.utf8ToUtf16LeStringLiteral("~MHz");
        var mhz_data: u32 = 0;
        var mhz_size: u32 = @sizeOf(u32);
        var mhz_type: u32 = 0;
        if (RegQueryValueExW(hKey, mhz_val, null, &mhz_type, @as([*]u8, @ptrCast(&mhz_data)), &mhz_size) == 0 and mhz_type == REG_DWORD) {
            self.cpu_freq_mhz = mhz_data;
        }
    }

    fn readGpuName(self: *WindowsCollector) void {
        var dd = DISPLAY_DEVICEW{};
        var i: DWORD = 0;
        while (i < 16) : (i += 1) {
            dd.cb = @sizeOf(DISPLAY_DEVICEW);
            if (EnumDisplayDevicesW(null, i, &dd, 0) == 0) break;
            if (dd.StateFlags & DISPLAY_DEVICE_ACTIVE != 0) {
                // Convert DeviceString (GPU name) from UTF-16 to UTF-8
                var str_len: usize = 0;
                while (str_len < 128 and dd.DeviceString[str_len] != 0) : (str_len += 1) {}
                if (str_len > 0) {
                    if (std.unicode.utf16LeToUtf8(&self.gpu_name, dd.DeviceString[0..str_len])) |converted| {
                        self.gpu_name_len = converted;
                        self.gpu_detected = true;
                    } else |_| {}
                }
                break; // Use first active display device
            }
        }
    }

    fn initPerCoreCpu(self: *WindowsCollector) void {
        const count = @min(self.num_cores, MAX_CORES);
        const buf_size = @as(u32, @intCast(count * @sizeOf(SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION)));
        const status = NtQuerySystemInformation(
            SystemProcessorPerformanceInformation,
            @ptrCast(&self.prev_core_info),
            buf_size,
            null,
        );
        if (status == .SUCCESS) {
            self.core_info_initialized = true;
        }
    }

    const vtable_impl: PlatformCollector.VTable = .{
        .getCpuMetrics = getCpuMetrics,
        .getMemoryMetrics = getMemoryMetrics,
        .getDiskMetrics = getDiskMetrics,
        .getNetworkMetrics = getNetworkMetrics,
        .getGpuMetrics = getGpuMetrics,
        .getBatteryMetrics = getBatteryMetrics,
        .getProcessList = getProcessList,
        .getServices = getServices,
        .getSystemLogs = getSystemLogs,
        .killProcess = killProcess,
        .suspendProcess = suspendProcess,
        .resumeProcess = resumeProcess,
        .deinit = deinit,
    };

    pub fn collector(self: *WindowsCollector) PlatformCollector {
        return .{
            .ptr = self,
            .vtable = &vtable_impl,
        };
    }

    fn deinit(_: *anyopaque) void {}

    // ═══════════════════════════════════════════════════════════════════
    // CPU Metrics — REAL (GetSystemTimes + NtQuerySystemInformation)
    // ═══════════════════════════════════════════════════════════════════

    fn getCpuMetrics(ctx: *anyopaque, allocator: std.mem.Allocator) anyerror!types.CpuMetrics {
        const self: *WindowsCollector = @ptrCast(@alignCast(ctx));

        var idle_ft: FILETIME = .{};
        var kernel_ft: FILETIME = .{};
        var user_ft: FILETIME = .{};

        var cpu = types.CpuMetrics{
            .logical_cores = self.num_cores,
            .physical_cores = @max(1, self.num_cores / 2),
            .frequency_mhz = self.cpu_freq_mhz,
        };

        // Real CPU model name from registry
        if (self.cpu_name_len > 0) {
            @memcpy(cpu.model_name[0..self.cpu_name_len], self.cpu_name[0..self.cpu_name_len]);
            cpu.model_name_len = self.cpu_name_len;
        }

        // Real aggregate CPU usage via GetSystemTimes
        if (GetSystemTimes(&idle_ft, &kernel_ft, &user_ft) != 0) {
            const idle = idle_ft.toU64();
            const kernel = kernel_ft.toU64();
            const user = user_ft.toU64();

            if (self.initialized) {
                const idle_diff = idle -| self.prev_idle;
                const kernel_diff = kernel -| self.prev_kernel;
                const user_diff = user -| self.prev_user;

                const total = kernel_diff + user_diff;
                if (total > 0) {
                    self.last_system_delta = total;
                    const sys_diff = kernel_diff -| idle_diff;
                    const total_used = sys_diff + user_diff;
                    cpu.total_usage = @min(100.0, @as(f32, @floatFromInt(total_used)) * 100.0 / @as(f32, @floatFromInt(total)));
                    cpu.user_usage = @min(100.0, @as(f32, @floatFromInt(user_diff)) * 100.0 / @as(f32, @floatFromInt(total)));
                    cpu.system_usage = @min(100.0, @as(f32, @floatFromInt(sys_diff)) * 100.0 / @as(f32, @floatFromInt(total)));
                    cpu.idle_usage = @max(0.0, 100.0 - cpu.total_usage);
                }
            }

            self.prev_idle = idle;
            self.prev_kernel = kernel;
            self.prev_user = user;
            self.initialized = true;
        }

        // Real per-core CPU via NtQuerySystemInformation(class 8)
        const core_count = @min(self.num_cores, MAX_CORES);
        const cores = try allocator.alloc(f32, core_count);
        @memset(cores, 0.0);

        var curr_core_info: [MAX_CORES]SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION = @splat(.{});
        const buf_size = @as(u32, @intCast(core_count * @sizeOf(SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION)));
        const status = NtQuerySystemInformation(
            SystemProcessorPerformanceInformation,
            @ptrCast(&curr_core_info),
            buf_size,
            null,
        );

        if (status == .SUCCESS and self.core_info_initialized) {
            for (0..core_count) |i| {
                const curr = curr_core_info[i];
                const prev = self.prev_core_info[i];

                const delta_kernel: u64 = @intCast(@max(0, curr.KernelTime -| prev.KernelTime));
                const delta_user: u64 = @intCast(@max(0, curr.UserTime -| prev.UserTime));
                const delta_idle: u64 = @intCast(@max(0, curr.IdleTime -| prev.IdleTime));

                const total_ticks = delta_kernel + delta_user;
                if (total_ticks > 0) {
                    const active_ticks = total_ticks -| delta_idle;
                    cores[i] = @min(100.0, @as(f32, @floatFromInt(active_ticks)) * 100.0 / @as(f32, @floatFromInt(total_ticks)));
                }
            }
        }

        if (status == .SUCCESS) {
            @memcpy(self.prev_core_info[0..core_count], curr_core_info[0..core_count]);
            self.core_info_initialized = true;
        }

        cpu.core_usage = cores;
        return cpu;
    }

    // ═══════════════════════════════════════════════════════════════════
    // Memory Metrics — REAL (GlobalMemoryStatusEx)
    // ═══════════════════════════════════════════════════════════════════

    fn getMemoryMetrics(_: *anyopaque) anyerror!types.MemoryMetrics {
        var status = MEMORYSTATUSEX{};
        if (GlobalMemoryStatusEx(&status) == 0) {
            return error.WindowsMemoryQueryFailed;
        }

        const total_phys = status.ullTotalPhys;
        const avail_phys = status.ullAvailPhys;
        const used_phys = total_phys -| avail_phys;

        const total_page = status.ullTotalPageFile;
        const avail_page = status.ullAvailPageFile;
        const used_page = total_page -| avail_page;

        const used_pct = if (total_phys > 0)
            @as(f32, @floatFromInt(used_phys)) * 100.0 / @as(f32, @floatFromInt(total_phys))
        else
            0.0;

        const swap_pct = if (total_page > 0)
            @as(f32, @floatFromInt(used_page)) * 100.0 / @as(f32, @floatFromInt(total_page))
        else
            0.0;

        const pressure: types.MemoryPressureLevel = if (used_pct > 92.0)
            .critical
        else if (used_pct > 80.0)
            .high
        else if (used_pct > 65.0)
            .medium
        else
            .low;

        return types.MemoryMetrics{
            .total_bytes = total_phys,
            .used_bytes = used_phys,
            .available_bytes = avail_phys,
            .free_bytes = avail_phys,
            .cached_bytes = 0, // Windows doesn't expose cache bytes without performance counters
            .swap_total_bytes = total_page,
            .swap_used_bytes = used_page,
            .swap_free_bytes = avail_page,
            .used_percent = used_pct,
            .swap_used_percent = swap_pct,
            .pressure_level = pressure,
        };
    }

    // ═══════════════════════════════════════════════════════════════════
    // Disk Metrics — REAL partitions, real FS type via GetVolumeInformationW
    // ═══════════════════════════════════════════════════════════════════

    fn getDiskMetrics(_: *anyopaque, allocator: std.mem.Allocator) anyerror!types.DiskMetrics {
        var partitions: std.ArrayList(types.DiskPartition) = .empty;
        defer partitions.deinit(allocator);

        var drive_buf: [512]u16 = @splat(0);
        const len = GetLogicalDriveStringsW(512, &drive_buf);
        if (len > 0 and len < 512) {
            var i: usize = 0;
            while (i < len and drive_buf[i] != 0) {
                var drive_name: [4:0]u16 = [_:0]u16{ drive_buf[i], drive_buf[i + 1], drive_buf[i + 2], 0 };
                const drive_type = GetDriveTypeW(&drive_name);

                if (drive_type == 3 or drive_type == 2 or drive_type == 4) {
                    var free_caller: u64 = 0;
                    var total_bytes: u64 = 0;
                    var free_bytes: u64 = 0;

                    if (GetDiskFreeSpaceExW(&drive_name, &free_caller, &total_bytes, &free_bytes) != 0 and total_bytes > 0) {
                        var part = types.DiskPartition{
                            .total_bytes = total_bytes,
                            .free_bytes = free_bytes,
                            .used_bytes = total_bytes -| free_bytes,
                            .used_percent = @as(f32, @floatFromInt(total_bytes -| free_bytes)) * 100.0 / @as(f32, @floatFromInt(total_bytes)),
                        };

                        part.mount_point[0] = @as(u8, @intCast(drive_buf[i] & 0xFF));
                        part.mount_point[1] = @as(u8, @intCast(drive_buf[i + 1] & 0xFF));
                        part.mount_point[2] = @as(u8, @intCast(drive_buf[i + 2] & 0xFF));
                        part.mount_len = 3;

                        // Real filesystem type via GetVolumeInformationW
                        var fs_name_buf: [16]u16 = @splat(0);
                        if (GetVolumeInformationW(&drive_name, null, 0, null, null, null, &fs_name_buf, 16) != 0) {
                            var fs_u8: [32]u8 = @splat(0);
                            var fs_u16_len: usize = 0;
                            while (fs_u16_len < 16 and fs_name_buf[fs_u16_len] != 0) : (fs_u16_len += 1) {}
                            if (fs_u16_len > 0) {
                                if (std.unicode.utf16LeToUtf8(&fs_u8, fs_name_buf[0..fs_u16_len])) |converted| {
                                    @memcpy(part.fs_type[0..converted], fs_u8[0..converted]);
                                    part.fs_len = converted;
                                } else |_| {
                                    const fallback = "Unknown";
                                    @memcpy(part.fs_type[0..fallback.len], fallback);
                                    part.fs_len = fallback.len;
                                }
                            }
                        }

                        try partitions.append(allocator, part);
                    }
                }

                while (i < len and drive_buf[i] != 0) : (i += 1) {}
                i += 1;
            }
        }

        const part_slice = try partitions.toOwnedSlice(allocator);

        // No fake directory tree or I/O stats - return real partition data only
        return types.DiskMetrics{
            .partitions = part_slice,
            .top_directories = &[_]types.DirectoryNode{},
            .read_bytes_sec = 0,
            .write_bytes_sec = 0,
            .iops = 0,
        };
    }

    // ═══════════════════════════════════════════════════════════════════
    // Network Metrics — REAL (GetIfTable + GetExtendedTcpTable)
    // ═══════════════════════════════════════════════════════════════════

    fn getNetworkMetrics(ctx: *anyopaque, allocator: std.mem.Allocator) anyerror!types.NetworkMetrics {
        const self: *WindowsCollector = @ptrCast(@alignCast(ctx));

        var ifaces: std.ArrayList(types.NetworkInterface) = .empty;
        defer ifaces.deinit(allocator);

        var total_rx: u64 = 0;
        var total_tx: u64 = 0;

        const now_ns = std.time.nanoTimestamp();
        const elapsed_ns: u64 = if (self.net_prev_timestamp > 0)
            @intCast(@max(1, now_ns - self.net_prev_timestamp))
        else
            0;

        // Real interface metrics via GetIfTable
        var table_size: DWORD = 0;
        _ = GetIfTable(null, &table_size, 0);
        if (table_size > 0) {
            const table_buf = allocator.alloc(u8, table_size) catch null;
            if (table_buf) |buf| {
                defer allocator.free(buf);
                const table: *MIB_IFTABLE = @ptrCast(@alignCast(buf.ptr));
                if (GetIfTable(table, &table_size, 0) == 0) {
                    const entries: [*]MIB_IFROW = @ptrCast(&table.table);
                    var iface_idx: usize = 0;
                    for (0..table.dwNumEntries) |ei| {
                        const row = entries[ei];
                        // Skip loopback (type 24) and tunnel (type 131) interfaces
                        if (row.dwType == 24 or row.dwType == 131) continue;
                        // Only show operational interfaces
                        if (row.dwOperStatus != 1) continue; // MIB_IF_OPER_STATUS_OPERATIONAL = 1

                        var ni = types.NetworkInterface{
                            .is_up = true,
                            .total_rx_bytes = row.dwInOctets,
                            .total_tx_bytes = row.dwOutOctets,
                        };

                        // Interface description as name
                        const descr_len = @min(row.dwDescrLen, 63);
                        if (descr_len > 0) {
                            @memcpy(ni.name[0..descr_len], row.bDescr[0..descr_len]);
                            ni.name_len = descr_len;
                        }

                        // Compute bytes/sec from delta if we have previous data
                        if (elapsed_ns > 0 and iface_idx < self.if_state_count) {
                            const prev = &self.if_states[iface_idx];
                            if (prev.used and prev.index == row.dwIndex) {
                                // Handle 32-bit counter wrap
                                const rx_delta = if (row.dwInOctets >= @as(u32, @intCast(prev.prev_in & 0xFFFFFFFF)))
                                    @as(u64, row.dwInOctets) - (prev.prev_in & 0xFFFFFFFF)
                                else
                                    @as(u64, row.dwInOctets) + (0x100000000 - (prev.prev_in & 0xFFFFFFFF));

                                const tx_delta = if (row.dwOutOctets >= @as(u32, @intCast(prev.prev_out & 0xFFFFFFFF)))
                                    @as(u64, row.dwOutOctets) - (prev.prev_out & 0xFFFFFFFF)
                                else
                                    @as(u64, row.dwOutOctets) + (0x100000000 - (prev.prev_out & 0xFFFFFFFF));

                                ni.rx_bytes_sec = rx_delta * 1_000_000_000 / elapsed_ns;
                                ni.tx_bytes_sec = tx_delta * 1_000_000_000 / elapsed_ns;
                            }
                        }

                        // Store state for next delta
                        if (iface_idx < MAX_IFACES) {
                            self.if_states[iface_idx] = .{
                                .index = row.dwIndex,
                                .prev_in = row.dwInOctets,
                                .prev_out = row.dwOutOctets,
                                .used = true,
                            };
                        }

                        total_rx += ni.rx_bytes_sec;
                        total_tx += ni.tx_bytes_sec;

                        try ifaces.append(allocator, ni);
                        iface_idx += 1;
                        if (iface_idx >= MAX_IFACES) break;
                    }
                    self.if_state_count = iface_idx;
                }
            }
        }
        self.net_prev_timestamp = now_ns;

        // Real TCP connections via GetExtendedTcpTable
        var conns: std.ArrayList(types.NetworkConnection) = .empty;
        defer conns.deinit(allocator);

        var tcp_size: DWORD = 0;
        _ = GetExtendedTcpTable(null, &tcp_size, 0, AF_INET, TCP_TABLE_OWNER_PID_ALL, 0);
        if (tcp_size > 0) {
            const tcp_buf = allocator.alloc(u8, tcp_size) catch null;
            if (tcp_buf) |buf| {
                defer allocator.free(buf);
                if (GetExtendedTcpTable(buf.ptr, &tcp_size, 0, AF_INET, TCP_TABLE_OWNER_PID_ALL, 0) == 0) {
                    const table: *const MIB_TCPTABLE_OWNER_PID = @ptrCast(@alignCast(buf.ptr));
                    const rows: [*]const MIB_TCPROW_OWNER_PID = @ptrCast(&table.table);
                    const count = @min(table.dwNumEntries, 200); // Cap at 200 to avoid UI overflow
                    for (0..count) |ci| {
                        const row = rows[ci];
                        var conn = types.NetworkConnection{
                            .pid = row.dwOwningPid,
                            .proto_tcp = true,
                            .local_port = @byteSwap(@as(u16, @truncate(row.dwLocalPort))),
                            .remote_port = @byteSwap(@as(u16, @truncate(row.dwRemotePort))),
                            .state = mapTcpState(row.dwState),
                        };

                        // Format remote address
                        const ip = @as([4]u8, @bitCast(row.dwRemoteAddr));
                        var addr_buf: [16]u8 = undefined;
                        const addr_str = std.fmt.bufPrint(&addr_buf, "{d}.{d}.{d}.{d}", .{ ip[0], ip[1], ip[2], ip[3] }) catch "";
                        if (addr_str.len > 0) {
                            @memcpy(conn.remote_addr[0..addr_str.len], addr_str);
                            conn.remote_addr_len = addr_str.len;
                        }

                        try conns.append(allocator, conn);
                    }
                }
            }
        }

        const iface_slice = try ifaces.toOwnedSlice(allocator);
        const conn_slice = try conns.toOwnedSlice(allocator);

        return types.NetworkMetrics{
            .interfaces = iface_slice,
            .connections = conn_slice,
            .total_rx_sec = total_rx,
            .total_tx_sec = total_tx,
        };
    }

    fn mapTcpState(state: u32) types.ConnectionState {
        return switch (state) {
            1 => .closed,
            2 => .listen,
            3 => .syn_sent,
            4 => .syn_recv,
            5 => .established,
            6 => .fin_wait,
            7 => .fin_wait,
            8 => .close_wait,
            9 => .closed, // CLOSING
            10 => .closed, // LAST_ACK
            11 => .time_wait,
            12 => .closed, // DELETE_TCB
            else => .closed,
        };
    }

    // ═══════════════════════════════════════════════════════════════════
    // GPU Metrics — REAL name via EnumDisplayDevices, honest about limits
    // ═══════════════════════════════════════════════════════════════════

    fn getGpuMetrics(ctx: *anyopaque) types.GpuMetrics {
        const self: *WindowsCollector = @ptrCast(@alignCast(ctx));
        var gpu = types.GpuMetrics{};

        if (self.gpu_detected) {
            gpu.available = true;
            @memcpy(gpu.name[0..self.gpu_name_len], self.gpu_name[0..self.gpu_name_len]);
            gpu.name_len = self.gpu_name_len;
            // Note: Utilization, VRAM, and temperature require NVML/D3DKMT/PDH
            // which are not yet implemented. Showing 0 / N/A is honest.
        }

        return gpu;
    }

    // ═══════════════════════════════════════════════════════════════════
    // Battery Metrics — REAL (GetSystemPowerStatus)
    // ═══════════════════════════════════════════════════════════════════

    fn getBatteryMetrics(_: *anyopaque) types.BatteryMetrics {
        var status = SYSTEM_POWER_STATUS{};
        if (GetSystemPowerStatus(&status) != 0 and status.BatteryFlag != 128 and status.BatteryFlag != 255) {
            const is_charging = (status.ACLineStatus == 1) or ((status.BatteryFlag & 8) != 0);
            const pct = if (status.BatteryLifePercent <= 100) @as(f32, @floatFromInt(status.BatteryLifePercent)) else 100.0;
            const time_rem: ?u32 = if (status.BatteryLifeTime != std.math.maxInt(DWORD) and status.BatteryLifeTime > 0)
                status.BatteryLifeTime / 60
            else
                null;

            return types.BatteryMetrics{
                .available = true,
                .percentage = pct,
                .is_charging = is_charging,
                .time_remaining_mins = time_rem,
            };
        }

        return types.BatteryMetrics{
            .available = false,
        };
    }

    // ═══════════════════════════════════════════════════════════════════
    // Process List — REAL (CreateToolhelp32Snapshot + GetProcessTimes)
    // ═══════════════════════════════════════════════════════════════════

    fn getProcessList(ctx: *anyopaque, allocator: std.mem.Allocator) anyerror![]types.ProcessInfo {
        const self: *WindowsCollector = @ptrCast(@alignCast(ctx));
        var list: std.ArrayList(types.ProcessInfo) = .empty;
        defer list.deinit(allocator);

        const snap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
        if (snap == INVALID_HANDLE_VALUE) {
            return error.WindowsSnapshotFailed;
        }
        defer _ = CloseHandle(snap);

        const sys_delta = self.last_system_delta;

        var entry = PROCESSENTRY32W{};
        if (Process32FirstW(snap, &entry) != 0) {
            while (true) {
                var proc = types.ProcessInfo{
                    .pid = entry.th32ProcessID,
                    .ppid = entry.th32ParentProcessID,
                    .threads_count = entry.cntThreads,
                    .state = .running,
                };

                var name_len_u16: usize = 0;
                while (name_len_u16 < 260 and entry.szExeFile[name_len_u16] != 0) : (name_len_u16 += 1) {}
                if (std.unicode.utf16LeToUtf8(&proc.name, entry.szExeFile[0..name_len_u16])) |converted| {
                    proc.name_len = converted;
                } else |_| {
                    var utf8_len: usize = 0;
                    for (entry.szExeFile[0..name_len_u16]) |c| {
                        if (utf8_len >= proc.name.len) break;
                        proc.name[utf8_len] = @as(u8, @intCast(c & 0x7F));
                        utf8_len += 1;
                    }
                    proc.name_len = utf8_len;
                }

                if (proc.pid > 4) {
                    if (OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, 0, proc.pid)) |hProc| {
                        defer _ = CloseHandle(hProc);

                        var pmc = PROCESS_MEMORY_COUNTERS_EX{};
                        if (GetProcessMemoryInfo(hProc, &pmc, @sizeOf(PROCESS_MEMORY_COUNTERS_EX)) != 0) {
                            proc.memory_rss = pmc.WorkingSetSize;
                            proc.memory_vsize = pmc.PagefileUsage;
                        }

                        var create_ft: FILETIME = .{};
                        var exit_ft: FILETIME = .{};
                        var kern_ft: FILETIME = .{};
                        var usr_ft: FILETIME = .{};

                        if (GetProcessTimes(hProc, &create_ft, &exit_ft, &kern_ft, &usr_ft) != 0) {
                            const proc_total_time = kern_ft.toU64() + usr_ft.toU64();
                            const slot = @as(usize, proc.pid) % self.proc_times.len;
                            const prev = self.proc_times[slot];

                            if (prev.used and prev.pid == proc.pid) {
                                const delta_proc = proc_total_time -| prev.total_time;
                                if (sys_delta > 0) {
                                    const scaled_cpu = @as(f32, @floatFromInt(delta_proc)) * 100.0 * @as(f32, @floatFromInt(self.num_cores)) / @as(f32, @floatFromInt(sys_delta));
                                    proc.cpu_percent = std.math.clamp(scaled_cpu, 0.0, 100.0);
                                }
                            }

                            self.proc_times[slot] = .{
                                .pid = proc.pid,
                                .total_time = proc_total_time,
                                .used = true,
                            };
                        }
                    }
                }

                try list.append(allocator, proc);

                if (Process32NextW(snap, &entry) == 0) break;
            }
        }

        return try list.toOwnedSlice(allocator);
    }

    // ═══════════════════════════════════════════════════════════════════
    // Services — REAL (OpenSCManagerW + EnumServicesStatusExW)
    // ═══════════════════════════════════════════════════════════════════

    fn getServices(_: *anyopaque, allocator: std.mem.Allocator) anyerror![]types.SystemService {
        var services: std.ArrayList(types.SystemService) = .empty;
        defer services.deinit(allocator);

        const hSCM = OpenSCManagerW(null, null, SC_MANAGER_CONNECT | SC_MANAGER_ENUMERATE_SERVICE);
        if (hSCM == null) return try services.toOwnedSlice(allocator);
        defer _ = CloseServiceHandle(hSCM.?);

        // First call to get required buffer size
        var bytes_needed: u32 = 0;
        var services_returned: u32 = 0;
        var resume_handle: u32 = 0;
        _ = EnumServicesStatusExW(
            hSCM.?,
            SC_ENUM_PROCESS_INFO,
            SERVICE_WIN32,
            SERVICE_STATE_ALL,
            null,
            0,
            &bytes_needed,
            &services_returned,
            &resume_handle,
            null,
        );

        if (bytes_needed == 0) return try services.toOwnedSlice(allocator);

        // Allocate buffer and enumerate
        const buf = allocator.alloc(u8, bytes_needed) catch return try services.toOwnedSlice(allocator);
        defer allocator.free(buf);

        resume_handle = 0;
        if (EnumServicesStatusExW(
            hSCM.?,
            SC_ENUM_PROCESS_INFO,
            SERVICE_WIN32,
            SERVICE_STATE_ALL,
            buf.ptr,
            bytes_needed,
            &bytes_needed,
            &services_returned,
            &resume_handle,
            null,
        ) != 0) {
            const entries: [*]const ENUM_SERVICE_STATUS_PROCESSW = @ptrCast(@alignCast(buf.ptr));
            const max_services = @min(services_returned, 100); // Cap at 100 for UI
            for (0..max_services) |si| {
                const entry = entries[si];
                var srv = types.SystemService{
                    .status = mapServiceState(entry.ServiceStatusProcess.dwCurrentState),
                    .pid = entry.ServiceStatusProcess.dwProcessId,
                };

                // Convert service name from UTF-16
                const svc_name_ptr: [*:0]const u16 = entry.lpServiceName;
                var svc_name_len: usize = 0;
                while (svc_name_len < 63 and svc_name_ptr[svc_name_len] != 0) : (svc_name_len += 1) {}
                if (svc_name_len > 0) {
                    if (std.unicode.utf16LeToUtf8(&srv.name, svc_name_ptr[0..svc_name_len])) |converted| {
                        srv.name_len = converted;
                    } else |_| {}
                }

                // Convert display name from UTF-16
                const disp_name_ptr: [*:0]const u16 = entry.lpDisplayName;
                var disp_name_len: usize = 0;
                while (disp_name_len < 127 and disp_name_ptr[disp_name_len] != 0) : (disp_name_len += 1) {}
                if (disp_name_len > 0) {
                    if (std.unicode.utf16LeToUtf8(&srv.display_name, disp_name_ptr[0..disp_name_len])) |converted| {
                        srv.display_name_len = converted;
                    } else |_| {}
                }

                try services.append(allocator, srv);
            }
        }

        return try services.toOwnedSlice(allocator);
    }

    fn mapServiceState(state: u32) types.ServiceStatus {
        return switch (state) {
            1 => .stopped,
            2 => .start_pending,
            3 => .stop_pending,
            4 => .running,
            5 => .stopped, // CONTINUE_PENDING
            6 => .stop_pending, // PAUSE_PENDING
            7 => .paused,
            else => .unknown,
        };
    }

    // ═══════════════════════════════════════════════════════════════════
    // System Logs — Return empty (Event Log API is future work)
    // ═══════════════════════════════════════════════════════════════════

    fn getSystemLogs(_: *anyopaque, _: std.mem.Allocator) anyerror![]types.SystemLogEvent {
        // TODO: Implement real event log reading via wevtapi.dll (EvtQuery/EvtNext)
        // For now, return empty rather than fake data
        return &[_]types.SystemLogEvent{};
    }

    // ═══════════════════════════════════════════════════════════════════
    // Process Control — REAL
    // ═══════════════════════════════════════════════════════════════════

    fn killProcess(_: *anyopaque, pid: u32) anyerror!void {
        const handle = OpenProcess(PROCESS_TERMINATE, 0, pid) orelse return error.ProcessAccessDenied;
        defer _ = CloseHandle(handle);

        if (TerminateProcess(handle, 1) == 0) {
            return error.ProcessTerminationFailed;
        }
    }

    fn suspendProcess(_: *anyopaque, pid: u32) anyerror!void {
        const handle = OpenProcess(PROCESS_SUSPEND_RESUME, 0, pid) orelse return error.ProcessAccessDenied;
        defer _ = CloseHandle(handle);
        _ = NtSuspendProcess(handle);
    }

    fn resumeProcess(_: *anyopaque, pid: u32) anyerror!void {
        const handle = OpenProcess(PROCESS_SUSPEND_RESUME, 0, pid) orelse return error.ProcessAccessDenied;
        defer _ = CloseHandle(handle);
        _ = NtResumeProcess(handle);
    }
};

// ═══════════════════════════════════════════════════════════════════════════
// Admin Detection — REAL
// ═══════════════════════════════════════════════════════════════════════════

pub fn isUserAdmin() bool {
    var sid: std.os.windows.SID_IDENTIFIER_AUTHORITY = .{ .Value = .{ 0, 0, 0, 0, 0, 5 } };
    var group: std.os.windows.PSID = undefined;

    if (std.os.windows.advapi32.AllocateAndInitializeSid(
        &sid,
        2,
        32, // SECURITY_BUILTIN_DOMAIN_RID
        544, // DOMAIN_ALIAS_RID_ADMINS
        0,
        0,
        0,
        0,
        0,
        0,
        &group,
    ) != 0) {
        defer _ = std.os.windows.advapi32.FreeSid(group);
        var is_member: std.os.windows.BOOL = 0;
        if (std.os.windows.advapi32.CheckTokenMembership(null, group, &is_member) != 0) {
            return is_member != 0;
        }
    }
    return false;
}
