const std = @import("std");
const debug = std.debug;
const perf = @import("perf-metrics.zig");

const State = enum {
    unitialized,
    testing,
    completed,
    err,
};

pub const Metrics = enum {
    testCount,
    time,
    pageFaults,
    byteCount,
    gbPerSec,
    kbPerPgFault,

    count,
};

pub const ResultValue = struct {
    values: [@intFromEnum(Metrics.count)]u64,
    perCount: [@intFromEnum(Metrics.count)]f64,
};

pub const Results = struct {
    totals: ResultValue,
    min: ResultValue,
    max: ResultValue,
};

fn timeAsSeconds(time: f64) f64 {
    return time / @as(f64, @floatFromInt(std.time.ns_per_s));
}

fn timeFromSecs(seconds: u64) u64 {
    return seconds * std.time.ns_per_s;
}

fn computeDerivedValues(value: *ResultValue) void {
    const testCount: f64 = @floatFromInt(value.values[@intFromEnum(Metrics.testCount)]);

    for (0..@intFromEnum(Metrics.count)) |i| {
        value.perCount[i] = @as(f64, @floatFromInt(value.values[i])) / testCount;
    }

    const time = timeAsSeconds(value.perCount[@intFromEnum(Metrics.time)]);
    const bytes = value.perCount[@intFromEnum(Metrics.byteCount)];

    if (bytes > 0) {
        const GB: f64 = 1024.0 * 1024.0 * 1024.0;
        const gbProcessed = bytes / (GB * time);
        value.perCount[@intFromEnum(Metrics.gbPerSec)] = gbProcessed;
    }

    const pageFaults = value.perCount[@intFromEnum(Metrics.pageFaults)];
    if (pageFaults > 0) {
        value.perCount[@intFromEnum(Metrics.kbPerPgFault)] = bytes / pageFaults * 1024;
    }
}

const MAX_LABEL_SIZE = 64;

