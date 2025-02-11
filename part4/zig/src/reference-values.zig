const std = @import("std");
const math = std.math;
const dbg = std.debug;
const mymath = @import("my-math.zig");

const Input = struct { step: f64, range: [2]f64, refFn: fn (f64) f64, checkFn: fn (f64) f64 };

fn rangeCheck(inp: Input) f64 {
    var val = inp.range[0];
    var largestDif: f64 = 0.0;

    while (val < inp.range[1]) {
        const refVal = inp.refFn(val);
        const checkVal = inp.checkFn(val);
        // dbg.print("for {d}, ref: {d} and check: {d}\n", .{ val, refVal, checkVal });

        const diff = @abs(checkVal - refVal);
        if (diff > largestDif) {
            largestDif = diff;
        }

        val += inp.step;
    }

    return largestDif;
}

fn cosRef(val: f64) f64 {
    return math.cos(val);
}

fn sinRef(val: f64) f64 {
    return math.sin(val);
}

fn asinRef(val: f64) f64 {
    return math.asin(val);
}

fn sqrtRef(val: f64) f64 {
    return math.sqrt(val);
}

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
    dbg.print("Cos: {d}\n", .{rangeCheck(.{
        .step = step,
        .range = [2]f64{ -1.5707944268482854, 2.5707961323959962 },
        .checkFn = cosRef,
        .refFn = mymath.cos,
    })});

    dbg.print("Sin: {d}\n", .{rangeCheck(.{
        .step = step,
        .range = [2]f64{ -3.1393153778507914, 3.1349791710994097 },
        .checkFn = sinRef,
        .refFn = mymath.sin,
    })});

    dbg.print("Asin: {d}\n", .{rangeCheck(.{
        .step = step,
        .range = [2]f64{ 0.0, 1.0 },
        .checkFn = asinRef,
        .refFn = mymath.asin,
    })});

    dbg.print("Sqrt: {d}\n", .{rangeCheck(.{
        .step = step,
        .range = [2]f64{ 0.0, 1.0 },
        .checkFn = sqrtRef,
        .refFn = mymath.sqrt,
    })});
}
