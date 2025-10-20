const std = @import("std");
const debug = std.debug;
const perf = @import("perf-metrics.zig");

const State = enum {
    unitialized,
    testing,
    completed,
    err,
};

const Metrics = enum {
    testCount,
    time,
    pageFaults,
    byteCount,

    count,
};

pub const Results = struct {
    totals: [@intFromEnum(Metrics.count)]u64,
    min: [@intFromEnum(Metrics.count)]u64,
    max: [@intFromEnum(Metrics.count)]u64,
};

const MAX_LABEL_SIZE = 64;

pub fn ReptitionTestSeries(comptime maxRows: usize, comptime columnCount: usize) type {
    const maxResultsSize = maxRows * columnCount;
    return struct {
        maxRowCount: usize,
        columnCount: usize,
        rowIndex: usize,
        columnIndex: usize,
        rowLabels: [maxRows][MAX_LABEL_SIZE]u8, // Changed to array
        columnsLabel: [columnCount][MAX_LABEL_SIZE]u8, // Changed to array

        results: [maxResultsSize]Results,

        const Self = @This();

        pub fn new() Self {
            const size = @intFromEnum(Metrics.count);
            return Self{
                .maxRowCount = maxRows,
                .columnCount = columnCount,
                .rowIndex = 0,
                .columnIndex = 0,
                .results = [_]Results{Results{
                    .totals = [_]u64{0} ** size,
                    .min = [_]u64{0} ** size,
                    .max = [_]u64{0} ** size,
                }} ** maxResultsSize,
                .rowLabels = [_][MAX_LABEL_SIZE]u8{[_]u8{0} ** MAX_LABEL_SIZE} ** maxRows,
                .columnsLabel = [_][MAX_LABEL_SIZE]u8{[_]u8{0} ** MAX_LABEL_SIZE} ** columnCount,
            };
        }

        pub fn isInbound(self: *Self) bool {
            return (self.rowIndex < self.maxRowCount) and (self.columnIndex < self.columnCount);
        }

        pub fn setRowLabel(self: *Self, label: []const u8) void {
            if (self.isInbound()) {
                self.rowLabels[self.rowIndex] = [_]u8{0} ** MAX_LABEL_SIZE;
                const copyLen = @min(label.len, MAX_LABEL_SIZE);
                @memcpy(self.rowLabels[self.rowIndex][0..copyLen], label[0..copyLen]);
            }
        }

        pub fn setColumnLabel(self: *Self, label: []const u8) void {
            if (self.isInbound()) {
                self.columnsLabel[self.columnIndex] = [_]u8{0} ** 64;
                const copyLen = @min(label.len, 64);
                @memcpy(self.columnsLabel[self.columnIndex][0..copyLen], label[0..copyLen]);
            }
        }
        pub fn newTestWave(self: *Self, t: *Tester, secondsToTry: u64, expectedBytes: u64) void {
            if (self.isInbound()) {
                const c = self.columnsLabel[self.columnIndex];
                const cl = std.mem.indexOfScalar(u8, &c, 0).?;
                const r = self.rowLabels[self.rowIndex];
                const rl = std.mem.indexOfScalar(u8, &r, 0).?;
                std.debug.print("\n--- {s} {s} ---\n", .{ c[0..cl], r[0..rl] });
            }
            t.startNewWave(secondsToTry, expectedBytes);
        }
        pub fn isTesting(self: *Self, t: *Tester) bool {
            const res = t.isTesting();
            if (!res) {
                if (self.isInbound()) {
                    // todo get results...
                    self.results[self.rowIndex * self.columnCount + self.columnIndex] = t.results;
                    if (self.columnIndex >= self.columnCount) {
                        self.columnCount = 0;
                        self.rowIndex += 1;
                    }
                }
            }

            return res;
        }
    };
}

