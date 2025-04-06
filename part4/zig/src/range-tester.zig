const std = @import("std");
const math = std.math;

pub const RangeCheckInput = struct { step: f64, range: [2]f64, refFn: fn (f64) f64, checkFn: fn (f64) f64 };
pub const RangeCheckOutput = struct { maxDiff: f64 };

pub const PrecisionTester = struct {
    testing: bool = false,
    inputValue: f64 = 0.0,

    maxDiff: f64 = 0.0,
    testedValueAtMaxDiff: f64 = 0.0,
    expectedValueAtMaxDiff: f64 = 0.0,
    inputValueAtMaxDiff: f64 = 0.0,

    step: f64 = 0.0,
    stepIndex: u32 = 0,
    stepCount: u32 = 100000000,
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
    if (tester.testing) {
        tester.stepIndex += 1;
    } else {
        tester.testing = true;
        tester.stepIndex = 0;
        tester.maxDiff = -100000000;
        tester.testedValueAtMaxDiff = min;
        tester.expectedValueAtMaxDiff = min;
        tester.inputValueAtMaxDiff = min;
    }

    if (tester.stepIndex < tester.stepCount) {
        const si: f64 = @floatFromInt(tester.stepIndex);
        const sc: f64 = @floatFromInt(tester.stepCount - 1);
        const step: f64 = si / sc;
        tester.inputValue = (1.0 - step) * min + step * max;
    } else {
        tester.testing = false;
    }

    return tester.testing;
}

pub fn checkPrecisionTest(tester: *PrecisionTester, expected: f64, tested: f64) void {
    const diff = @abs(expected - tested);
    if (diff > tester.maxDiff) {
        // std.debug.print("checkPrecisionTest expected: {d}, tested: {d} --- diff: {d}\n", .{ expected, tested, diff });
        tester.maxDiff = diff;
        tester.expectedValueAtMaxDiff = expected;
        tester.testedValueAtMaxDiff = tested;
        tester.inputValueAtMaxDiff = tester.inputValue;
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
