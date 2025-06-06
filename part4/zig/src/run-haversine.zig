const std = @import("std");
const mem = std.mem;
const dbg = std.debug;
const assert = std.debug.assert;
const parser = @import("json-parser.zig");
const perf = @import("perf-metrics.zig");
const haversine = @import("haversine.zig");
const repetitionTester = @import("repetition-tester.zig");

const HaversineChecker = struct {
    name: []const u8,
    func: *const fn (*parser.HaversineSetup) error{}!void,
};

fn checkHaversine(setup: *parser.HaversineSetup) error{}!void {
    const fcount: f64 = @floatFromInt(setup.pointsCount);
    const coefficient: f64 = 1.0 / fcount;
    var total: f64 = 0;

    for (setup.points, setup.answers) |p, a| {
        const hav = haversine.referenceHaversine(p.X0, p.Y0, p.X1, p.Y1);
        assert(std.math.approxEqAbs(f64, hav, a, 0.0001));

        total += hav * coefficient;
    }

    // dbg.print("total: {d}, answer: {d}\n", .{ total, setup.answersSum });
    assert(std.math.approxEqAbs(f64, total, setup.answersSum, 0.0001));
    setup.valid = true;
}

fn checkHaversineReplacment(setup: *parser.HaversineSetup) error{}!void {
    const fcount: f64 = @floatFromInt(setup.pointsCount);
    const coefficient: f64 = 1.0 / fcount;
    var total: f64 = 0;

    for (setup.points, setup.answers) |p, a| {
        const hav = haversine.haversineReplacment(p.X0, p.Y0, p.X1, p.Y1);
        assert(std.math.approxEqAbs(f64, hav, a, 0.0001));

        total += hav * coefficient;
    }

    // dbg.print("total: {d}, answer: {d}\n", .{ total, setup.answersSum });
    assert(std.math.approxEqAbs(f64, total, setup.answersSum, 0.0001));
    setup.valid = true;
}

pub fn runHaversine(baseAllocator: mem.Allocator, inputFilename: []u8) !void {
    var arena = std.heap.ArenaAllocator.init(baseAllocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var setup = try parser.setupHaversine(allocator, inputFilename);

    const functions = [_]HaversineChecker{HaversineChecker{
        .name = "naive checker",
        .func = checkHaversine,
    }};
    // const functions = [_]HaversineChecker{HaversineChecker{
    //     .name = "replacment checker",
    //     .func = checkHaversineReplacment,
    // }};

    var tester = repetitionTester.Tester.new();

    while (true) {
        tester.startNewWave(5, setup.totalBytes);
        for (functions) |hc| {
            dbg.print("**** calling {s} ****\n", .{hc.name});
            while (tester.isTesting()) {
                tester.beginTime();
                try hc.func(&setup);
                tester.endTime();
                tester.countBytes(setup.totalBytes);
            }
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    try runHaversine(allocator, args[1]);
}
