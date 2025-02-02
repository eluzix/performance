const std = @import("std");
const math = std.math;
const dbg = std.debug;
const mymath = @import("my-math.zig");

fn rangeCos(step: f64) !void {
    const range: [2]f64 = [2]f64{ -1.5707944268482854, 1.5707961323959962 };
    var val = range[0];
    var largestDif: f64 = 0.0;

    while (val < range[1]) {
        const refVal = math.cos(val);
        const checkVal = mymath.cos(val);

        const diff = @abs(refVal - checkVal);
        if (diff > largestDif) {
            largestDif = diff;
        }

        val += step;
    }

    dbg.print("Cos largest diff: {d}\n", .{largestDif});
}

fn rangeSin(step: f64) !void {
    const range: [2]f64 = [2]f64{ -3.1393153778507914, 3.1349791710994097 };
    var val = range[0];
    var largestDif: f64 = 0.0;

    while (val < range[1]) {
        const refVal = math.sin(val);
        const checkVal = mymath.sin(val);

        const diff = @abs(refVal - checkVal);
        if (diff > largestDif) {
            largestDif = diff;
        }

        val += step;
    }

    dbg.print("Sin largest diff: {d}\n", .{largestDif});
}

fn rangeAsin(step: f64) !void {
    const range: [2]f64 = [2]f64{ 0.0004837476495959685, 0.999999854967022 };
    var val = range[0];
    var largestDif: f64 = 0.0;

    while (val < range[1]) {
        const refVal = math.asin(val);
        const checkVal = mymath.asin(val);

        const diff = @abs(refVal - checkVal);
        if (diff > largestDif) {
            largestDif = diff;
        }

        val += step;
    }

    dbg.print("Asin largest diff: {d}\n", .{largestDif});
}

fn rangeSqrt(step: f64) !void {
    const range: [2]f64 = [2]f64{ 0.0, 1.0 };
    var val = range[0];
    var largestDif: f64 = 0.0;

    while (val < range[1]) {
        const refVal = math.sqrt(val);
        const checkVal = mymath.sqrt(val);

        const diff = @abs(refVal - checkVal);
        if (diff > largestDif) {
            largestDif = diff;
        }

        val += step;
    }

    dbg.print("Sqrt largest diff: {d}\n", .{largestDif});
}

fn rangePow(step: f64) !void {
    const range: [2]f64 = [2]f64{ -1.0, 1.0 };
    var val = range[0];
    var largestDif: f64 = 0.0;

    while (val < range[1]) {
        const refVal = math.pow(f64, val, 2.0);
        const checkVal = mymath.pow(val, 2.0);

        const diff = @abs(refVal - checkVal);
        if (diff > largestDif) {
            largestDif = diff;
        }

        val += step;
    }

    dbg.print("Pow largest diff: {d}\n", .{largestDif});
}

pub fn main() !void {
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand: std.Random = prng.random();
    const step = rand.float(f64) / @as(f64, 10000);
    try rangeCos(step);
    try rangeSin(step);
    try rangeAsin(step);
    try rangeSqrt(step);
    try rangePow(step);
}
