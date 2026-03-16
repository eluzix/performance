const std = @import("std");
const mem = std.mem;
const dbg = std.debug;
const repetitionTester = @import("repetition-tester.zig");

fn fmaDepChain(chainCount: u32, chainLength: u32) void {
    for (0..chainCount) |_| {
        const X2: f64 = 0;
        const M: f64 = 0;
        var R0: f64 = 0;

        mem.doNotOptimizeAway(X2);
        mem.doNotOptimizeAway(M);
        mem.doNotOptimizeAway(R0);

        var lenIdx: u32 = 0;
        while (lenIdx < chainLength) {
            lenIdx += 8;

            R0 = @mulAdd(f64, R0, X2, M);
            R0 = @mulAdd(f64, R0, X2, M);
            R0 = @mulAdd(f64, R0, X2, M);
            R0 = @mulAdd(f64, R0, X2, M);
            R0 = @mulAdd(f64, R0, X2, M);
            R0 = @mulAdd(f64, R0, X2, M);
            R0 = @mulAdd(f64, R0, X2, M);
            R0 = @mulAdd(f64, R0, X2, M);
        }

        mem.doNotOptimizeAway(R0);
    }
}

fn fmaDepChainMy(chainCount: u32, chainLength: u32) void {
    for (0..chainCount) |_| {
        const X2: f64 = 0;
        const M: f64 = 0;
        var R0: f64 = 0;

        mem.doNotOptimizeAway(X2);
        mem.doNotOptimizeAway(M);
        mem.doNotOptimizeAway(R0);

        var lenIdx: u32 = 0;
        while (lenIdx < chainLength) {
            lenIdx += 8;

            for (0..8) |_| {
                R0 = @mulAdd(f64, R0, X2, M);
            }
        }

        mem.doNotOptimizeAway(R0);
    }
}

pub fn main() !void {
    fmaDepChain(2, 8);

    var testSeries = repetitionTester.ReptitionTestSeries(1024, 2).new();
    testSeries.setRowLabel(""[0..]);

    var chainLen: u32 = 8;

    while (chainLen <= 256) {
        const repCount: u32 = 1024 * 1024;
        const chainCount: u32 = repCount / chainLen;

        var buf: [64]u8 = [_]u8{0} ** 64;
        _ = try std.fmt.bufPrint(&buf, "{d}", .{chainLen});
        testSeries.setRowLabel(buf[0..]);

        testSeries.setColumnLabel("original");
        var tester = repetitionTester.Tester.new();
        testSeries.newTestWave(&tester, 3, repCount);
        while (testSeries.isTesting(&tester)) {
            tester.beginTime();
            std.mem.doNotOptimizeAway(fmaDepChain(chainCount, chainLen));
            tester.endTime();
            tester.countBytes(repCount);
        }

        testSeries.setColumnLabel("my");
        tester = repetitionTester.Tester.new();
        testSeries.newTestWave(&tester, 3, repCount);
        while (testSeries.isTesting(&tester)) {
            tester.beginTime();
            std.mem.doNotOptimizeAway(fmaDepChainMy(chainCount, chainLen));
            tester.endTime();
            tester.countBytes(repCount);
        }

        chainLen += 8;
    }
    testSeries.dumpCSV(repetitionTester.Metrics.gbPerSec);
}