pub fn ReptitionTestSeries(comptime maxRows: usize, comptime columnCount: usize) type {
    const maxResultsSize = maxRows * columnCount;
    return struct {
        maxRowCount: usize,
        columnCount: usize,
        rowIndex: usize,
        columnIndex: usize,
        currentRun: usize,
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
                .currentRun = 0,
                .results = [_]Results{Results{
                    .totals = ResultValue{
                        .values = [_]u64{0} ** size,
                        .perCount = [_]f64{0} ** size,
                    },
                    .min = ResultValue{
                        .values = [_]u64{0} ** size,
                        .perCount = [_]f64{0} ** size,
                    },
                    .max = ResultValue{
                        .values = [_]u64{0} ** size,
                        .perCount = [_]f64{0} ** size,
                    },
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
                self.columnsLabel[self.columnIndex] = [_]u8{0} ** MAX_LABEL_SIZE;
                const copyLen = @min(label.len, MAX_LABEL_SIZE);
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

                self.currentRun += 1;
            }
            t.startNewWave(secondsToTry, expectedBytes);
        }
        pub fn isTesting(self: *Self, t: *Tester) bool {
            const res = t.isTesting();
            if (!res) {
                if (self.isInbound()) {
                    // todo get results...
                    self.results[self.rowIndex * self.columnCount + self.columnIndex] = t.results;
                    // debug.print("=>=>=>=> rowIndex: {d}, columnCount: {d}, columnIndex: {d}, LOC: {d}\n", .{ self.rowIndex, self.columnCount, self.columnIndex, self.rowIndex * self.columnCount + self.columnIndex });

                    self.columnIndex += 1;
                    if (self.columnIndex >= self.columnCount) {
                        self.columnIndex = 0;
                        self.rowIndex += 1;
                    }
                }
            }

            return res;
        }
        pub fn dumpCSV(self: *Self, metric: Metrics) void {
            for (0..self.columnCount) |c| {
                const r = self.columnsLabel[c];
                const rl = std.mem.indexOfScalar(u8, &r, 0).?;
                debug.print("{s},", .{r[0..rl]});
            }
            debug.print("\n", .{});

            for (0..self.rowIndex + 1) |i| {
                for (0..self.columnCount) |c| {
                    // debug.print("->->->-> rowIndex: {d}, columnCount: {d}, columnIndex: {d}, LOC: {d}\n", .{ i, self.columnCount, c, i * self.columnCount + c });
                    const r = self.results[i * self.columnCount + c];
                    debug.print("{d},", .{r.min.perCount[@intFromEnum(metric)]});
                }
                debug.print("\n", .{});
            }
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
                .totals = ResultValue{
                    .values = [_]u64{0} ** size,
                    .perCount = [_]f64{0} ** size,
                },
                .min = ResultValue{
                    .values = [_]u64{0} ** size,
                    .perCount = [_]f64{0} ** size,
                },
                .max = ResultValue{
                    .values = [_]u64{0} ** size,
                    .perCount = [_]f64{0} ** size,
                },
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
                    .totals = ResultValue{
                        .values = [_]u64{0} ** @intFromEnum(Metrics.count),
                        .perCount = [_]f64{0} ** @intFromEnum(Metrics.count),
                    },
                    .min = ResultValue{
                        .values = [_]u64{0} ** @intFromEnum(Metrics.count),
                        .perCount = [_]f64{0} ** @intFromEnum(Metrics.count),
                    },
                    .max = ResultValue{
                        .values = [_]u64{0} ** @intFromEnum(Metrics.count),
                        .perCount = [_]f64{0} ** @intFromEnum(Metrics.count),
                    },
                };

                const faults: u64 = @intCast(perf.getPageFaults());
                self.testMetrics[@intFromEnum(Metrics.pageFaults)] = faults - self.testMetrics[@intFromEnum(Metrics.pageFaults)];
            },
            State.completed => {
                self.state = State.testing;
            },
            State.testing => unreachable,
            State.err => unreachable,
        }

        self.startTime = perf.highResolutionClock();
        self.timeToWait = timeFromSecs(secondsToTry);
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
                    self.testMetrics[@intFromEnum(Metrics.testCount)] = 1;

                    for (0..@intFromEnum(Metrics.count)) |i| {
                        self.results.totals.values[i] += self.testMetrics[i];
                    }

                    if (self.results.max.values[@intFromEnum(Metrics.time)] < self.testMetrics[@intFromEnum(Metrics.time)]) {
                        self.results.max.values = self.testMetrics;
                    }

                    const rmin = self.results.min.values[@intFromEnum(Metrics.time)];
                    if (rmin == 0 or rmin > self.testMetrics[@intFromEnum(Metrics.time)]) {
                        self.results.min.values = self.testMetrics;
                        self.startTime = currentTime;
                        self.printTime("Min", self.results.min, true);
                    }
                }

                if (currentTime - self.startTime > self.timeToWait) {
                    self.state = State.completed;
                    computeDerivedValues(&self.results.totals);
                    computeDerivedValues(&self.results.min);
                    computeDerivedValues(&self.results.max);
                    self.printAllResults();
                }
            }

            return true;
        }

        return false;
    }

    fn printTime(self: *Tester, label: []const u8, value: ResultValue, carridgeReturn: bool) void {
        const time = value.values[@intFromEnum(Metrics.time)];
        var w: std.io.Writer = .fixed(&self.labelTimeBuffer);
        w.printDuration(time, .{}) catch unreachable;
        debug.print("{s}: {} ({s})", .{ label, time, w.buffered() });

        const bytes = value.perCount[@intFromEnum(Metrics.byteCount)];
        if (bytes > 0) {
            debug.print(" ({d:.10} GB/s)", .{value.perCount[@intFromEnum(Metrics.gbPerSec)]});
        }

        const pageFaults = value.perCount[@intFromEnum(Metrics.pageFaults)];
        if (pageFaults > 0) {
            debug.print(" (PF: {d:.4}, {d:.4}k/faults)", .{ pageFaults, value.perCount[@intFromEnum(Metrics.kbPerPgFault)] });
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

    var ts = ReptitionTestSeries(5, 2).new();
    ts.setRowLabel("row"[0..]);
    // std.debug.print(">>> {any} \n", .{ts});

    for (0..2) |i| {
        var buf: [64]u8 = [_]u8{0} ** 64;
        _ = try std.fmt.bufPrint(&buf, "column {d}", .{i});
        ts.setColumnLabel(buf[0..]);

        var t = Tester.new();
        // while (true) {
        // t.startNewWave(5, 10);
        ts.newTestWave(&t, 5, 10 * 1024 * 1024);

        while (ts.isTesting(&t)) {
            t.beginTime();
            try run(4096, 128);
            t.endTime();
            t.countBytes(10 * 1024 * 1024);
        }
    }
    ts.dumpCSV(Metrics.gbPerSec);
    // }
    // t.startNewWave(2, 10000);
    // t.beginTime();
    // debug.print("hello world >>> {any}\n", .{t});
    // t.endTime();
    // t.countBytes(10000);
    // debug.print("hello world >>> {any}\n", .{t});

}
