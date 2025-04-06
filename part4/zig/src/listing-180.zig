const std = @import("std");
const math = std.math;
const dbg = std.debug;
const mymath = @import("my-math.zig");
const rt = @import("range-tester.zig");

pub fn factorial(x: u32) f64 {
    var res: f64 = @floatFromInt(x);
    var xx = res;
    while (xx > 1) {
        xx -= 1;
        res *= xx;
    }
    return res;
}

pub fn taylorSineCoefficient(power: u32) f64 {
    const sign: f64 = if (@mod((power - 1) / 2, 2) != 0) -1.0 else 1.0;
    // std.debug.print("taylorSineCoefficient => for power {d} sign {d}\n", .{ power, sign });
    return sign / factorial(power);
}

pub fn taylorSine(power: u32, x: f64) f64 {
    var res: f64 = 0;
    const x2 = x * x;
    var xPow = x;

    var p = @as(u32, 1);
    while (p <= power) : (p += 2) {
        // std.debug.print("For power: {d}, res: {d}, xPow: {d}, coeff: {d}\n", .{ p, res, xPow, taylorSineCoefficient(p) });
        res += xPow * taylorSineCoefficient(p);
        xPow *= x2;
    }

    return res;
}

pub fn main() !void {
    // const v: f64 = math.pi / @as(f64, 2.0);
    // const r = taylorSine(11, v);
    // std.debug.print(">>>>value: {d}, r: {d}, sine: {d}\n", .{ v, r, math.sin(v) });

    var tester = rt.PrecisionTester{};

    var p = @as(u32, 3);
    while (p <= 31) : (p += 2) {
        while (rt.rangePrecisionTest(&tester, 0, math.pi / @as(f64, 2))) {
            rt.checkPrecisionTest(&tester, math.sin(tester.inputValue), taylorSine(p, tester.inputValue));
        }

        dbg.print("Taylor sine for power: {d}, max diff: {d}\n", .{ p, tester.maxDiff });
    }
}
