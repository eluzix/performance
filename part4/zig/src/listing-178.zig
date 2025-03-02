const std = @import("std");
const math = std.math;
const dbg = std.debug;
const mymath = @import("my-math.zig");
const rf = @import("reference-values.zig");

pub fn main() !void {
    const step = 0.0000001;

    dbg.print("Sin arc: {d}\n", .{rf.rangeCheck(.{
        .step = step,
        .range = [2]f64{ 0, math.pi },
        .checkFn = rf.sinRef,
        .refFn = mymath.sin,
    })});

    dbg.print("Sin full: {d}\n", .{rf.rangeCheck(.{
        .step = step,
        .range = [2]f64{ -math.pi, math.pi },
        .checkFn = rf.sinRef,
        .refFn = mymath.sin,
    })});
}
