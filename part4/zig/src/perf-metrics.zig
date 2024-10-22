const std = @import("std");

pub const TBInfo = struct { denom: u32, numer: u32 };

pub fn timeBaseInfo() TBInfo {
    var info: std.c.mach_timebase_info_data = undefined;
    const r = std.c.mach_timebase_info(&info);
    if (r != 0) @panic("mach_timebase_info failed");
    return TBInfo{
        .denom = info.denom,
        .numer = info.numer,
    };
}

pub fn highResolutionClock() u64 {
    const now = std.c.mach_absolute_time();
    const info = timeBaseInfo();
    return (now * info.numer) / info.denom;
}

pub fn getPageFaults() isize {
    const info: std.posix.rusage = std.posix.getrusage(0);
    return info.minflt + info.majflt;
}