pub const Tester = struct {
    state: State,
    startTime: u64,
    timeToWait: u64,
    timeBaseInfo: perf.TBInfo,

    openBlocksCount: u32,
    closeBlockCount: u32,

    expectedBytes: u64,
    testMetrics: [@intFromEnum(Metrics.count)]u64,

    labelTimeBuffer: [64]u8,
    results: Results,

    pub fn new() Tester {
        const size = @intFromEnum(Metrics.count);
        return Tester{
            .state = State.unitialized,
            .startTime = 0,
            .timeToWait = 0,
            .timeBaseInfo = perf.timeBaseInfo(),
            .openBlocksCount = 0,
            .closeBlockCount = 0,
            .expectedBytes = 0,
            .testMetrics = [_]u64{0} ** size,
            .labelTimeBuffer = [_]u8{0} ** 64,
            .results = Results{
                .totals = [_]u64{0} ** size,
                .min = [_]u64{0} ** size,
                .max = [_]u64{0} ** size,
            },
        };
    }

    pub fn startNewWave(self: *Tester, secondsToTry: u64, expectedBytes: u64) void {
        // debug.print(">>>> secondsToTry: {d}\n", .{secondsToTry});
        switch (self.state) {
            State.unitialized => {
                self.state = State.testing;
                self.startTime = perf.highResolutionClock();
                self.openBlocksCount = 0;
                self.closeBlockCount = 0;
                self.expectedBytes = expectedBytes;
                self.results = Results{
                    .totals = [_]u64{0} ** @intFromEnum(Metrics.count),
                    .min = [_]u64{0} ** @intFromEnum(Metrics.count),
                    .max = [_]u64{0} ** @intFromEnum(Metrics.count),
                };

                const faults: u64 = @intCast(perf.getPageFaults());
                self.testMetrics[@intFromEnum(Metrics.pageFaults)] = faults - self.testMetrics[@intFromEnum(Metrics.pageFaults)];
            },
            State.completed => {
                self.state = State.testing;
                // self.testMetrics = [_]u64{0} ** @intFromEnum(Metrics.count);
            },
            State.testing => unreachable,
            State.err => unreachable,
        }

        self.startTime = perf.highResolutionClock();
        self.timeToWait = self.timeFromSecs(secondsToTry);
    }

    pub fn setError(self: *Tester, msg: []const u8) void {
        self.state = State.err;
        debug.print("{s}", .{msg});
    }

    pub fn beginTime(self: *Tester) void {
        self.openBlocksCount += 1;
        self.testMetrics[@intFromEnum(Metrics.time)] = perf.highResolutionClock();
        self.testMetrics[@intFromEnum(Metrics.pageFaults)] = @intCast(perf.getPageFaults());
        self.testMetrics[@intFromEnum(Metrics.byteCount)] = 0;
    }

    pub fn endTime(self: *Tester) void {
        self.closeBlockCount += 1;
        self.testMetrics[@intFromEnum(Metrics.time)] = perf.highResolutionClock() - self.testMetrics[@intFromEnum(Metrics.time)];
        const faults: u64 = @intCast(perf.getPageFaults());
        self.testMetrics[@intFromEnum(Metrics.pageFaults)] = faults - self.testMetrics[@intFromEnum(Metrics.pageFaults)];
    }

    pub fn countBytes(self: *Tester, bytes: u64) void {
        self.testMetrics[@intFromEnum(Metrics.byteCount)] += bytes;
    }

    pub fn isTesting(self: *Tester) bool {
        if (self.state == State.testing) {
            const currentTime = perf.highResolutionClock();
            if (self.openBlocksCount > 0) {
                if (self.openBlocksCount != self.closeBlockCount) {
                    self.setError("Open and close blocks count doesn't match\n");
                }

                if (self.testMetrics[@intFromEnum(Metrics.byteCount)] != self.expectedBytes) {
                    std.debug.print("expected: {d}, found: {d}\n", .{ self.expectedBytes, self.testMetrics[@intFromEnum(Metrics.byteCount)] });
                    self.setError("byteCount doesn't match\n");
                }

                if (self.state == State.testing) {
                    self.testMetrics[@intFromEnum(Metrics.testCount)] += 1;

                    for (0..@intFromEnum(Metrics.count)) |i| {
                        self.results.totals[i] += self.testMetrics[i];
                    }

                    if (self.results.max[@intFromEnum(Metrics.time)] < self.testMetrics[@intFromEnum(Metrics.time)]) {
                        self.results.max = self.testMetrics;
                    }

                    const rmin = self.results.min[@intFromEnum(Metrics.time)];
                    if (rmin == 0 or rmin > self.testMetrics[@intFromEnum(Metrics.time)]) {
                        self.results.min = self.testMetrics;
                        self.startTime = currentTime;
                        self.printTime("Min", self.results.min, true);
                    }
                }

                if (currentTime - self.startTime > self.timeToWait) {
                    self.state = State.completed;
                    self.printAllResults();
                }
            }

            return true;
        }

        return false;
    }
    fn timeFromSecs(self: *Tester, seconds: u64) u64 {
        return seconds * 10_000_000 * (self.timeBaseInfo.numer / self.timeBaseInfo.denom);
    }

    fn timeAsSeconds(self: *Tester, time: u64) u64 {
        return (time * self.timeBaseInfo.numer / self.timeBaseInfo.denom) / 1000;
        // return (time * self.timeBaseInfo.numer / self.timeBaseInfo.denom);
    }

    fn printTime(self: *Tester, label: []const u8, value: [@intFromEnum(Metrics.count)]u64, carridgeReturn: bool) void {
        const testCount = value[@intFromEnum(Metrics.testCount)];
        var localValues: [@intFromEnum(Metrics.count)]u64 = [_]u64{0} ** @intFromEnum(Metrics.count);

        for (0..@intFromEnum(Metrics.count)) |i| {
            localValues[i] = value[i] / testCount;
        }

        const time = localValues[@intFromEnum(Metrics.time)];
        var w: std.io.Writer = .fixed(&self.labelTimeBuffer);
        w.printDuration(time, .{}) catch unreachable;
        debug.print("{s}: {} ({s})", .{ label, time, w.buffered() });

        const bytes = localValues[@intFromEnum(Metrics.byteCount)];
        if (bytes > 0) {
            const fb: f64 = @floatFromInt(bytes);
            const gbProcessed = fb / (1024.0 * 1024.0 * 1024.0);
            const fpt: f64 = @floatFromInt(time);
            const bandwidth = gbProcessed / (fpt / 1000 / 1000 / 1000);
            debug.print(" ({d:.10} GB/s)", .{bandwidth});
        }

        const pageFaults = localValues[@intFromEnum(Metrics.pageFaults)];
        if (pageFaults > 0) {
            debug.print(" (PF: {d:.4}, {d:.4}k/faults)", .{ pageFaults, bytes / pageFaults * 1024 });
        }

        if (carridgeReturn) {
            debug.print("               \r", .{});
        } else {
            debug.print("\n", .{});
        }
    }

    pub fn printAllResults(self: *Tester) void {
        self.printTime("Min", self.results.min, false);
        self.printTime("Max", self.results.max, false);
        self.printTime("Avg.", self.results.totals, false);
    }
};

