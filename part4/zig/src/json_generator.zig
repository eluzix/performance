const std = @import("std");
const haversine = @import("haversine.zig");

fn randomFloatInRange(rng: *std.rand.DefaultPrng, min: f64, max: f64) f64 {
    const random_value = rng.random().float(f64);
    return min + random_value * (max - min);
}

fn randomInRane(rng: *std.rand.DefaultPrng, x0: *[2]f64, y0: *[2]f64, x1: *[2]f64, y1: *[2]f64, rnd: *[4]f64) void {
    rnd[0] = randomFloatInRange(rng, x0[0], x0[1]);
    rnd[1] = randomFloatInRange(rng, y0[0], y0[1]);
    rnd[2] = randomFloatInRange(rng, x1[0], x1[1]);
    rnd[3] = randomFloatInRange(rng, y0[0], y1[1]);
}

fn generateJson(allocator: std.mem.Allocator, count: usize, seed: u64, inputFileName: []u8) !void {
    var prng = std.rand.DefaultPrng.init(seed);
    var ranges = [_][2]f64{
        [_]f64{ -180.0, 180.0 },
        [_]f64{ -90.0, 90.0 },
        [_]f64{ -180.0, 180.0 },
        [_]f64{ -90.0, 90.0 },
    };
    var rnd = [_]f64{ 0.0, 0.0, 0.0, 0.0 };

    const fileName = try std.fmt.allocPrint(allocator, "{s}.json", .{inputFileName});
    const cwd = std.fs.cwd();
    var file = try cwd.createFile(fileName, .{ .truncate = true });
    defer file.close();
    const writer = file.writer();
    try writer.writeAll("{\"pairs\": [\n");

    const binFileName = try std.fmt.allocPrint(allocator, "{s}.bin", .{fileName});
    var binFile = try cwd.createFile(binFileName, .{ .truncate = true });
    defer binFile.close();
    // const binWriter = binFileName.writer();

    const fcount: f64 = @floatFromInt(count);
    const coefficient: f64 = 1.0 / fcount;

    var total: f64 = 0.0;
    for (0..count) |_| {
        randomInRane(&prng, &ranges[0], &ranges[1], &ranges[2], &ranges[3], &rnd);
        const distance = haversine.referenceHaversine(rnd[0], rnd[1], rnd[2], rnd[3]);

        try std.fmt.format(writer, "{{\"x0\":{},\"y0\":{},\"x1\":{},\"y1\":{}}}\n", .{ rnd[0], rnd[1], rnd[2], rnd[3] });
        const bytes: [8]u8 = @bitCast(distance);
        try binFile.writeAll(bytes[0..]);

        total += distance * coefficient;
    }
    const bytes: [8]u8 = @bitCast(total);
    try binFile.writeAll(bytes[0..]);

    try writer.writeAll("]}\n");

    std.debug.print("Generated {d} points\n", .{count});
    std.debug.print("Seed: {d}\n", .{seed});
    std.debug.print("Total distance: {d}\n", .{total});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    if (args.len < 3) {
        std.debug.print("Usage: {s} generate|parse|run <file|listing>", .{args[0]});
        std.process.exit(1);
    }

    if (std.mem.eql(u8, args[1], "generate")) {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        try generateJson(allocator, 100.0, seed, args[2]);
    } else {
        std.debug.print("Usage: {s} generate|parse|run <file|listing>", .{args[0]});
        std.process.exit(1);
    }
}