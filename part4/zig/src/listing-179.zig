const std = @import("std");
const math = std.math;
const dbg = std.debug;
const mymath = @import("my-math.zig");
const rt = @import("range-tester.zig");

pub fn sinQuarter(x: f64) f64 {
    const halfPi = math.pi / 2.0;
    const absX = @abs(x);
    const quartX = if (absX > halfPi) math.pi - absX else absX;
    const quartX2 = mymath.square(quartX);

    const A = -0.3357488673628103541807525733876701910953780492546723687387637750157263772845455;
    const B = 1.164012859946630796034863328523423717191309716948615456152205566227330270901187;

    const xRes = A * quartX2 + B * quartX;

    return if (x < 0) -xRes else xRes;
}

pub fn cosQuarter(x: f64) f64 {
    return sinQuarter(x + math.pi / 2.0);
}

pub fn main() !void {
    const step = 0.0000001;

    dbg.print("Sin full: {d}\n", .{rt.rangeCheck(.{
        .step = step,
        .range = [2]f64{ -math.pi, math.pi },
        .checkFn = rt.sinRef,
        .refFn = mymath.sin,
    }).maxDiff});

    dbg.print("Sin quarter: {d}\n", .{rt.rangeCheck(.{
        .step = step,
        .range = [2]f64{ -math.pi, math.pi },
        .checkFn = rt.sinRef,
        .refFn = sinQuarter,
    }).maxDiff});

    dbg.print("Cos quarter: {d}\n", .{rt.rangeCheck(.{
        .step = step,
        .range = [2]f64{ -math.pi, math.pi },
        .checkFn = rt.cosRef,
        .refFn = cosQuarter,
    }).maxDiff});
}
