const std = @import("std");
const mem = std.mem;
const io = std.io;
const debug = std.debug;
const perf = @import("perf-metrics.zig");

pub const TimePoint = struct {
    hitCount: u32,
    startTime: u64,
    totalTime: u64,
    childrenTime: u64,
    byteProcessed: u64,
    parentIdx: ?usize,
    label: []const u8,

    fn new(label: []const u8) TimePoint {
        return TimePoint{
            .hitCount = 0,
            .startTime = perf.highResolutionClock(),
            .totalTime = 0,
            .childrenTime = 0,
            .byteProcessed = 0,
            .parentIdx = null,
            .label = label,
        };
    }

    fn mark(self: *TimePoint, byteProcessed: u64) u64 {
        const t = perf.highResolutionClock() - self.startTime;
        self.totalTime += t;
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
    stack: std.ArrayList(usize),
    labelTimeBuffer: [64]u8,

    pub fn new(allocator: std.mem.Allocator) !Profiler {
        return Profiler{
            .startTime = 0,
            .elapsedTime = 0,
            .allocator = allocator,
            .points = try std.ArrayList(TimePoint).initCapacity(allocator, 4096),
            .stack = try std.ArrayList(usize).initCapacity(allocator, 64),
            .labelTimeBuffer = [_]u8{0} ** 64,
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
            var tp = TimePoint.new(label);

            if (self.stack.items.len > 0) {
                const parentIdx = self.stack.getLast();
                // const parent = &self.points.items[parentIdx];
                // debug.print("For {s} {d} ADDING parent: {s} {d} total: {d}\n", .{ label, idx.?, parent.label, parentIdx, self.stack.items.len });
                tp.parentIdx = parentIdx;
            }

            try self.points.append(self.allocator, tp);
        } else {
            const point = &self.points.items[idx.?];
            point.restart();
        }

        if (self.stack.items.len == 0) {
            try self.stack.append(self.allocator, idx.?);
        } else {
            const lastRootIdx = self.stack.getLast();
            if (lastRootIdx != idx.?) {
                try self.stack.append(self.allocator, idx.?);
            }
        }

        return idx.?;
    }

    pub fn stopSpan(self: *Profiler, idx: usize, byteProcessed: u64) void {
        var point = &self.points.items[idx];
        const elapsed = point.mark(byteProcessed);

        if (point.parentIdx != null) {
            const parent = &self.points.items[point.parentIdx.?];
            parent.childrenTime += elapsed;

            const lastRootIdx = self.stack.getLast();
            if (lastRootIdx == idx) {
                _ = self.stack.pop();
            }
        }

        if (self.stack.items.len > 0) {
            const lastRootIdx = self.stack.getLast();
            if (lastRootIdx == idx) {
                _ = self.stack.pop();
            }
        }
    }

    pub fn report(self: *Profiler) !void {
        const timeInfo = perf.timeBaseInfo();
        const totalTime = self.elapsedTime * timeInfo.numer / timeInfo.denom;
        const fTotalTime: f64 = @floatFromInt(totalTime);

        for (self.points.items) |point| {
            const pointElapsedTime = point.totalTime - point.childrenTime;
            const pointTime = pointElapsedTime * timeInfo.numer / timeInfo.denom;
            const fPointTime: f64 = @floatFromInt(pointTime);
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

        var w: io.Writer = .fixed(&self.labelTimeBuffer);
        w.printDuration(totalTime, .{}) catch unreachable;

        debug.print("Total time: {s}\n", .{w.buffered()});
    }
};

pub fn main() !void {
    // var gpa = std.heap.DebugAllocator(.{}){};
    var b: [1024 * 1024]u8 = undefined;
    var gpa = std.heap.FixedBufferAllocator.init(&b);
    const allocator = gpa.allocator();

    var profiler = try Profiler.new(allocator);

    for (0..10) |_| {
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
}
