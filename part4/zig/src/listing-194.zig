const std = @import("std");
const mem = std.mem;
const dbg = std.debug;
const assert = std.debug.assert;
const parser = @import("json-parser.zig");
const perf = @import("perf-metrics.zig");
const repetitionTester = @import("repetition-tester.zig");
const mymath = @import("my-math.zig");
const math = std.math;

pub const EARTH_RADIUS: f64 = 6372.8;

pub fn degreeToRadian(degree: f64) f64 {
    return degree * 0.01745329251994329577;
}

const HaversineChecker = struct {
    name: []const u8,
    func: *const fn (*parser.HaversineSetup) error{}!void,
    tester: repetitionTester.Tester,
};

fn checkHaversineBase(setup: *parser.HaversineSetup) error{}!void {
    const fcount: f64 = @floatFromInt(setup.pointsCount);
    const coefficient: f64 = 1.0 / fcount;
    var total: f64 = 0;
    const RAD = 0.01745329251994329577;

    for (setup.points, setup.answers) |p, ans| {
        const dlat = RAD * (p.Y1 - p.Y0);
        const dlon = RAD * (p.X1 - p.X0);
        const llat1 = RAD * p.Y0;
        const llat2 = RAD * p.Y1;

        const a: f64 = mymath.square(mymath.sin(dlat / 2.0)) + mymath.cos(llat1) * mymath.cos(llat2) * mymath.square(mymath.sin(dlon / 2.0));

        const c: f64 = 2.0 * mymath.asine(mymath.sqrt(a));

        const hav = c * EARTH_RADIUS;
        assert(std.math.approxEqAbs(f64, hav, ans, 0.000001));

        total += hav * coefficient;
    }

    assert(std.math.approxEqAbs(f64, total, setup.answersSum, 0.000001));
    setup.valid = true;
}

fn checkHaversineV1(setup: *parser.HaversineSetup) error{}!void {
    const fcount: f64 = @floatFromInt(setup.pointsCount);
    const coefficient: f64 = 1.0 / fcount;
    var total: f64 = 0;

    for (setup.points, setup.answers) |p, ans| {
        const dlat = degreeToRadian(p.Y1 - p.Y0);
        const dlon = degreeToRadian(p.X1 - p.X0);
        const llat1 = degreeToRadian(p.Y0);
        const llat2 = degreeToRadian(p.Y1);

        const a: f64 = std.math.pow(f64, (std.math.sin(dlat / 2.0)), 2.0) + std.math.cos(llat1) * std.math.cos(llat2) * std.math.pow(f64, (std.math.sin(dlon / 2.0)), 2.0);

        const c: f64 = 2.0 * std.math.asin(std.math.sqrt(a));

        const hav = c * EARTH_RADIUS;
        assert(std.math.approxEqAbs(f64, hav, ans, 0.000001));

        total += hav * coefficient;
    }

    assert(std.math.approxEqAbs(f64, total, setup.answersSum, 0.000001));
    setup.valid = true;
}

pub fn runHaversine(baseAllocator: mem.Allocator, inputFilename: []u8) !void {
    var arena = std.heap.ArenaAllocator.init(baseAllocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var setup = try parser.setupHaversine(allocator, inputFilename);

    const functions = [_]HaversineChecker{ HaversineChecker{
        .name = "Base",
        .func = checkHaversineBase,
        .tester = repetitionTester.Tester.new(),
    }, HaversineChecker{
        .name = "V1",
        .func = checkHaversineV1,
        .tester = repetitionTester.Tester.new(),
    } };

    var testSeries = repetitionTester.ReptitionTestSeries(1, functions.len).new();
    testSeries.setRowLabel("haversine"[0..]);

    for (functions) |hc| {
        testSeries.setColumnLabel(hc.name);

        var tester = hc.tester;
        testSeries.newTestWave(&tester, 5, setup.totalBytes);
        while (testSeries.isTesting(&tester)) {
            tester.beginTime();
            try hc.func(&setup);
            tester.endTime();
            tester.countBytes(setup.totalBytes);
        }
    }

    std.debug.print("?>>>>>>> {any}\n", .{testSeries.results});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    try runHaversine(allocator, args[1]);
}
