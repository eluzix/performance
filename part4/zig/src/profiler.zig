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

    pub fn new(allocator: std.mem.Allocator) !Profiler {
        return Profiler{
            .startTime = 0,
            .elapsedTime = 0,
            .allocator = allocator,
            .points = try std.ArrayList(TimePoint).initCapacity(allocator, 1024),
        };
    }

    pub fn startProfile(self: *Profiler) void {
        self.startTime = perf.highResolutionClock();
    }

    pub fn endProfile(self: *Profiler) void {
        self.elapsedTime = perf.highResolutionClock() - self.startTime;
    }

    pub fn startSpan(self: *Profiler, label: []const u8) !usize {
        var idx: ?usize = null;
        for (self.points.items, 0..) |*p, i| {
            if (mem.eql(u8, p.label, label)) {
                idx = i;
                break;
            }
        }

        if (idx == null) {
            idx = self.points.items.len;
            try self.points.append(TimePoint.new(label));
        } else {
            const point = &self.points.items[idx.?];
            point.restart();
        }

        return idx.?;
    }

    pub fn stopSpan(self: *Profiler, idx: usize, byteProcessed: u64) void {
        var point = &self.points.items[idx];
        _ = point.mark(byteProcessed);
    }

    pub fn report(self: *Profiler) !void {
        const timeInfo = perf.timeBaseInfo();
        const totalTime = self.elapsedTime * timeInfo.numer / timeInfo.denom;
        const fTotalTime: f64 = @floatFromInt(totalTime);

        for (self.points.items) |point| {
            const pointElapsedTime = point.totalTime + point.childrenTime;
            const pointTime = pointElapsedTime * timeInfo.numer / timeInfo.denom;
            const fPointTime: f64 = @floatFromInt(pointTime);
            // const percent = (pointTime / totalTime) * 100;
            const percent = (fPointTime / fTotalTime) * 100.0;
            debug.print("{s}: {d} ({d} hits, {d:.2}%)", .{ point.label, pointElapsedTime, point.hitCount, percent });

            if (point.byteProcessed > 0) {
                const fb: f64 = @floatFromInt(point.byteProcessed);
                const mbProcessed = fb / 1024.0 / 1024.0;
                const gbProcessed = mbProcessed / 1024.0;
                const fpt: f64 = @floatFromInt(pointTime);
                const bandwidth = gbProcessed / (fpt / 1000 / 1000 / 1000 / 1000);
                debug.print(" {d:.4} MB, {d:.6} GB/s", .{ mbProcessed, bandwidth });
            }

            debug.print("\n", .{});
        }

        debug.print("Total time: {s}\n", .{std.fmt.fmtDuration(totalTime / 1000)});
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var profiler = try Profiler.new(allocator);
    profiler.startProfile();

    var idx = try profiler.startSpan("test");
    debug.print("IDX 1: {d}\n", .{idx});
    for (0..100000) |_| {
        var tp = TimePoint.new("inside....");
        _ = tp.mark(100);
    }
    profiler.stopSpan(idx, 1024000);

    idx = try profiler.startSpan("test");
    debug.print("IDX 2: {d}\n", .{idx});
    for (0..100000) |_| {
        var tp = TimePoint.new("inside....");
        _ = tp.mark(100);
    }
    profiler.stopSpan(idx, 8192000);

    idx = try profiler.startSpan("XXX");
    debug.print("IDX 3: {d}\n", .{idx});
    for (0..100000) |_| {
        var tp = TimePoint.new("inside....");
        _ = tp.mark(100);
    }
    profiler.stopSpan(idx, 8192000);

    profiler.endProfile();
    try profiler.report();
}
