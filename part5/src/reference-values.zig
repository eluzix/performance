const std = @import("std");
const math = std.math;
const dbg = std.debug;
const rt = @import("range-tester.zig");
const mymath = @import("my-math.zig");

pub fn main() !void {
    // var prng = std.rand.DefaultPrng.init(blk: {
    //     var seed: u64 = undefined;
    //     try std.posix.getrandom(std.mem.asBytes(&seed));
    //     break :blk seed;
    // });
    // const rand: std.Random = prng.random();
    // const step: f64 = rand.float(f64) / @as(f64, 10000);

    // const r: [2]f64 = [2]f64{ -1.5707944268482854, 2.5707961323959962 };

    // const inp: Input = .{
    //     // .step = step,
    //     .step = 0.00001,
    //     .range = r,
    //     .checkFn = cosRef,
    //     .refFn = mymath.cos,
    // };

    const step = 0.0000001;
    dbg.print("Cos: {d}\n", .{rt.rangeCheck(.{
        .step = step,
        .range = [2]f64{ -1.5707944268482854, 2.5707961323959962 },
        .checkFn = rt.cosRef,
        .refFn = mymath.cos,
    }).maxDiff});

    dbg.print("Sin: {d}\n", .{rt.rangeCheck(.{
        .step = step,
        .range = [2]f64{ -3.1393153778507914, 3.1349791710994097 },
        .checkFn = rt.sinRef,
        .refFn = mymath.sin,
    }).maxDiff});

    dbg.print("Asin: {d}\n", .{rt.rangeCheck(.{
        .step = step,
        .range = [2]f64{ 0.0, 1.0 },
        .checkFn = rt.asinRef,
        .refFn = mymath.asin,
    }).maxDiff});

    dbg.print("Sqrt: {d}\n", .{rt.rangeCheck(.{
        .step = step,
        .range = [2]f64{ 0.0, 1.0 },
        .checkFn = rt.sqrtRef,
        .refFn = mymath.sqrt,
    }).maxDiff});
}
