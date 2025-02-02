const std = @import("std");
const mem = std.mem;
const dbg = std.debug;
const assert = std.debug.assert;
const parser = @import("json-parser.zig");
const perf = @import("perf-metrics.zig");
const haversine = @import("haversine.zig");

const FunctionsMinMax = struct {
    sin: [2]f64,
    cos: [2]f64,
    asin: [2]f64,
    sqrt: [2]f64,
    pow: [2]f64,
};

fn setMinMax(value: f64, chk: *[2]f64) void {
    if (value < chk[0]) chk[0] = value;
    if (value > chk[1]) chk[1] = value;
}

fn referenceHaversine(lon1: f64, lat1: f64, lon2: f64, lat2: f64, checks: *FunctionsMinMax) f64 {
    const dlat = haversine.degreeToRadian(lat2 - lat1);
    const dlon = haversine.degreeToRadian(lon2 - lon1);
    const llat1 = haversine.degreeToRadian(lat1);
    const llat2 = haversine.degreeToRadian(lat2);

    setMinMax(dlat / 2.0, &checks.sin);
    setMinMax(llat1, &checks.cos);
    setMinMax(llat2, &checks.cos);
    setMinMax(dlon / 2.0, &checks.sin);

    const dlatSin = std.math.sin(dlat / 2.0);
    setMinMax(dlatSin, &checks.pow);

    const dlonSin = std.math.sin(dlon / 2.0);
    setMinMax(dlonSin, &checks.pow);

    const a: f64 = std.math.pow(f64, dlatSin, 2.0) + std.math.cos(llat1) * std.math.cos(llat2) * std.math.pow(f64, dlonSin, 2.0);

    setMinMax(a, &checks.sqrt);
    const asqrt = std.math.sqrt(a);

    setMinMax(asqrt, &checks.asin);
    const c: f64 = 2.0 * std.math.asin(asqrt);

    return c * haversine.EARTH_RADIUS;
}

pub fn runHaversine(baseAllocator: mem.Allocator, inputFilename: []u8) !void {
    var arena = std.heap.ArenaAllocator.init(baseAllocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const setup = try parser.setupHaversine(allocator, inputFilename);

    const fcount: f64 = @floatFromInt(setup.pointsCount);
    const coefficient: f64 = 1.0 / fcount;
    var total: f64 = 0;
    var checks = FunctionsMinMax{
        .cos = [2]f64{ std.math.floatMax(f64), std.math.floatMin(f64) },
        .asin = [2]f64{ std.math.floatMax(f64), std.math.floatMin(f64) },
        .sin = [2]f64{ std.math.floatMax(f64), std.math.floatMin(f64) },
        .sqrt = [2]f64{ std.math.floatMax(f64), std.math.floatMin(f64) },
        .pow = [2]f64{ std.math.floatMax(f64), std.math.floatMin(f64) },
    };

    for (setup.points, setup.answers) |p, a| {
        const hav = referenceHaversine(p.X0, p.Y0, p.X1, p.Y1, &checks);
        assert(std.math.approxEqAbs(f64, hav, a, 0.0001));

        total += hav * coefficient;
    }

    assert(std.math.approxEqAbs(f64, total, setup.answersSum, 0.0001));
    dbg.print("Cos: {d} :: {d}\n", .{ checks.cos[0], checks.cos[1] });
    dbg.print("Asin: {d} :: {d}\n", .{ checks.asin[0], checks.asin[1] });
    dbg.print("Sin: {d} :: {d}\n", .{ checks.sin[0], checks.sin[1] });
    dbg.print("Sqrt: {d} :: {d}\n", .{ checks.sqrt[0], checks.sqrt[1] });
    dbg.print("Pow: {d} :: {d}\n", .{ checks.pow[0], checks.pow[1] });
    // dbg.print("Min/Max values: {any}\n", .{checks});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input: []const u8 = "haversine";
    const fname_buffer = try allocator.alloc(u8, input.len);
    defer allocator.free(fname_buffer);

    std.mem.copyForwards(u8, fname_buffer, input);

    // Use the mutable buffer as `fname`
    const fname: []u8 = fname_buffer;

    try runHaversine(allocator, fname);
}
