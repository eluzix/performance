const std = @import("std");
const debug = std.debug;
const perf = @import("perf-metrics.zig");

pub const TimePoint = struct {
    hitCount: u32,
    startTime: u64,
    totalTime: u64,
    childrenTime: u64,
    byteProcessed: u64,
    label: []const u8,

    fn new(label: []const u8) TimePoint {
        return TimePoint{
            .hitCount = 0,
            .startTime = perf.highResolutionClock(),
            .totalTime = 0,
            .childrenTime = 0,
            .byteProcessed = 0,
            .label = label,
        };
    }

    fn mark(self: *TimePoint, byteProcessed: u64) u64 {
        const t = perf.highResolutionClock() - self.startTime;
        self.totalTime += 1;
        self.hitCount += 1;
        self.byteProcessed += byteProcessed;
        return t;
    }

    fn restart(self: *TimePoint) void {
        self.startTime = perf.highResolutionClock();
    }
};

pub const Profiler = struct {
    startTime: u64,
    elapsedTime: u64,
    allocator: std.mem.Allocator,
    points: std.ArrayList(TimePoint),

    fn new(allocator: std.mem.Allocator) !Profiler {
        return Profiler{
            .startTime = 0,
            .elapsedTime = 0,
            .allocator = allocator,
            .points = try std.ArrayList(TimePoint).initCapacity(allocator, 1024),
        };
    }

    fn startProfile(self: *Profiler) void {
        self.startTime = perf.highResolutionClock();
    }

    fn endProfile(self: *Profiler) void {
        self.elapsedTime = perf.highResolutionClock() - self.startTime;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var profiler = try Profiler.new(allocator);
    profiler.startProfile();
    debug.print(">>>> profiler: {any}\n", .{profiler});

    var tp = TimePoint.new("test");
    debug.print(">>>> {any}\n", .{tp});
    _ = tp.mark(100);
    debug.print(">>>> {any}\n", .{tp});

    profiler.endProfile();
    debug.print(">>>> profiler: {any}\n", .{profiler.elapsedTime});
}
