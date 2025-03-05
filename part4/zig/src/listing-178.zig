const std = @import("std");
const math = std.math;
const dbg = std.debug;
const mymath = @import("my-math.zig");
const rt = @import("range-tester.zig");

pub fn main() !void {
    const step = 0.0000001;

    dbg.print("Sin arc: {d}\n", .{rt.rangeCheck(.{
        .step = step,
        .range = [2]f64{ 0, math.pi },
        .checkFn = rt.sinRef,
        .refFn = mymath.sin,
    }).maxDiff});

    dbg.print("Sin full: {d}\n", .{rt.rangeCheck(.{
        .step = step,
        .range = [2]f64{ -math.pi, math.pi },
        .checkFn = rt.sinRef,
        .refFn = mymath.sin,
    }).maxDiff});
}
