const std = @import("std");

pub fn highResolutionClock() u64 {
    const now = std.c.mach_absolute_time();
    var info: std.c.mach_timebase_info_data = undefined;
    const r = std.c.mach_timebase_info(&info);
    if (r != 0) @panic("mach_timebase_info failed");
    return (now * info.numer) / info.denom;
}

pub fn getPageFaults() isize {
    const info: std.posix.rusage = std.posix.getrusage(0);
    return info.minflt + info.majflt;
}