fn run(pageSize: usize, pageCount: usize) !void {
    // const pageSize = 4096 * 4;
    // const pageSize = 1024;
    // const pageCount = 128;
    const totalSize = pageSize * pageCount;

    const prot = std.posix.PROT.READ | std.posix.PROT.WRITE;

    for (0..pageCount) |touchCount| {
        const touchSize = pageSize * touchCount;
        const addr = try std.posix.mmap(null, totalSize, prot, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(addr);

        var ptr: [*]u8 = @ptrCast(addr);
        // const startFaults = perf.getPageFaults();
        for (0..touchSize) |i| {
            ptr[i] = @truncate(i);
        }
        // const endFaults = perf.getPageFaults();
        // _ = endFaults - startFaults;
        // const faultCount = endFaults - startFaults;
        // debug.print("{d}, {d}, {d}\n", .{ pageCount, touchCount, faultCount });
    }
}

pub fn main() !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // _ = gpa.allocator();

    var ts = ReptitionTestSeries(10, 10).new();
    ts.setRowLabel("hello world"[0..]);
    // std.debug.print(">>> {any} \n", .{ts});

    var t = Tester.new();
    while (true) {
        t.startNewWave(5, 0);

        while (t.isTesting()) {
            t.beginTime();
            try run(4096, 128);
            t.endTime();
            t.countBytes(0);
        }
    }
    // t.startNewWave(2, 10000);
    // t.beginTime();
    // debug.print("hello world >>> {any}\n", .{t});
    // t.endTime();
    // t.countBytes(10000);
    // debug.print("hello world >>> {any}\n", .{t});

}
