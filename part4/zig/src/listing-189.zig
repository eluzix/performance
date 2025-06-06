const std = @import("std");
const math = std.math;
const dbg = std.debug;
const mymath = @import("my-math.zig");
const rt = @import("range-tester.zig");
const arcsineCoef = @import("arcsine-coefficients.zig");

fn taylorArcSine(dim: usize, x: f64) f64 {
    var res: f64 = 0;
    const x2 = x * x;

    for (0..(dim + 1)) |i| {
        const pwr = dim - i;
        // std.debug.print("i: {d}, coeff: {d}\n", .{ pwr, sineCoeff.SineRadiansC_Taylor[pwr] });
        res = @mulAdd(f64, res, x2, arcsineCoef.Arcsine_Radians_Tylor[pwr]);
    }
    res *= x;

    return res;
}

fn mftwpArcSine(dim: usize, x: f64) f64 {
    var res: f64 = 0;
    const x2 = x * x;
    const ar = arcsineCoef.Arcsine_Radians_MFTWP[dim][0..dim];
    // const l = ar.len - 1;
    var i = ar.len - 1;
    while (i > 0) {
        res = @mulAdd(f64, res, x2, ar[i]);
        i -= 1;
    }
    res = @mulAdd(f64, res, x2, ar[0]);

    res *= x;

    return res;
}

// fn mftwpStaticCoeff(x: f64) f64 {
//     const x2 = x * x;
//     var res: f64 = 0.0;
//
//     res = @mulAdd(f64, res, x2, 0x1.883c1c5deffbep-49);
//     res = @mulAdd(f64, res, x2, -0x1.ae43dc9bf8ba7p-41);
//     res = @mulAdd(f64, res, x2, 0x1.6123ce513b09fp-33);
//     res = @mulAdd(f64, res, x2, -0x1.ae6454d960ac4p-26);
//     res = @mulAdd(f64, res, x2, 0x1.71de3a52aab96p-19);
//     res = @mulAdd(f64, res, x2, -0x1.a01a01a014eb6p-13);
//     res = @mulAdd(f64, res, x2, 0x1.11111111110c9p-7);
//     res = @mulAdd(f64, res, x2, -0x1.5555555555555p-3);
//     res = @mulAdd(f64, res, x2, 0x1p0);
//
//     res *= x;
//
//     return res;
// }

pub fn main() !void {
    // const v: f64 = math.pi / @as(f64, 4.0);
    // const r = taylorSineCoeff(12, v);
    // std.debug.print(">>>>value: {d}, r: {d}, sine: {d}\n", .{ v, r, math.sin(v) });

    const alloc = std.heap.page_allocator;
    var tester = rt.PrecisionTester.init(alloc);
    const _1OverSqrt2: f64 = 1.0 / mymath.sqrt(2);

    for (1..22) |p| {
        const idx1 = p + 2;
        const idx2 = p;

        // for (2..12) |p| {
        while (rt.rangePrecisionTest(&tester, 0, _1OverSqrt2)) {
            var label: [32]u8 = undefined;
            rt.checkPrecisionTest(&tester, math.asin(tester.inputValue), taylorArcSine(idx1, tester.inputValue), try std.fmt.bufPrint(&label, "taylorArcSine{d}", .{idx1}));
            rt.checkPrecisionTest(&tester, math.asin(tester.inputValue), mftwpArcSine(idx2, tester.inputValue), try std.fmt.bufPrint(&label, "mftwpArcSine{d}", .{idx2}));
        }
    }

    rt.printResults(&tester);
}
