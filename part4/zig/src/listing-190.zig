const std = @import("std");
const math = std.math;
const dbg = std.debug;
const mymath = @import("my-math.zig");
const rt = @import("range-tester.zig");
const arcsineCoef = @import("arcsine-coefficients.zig");

pub fn arcsine(x: f64) f64 {
    const x2 = x * x;
    const needsTransform = (x > 0.7071067811865475244);
    var X: f64 = undefined;
    if (needsTransform) {
        X = mymath.sqrt(1.0 - x2);
    } else {
        X = x;
    }

    var r: f64 = 0x1.dfc53682725cap-1;
    r = @mulAdd(f64, r, x2, -0x1.bec6daf74ed61p1);
    r = @mulAdd(f64, r, x2, 0x1.8bf4dadaf548cp2);
    r = @mulAdd(f64, r, x2, -0x1.b06f523e74f33p2);
    r = @mulAdd(f64, r, x2, 0x1.4537ddde2d76dp2);
    r = @mulAdd(f64, r, x2, -0x1.6067d334b4792p1);
    r = @mulAdd(f64, r, x2, 0x1.1fb54da575b22p0);
    r = @mulAdd(f64, r, x2, -0x1.57380bcd2890ep-2);
    r = @mulAdd(f64, r, x2, 0x1.69b370aad086ep-4);
    r = @mulAdd(f64, r, x2, -0x1.21438ccc95d62p-8);
    r = @mulAdd(f64, r, x2, 0x1.b8a33b8e380efp-7);
    r = @mulAdd(f64, r, x2, 0x1.c37061f4e5f55p-7);
    r = @mulAdd(f64, r, x2, 0x1.1c875d6c5323dp-6);
    r = @mulAdd(f64, r, x2, 0x1.6e88ce94d1149p-6);
    r = @mulAdd(f64, r, x2, 0x1.f1c73443a02f5p-6);
    r = @mulAdd(f64, r, x2, 0x1.6db6db3184756p-5);
    r = @mulAdd(f64, r, x2, 0x1.3333333380df2p-4);
    r = @mulAdd(f64, r, x2, 0x1.555555555531ep-3);
    r = @mulAdd(f64, r, x2, 0x1p0);
    r *= X;

    var result: f64 = undefined;
    if (needsTransform) {
        result = 1.57079632679489661923 - r;
    } else {
        result = r;
    }

    return result;
}

pub fn main() !void {
    const alloc = std.heap.page_allocator;
    var tester = rt.PrecisionTester.init(alloc);

    while (rt.rangePrecisionTest(&tester, 0, 1)) {
        var label: [7]u8 = undefined;
        rt.checkPrecisionTest(&tester, math.asin(tester.inputValue), arcsine(tester.inputValue), try std.fmt.bufPrint(&label, "arcsine", .{}));
    }

    rt.printResults(&tester);
}
