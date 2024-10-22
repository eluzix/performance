const std = @import("std");
const mem = std.mem;
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
        self.totalTime += t;
        self.hitCount += 1;
        self.byteProcessed += byteProcessed;
        // debug.print("point.mark {s}: {d}, hits: {d}\n", .{ self.label, t, self.hitCount });
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

    fn startSpan(self: *Profiler, label: []const u8) !usize {
        var point: ?TimePoint = null;
        var idx: usize = 0;
        for (self.points.items, 0..) |p, i| {
            if (mem.eql(u8, p.label, label)) {
                point = p;
                idx = i;
                break;
            }
        }

        if (point == null) {
            point = TimePoint.new(label);
            debug.print("START {s} {*}\n", .{ label, &point });
            try self.points.append(point.?);
        } else {
            point.?.restart();
        }

        return idx;
    }

    fn stopSpan(self: *Profiler, idx: usize, byteProcessed: u64) void {
        debug.print("END {d} -- {d}\n", .{ idx, byteProcessed });
        var point = self.points.items[idx];
        debug.print("END {s} {*}\n", .{ point.label, &point });
        _ = point.mark(byteProcessed);
    }

    fn report(self: *Profiler) !void {
        const timeInfo = perf.timeBaseInfo();
        const totalTime = self.elapsedTime * timeInfo.numer / timeInfo.denom;

        for (self.points.items) |point| {
            const pointTotalTime = point.totalTime + point.childrenTime;
            const percent = pointTotalTime / totalTime * 100;
            debug.print("{s} ({*}): {d} ({d} hits, {d})\n", .{ point.label, &point, pointTotalTime, point.hitCount, percent });
        }

        debug.print("Total time: {s}\n", .{std.fmt.fmtDuration(totalTime)});
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var profiler = try Profiler.new(allocator);
    profiler.startProfile();
    const idx = try profiler.startSpan("test");

    for (0..100000) |_| {
        var tp = TimePoint.new("inside....");
        _ = tp.mark(100);
    }
    profiler.stopSpan(idx, 1024);

    profiler.endProfile();
    try profiler.report();
}
