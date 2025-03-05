const std = @import("std");
const math = std.math;

pub const RangeCheckInput = struct { step: f64, range: [2]f64, refFn: fn (f64) f64, checkFn: fn (f64) f64 };
pub const RangeCheckOutput = struct { maxDiff: f64 };

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
