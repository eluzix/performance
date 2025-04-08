const std = @import("std");
const math = std.math;

const MAX_RESULTS: u32 = 255;

pub const RangeCheckInput = struct { step: f64, range: [2]f64, refFn: fn (f64) f64, checkFn: fn (f64) f64 };
pub const RangeCheckOutput = struct { maxDiff: f64 };

pub const PrecisionTesterResult = struct { label: [128]u8, maxDiff: f64 = 0.0, testedValueAtMaxDiff: f64 = 0.0, expectedValueAtMaxDiff: f64 = 0.0, inputValueAtMaxDiff: f64 = 0.0, totalDiff: f64 = 0.0 };

pub const PrecisionTester = struct {
    // results: std.ArrayList(PrecisionTesterResult),
    results: [MAX_RESULTS]PrecisionTesterResult = undefined,
    testing: bool = false,
    inputValue: f64 = 0.0,

    resultIndex: u32 = 0,
    resultOffset: u32 = 0,
    resultCount: u32 = 0,

    step: f64 = 0.0,
    stepIndex: u32 = 0,
    stepCount: u32 = 10000000,

    pub fn init(_: std.mem.Allocator) PrecisionTester {
        // const p = PrecisionTester{ .results = std.ArrayList(PrecisionTesterResult).init(alloc) };
        const p = PrecisionTester{
            .results = [_]PrecisionTesterResult{.{ .label = undefined }} ** 255,
        };
        return p;
    }
};

pub fn rangeCheck(inp: RangeCheckInput) RangeCheckOutput {
    var val = inp.range[0];
    var largestDif: f64 = 0.0;

    while (val < inp.range[1]) {
        const refVal = inp.refFn(val);
        const checkVal = inp.checkFn(val);

        const diff = @abs(checkVal - refVal);
        if (diff > largestDif) {
            largestDif = diff;
        }

        val += inp.step;
    }

    return RangeCheckOutput{
        .maxDiff = largestDif,
    };
}

pub fn rangePrecisionTest(tester: *PrecisionTester, min: f64, max: f64) bool {
    const origIndex = tester.resultIndex;
    if (tester.testing) {
        tester.stepIndex += 1;
        tester.resultIndex = 0;
    } else {
        tester.testing = true;
        tester.stepIndex = 0;
    }

    if (tester.stepIndex < tester.stepCount) {
        const si: f64 = @floatFromInt(tester.stepIndex);
        const sc: f64 = @floatFromInt(tester.stepCount - 1);
        const step: f64 = si / sc;
        tester.inputValue = (1.0 - step) * min + step * max;
    } else {
        tester.testing = false;
        tester.resultOffset += origIndex;
        tester.resultCount = origIndex;
        printIntermediateResults(tester);
    }

    return tester.testing;
}

pub fn checkPrecisionTest(tester: *PrecisionTester, expected: f64, tested: f64, label: []u8) void {
    const idx = tester.resultOffset + tester.resultIndex;
    var result = &tester.results[idx];

    tester.resultIndex += 1;
    tester.resultCount += 1;

    if (tester.stepIndex == 0) {
        std.mem.copyForwards(u8, result.label[0..label.len], label);
    }

    const diff = @abs(expected - tested);
    if (diff > result.maxDiff) {
        result.maxDiff = diff;
        result.expectedValueAtMaxDiff = expected;
        result.testedValueAtMaxDiff = tested;
        result.inputValueAtMaxDiff = tester.inputValue;
    }
    result.totalDiff += diff;
}

pub fn printIntermediateResults(tester: *PrecisionTester) void {
    const idx = tester.resultOffset - tester.resultCount;
    for (tester.results[idx..]) |result| {
        if (result.maxDiff != 0.0) {
            std.debug.print("{s}, max diff: {d}\n", .{ result.label, result.maxDiff });
        }
    }
    std.debug.print("--------------------\n", .{});
}

fn resultsLessThan(tester: *PrecisionTester, lhs: usize, rhs: usize) bool {
    return tester.results[lhs].maxDiff < tester.results[rhs].maxDiff;
}

pub fn printResults(tester: *PrecisionTester) void {
    const total = tester.resultOffset;
    var indexes: [MAX_RESULTS]usize = undefined;
    for (0..total) |i| {
        indexes[i] = i;
        // std.debug.print(">>>>>>>>> {d}: {s}\n", .{ i, tester.results[i].label });
    }

    std.mem.sort(usize, indexes[0..total], tester, resultsLessThan);

    var i: usize = 0;
    while (i < total) {
        const result = tester.results[indexes[i]];
        std.debug.print("{d} [{s}", .{ result.maxDiff, result.label });
        while (i + 1 < total) {
            const nextResult = tester.results[indexes[i + 1]];
            if (nextResult.maxDiff == result.maxDiff) {
                std.debug.print(", {s}", .{nextResult.label});
                i += 1;
            } else {
                break;
            }
        }

        std.debug.print("]\n", .{});
        i += 1;
    }
}

pub fn cosRef(val: f64) f64 {
    return math.cos(val);
}

pub fn sinRef(val: f64) f64 {
    return math.sin(val);
}

pub fn asinRef(val: f64) f64 {
    return math.asin(val);
}

pub fn sqrtRef(val: f64) f64 {
    return math.sqrt(val);
}
