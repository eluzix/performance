const std = @import("std");
const haversine = @import("haversine.zig");

fn randomFloatInRange(rng: *std.Random.DefaultPrng, min: f64, max: f64) f64 {
    const random_value = rng.random().float(f64);
    return min + random_value * (max - min);
}

fn randomInRane(rng: *std.Random.DefaultPrng, x0: *[2]f64, y0: *[2]f64, x1: *[2]f64, y1: *[2]f64, rnd: *[4]f64) void {
    rnd[0] = randomFloatInRange(rng, x0[0], x0[1]);
    rnd[1] = randomFloatInRange(rng, y0[0], y0[1]);
    rnd[2] = randomFloatInRange(rng, x1[0], x1[1]);
    rnd[3] = randomFloatInRange(rng, y0[0], y1[1]);
}

pub fn generateJson(allocator: std.mem.Allocator, io: std.Io, count: usize, seed: u64, inputFileName: []const u8) !void {
    var prng = std.Random.DefaultPrng.init(seed);
    var ranges = [_][2]f64{
        [_]f64{ -180.0, 180.0 },
        [_]f64{ -90.0, 90.0 },
        [_]f64{ -180.0, 180.0 },
        [_]f64{ -90.0, 90.0 },
    };
    var rnd = [_]f64{ 0.0, 0.0, 0.0, 0.0 };

    const fileName = try std.fmt.allocPrint(allocator, "{s}.json", .{inputFileName});
    const cwd = std.Io.Dir.cwd();
    var file = try cwd.createFile(io, fileName, .{ .truncate = true });
    defer file.close(io);

    // try file.writePositionalAll(io, "{\"pairs\": [\n");

    // var buf: [4096]u8 = undefined;
    // const writer = file.writer(io, &buf);
    var writer = file.writer(io, &.{});
    try writer.interface.writeAll("{\"pairs\": [\n");

    const binFileName = try std.fmt.allocPrint(allocator, "{s}.bin", .{fileName});
    var binFile = try cwd.createFile(io, binFileName, .{ .truncate = true });
    defer binFile.close(io);
    // const binWriter = binFileName.writer();

    const fcount: f64 = @floatFromInt(count);
    const coefficient: f64 = 1.0 / fcount;

    var binWriter = binFile.writer(io, &.{});
    var total: f64 = 0.0;
    for (0..count) |_| {
        randomInRane(&prng, &ranges[0], &ranges[1], &ranges[2], &ranges[3], &rnd);
        const distance = haversine.referenceHaversine(rnd[0], rnd[1], rnd[2], rnd[3]);

        try writer.interface.print("{{\"x0\":{d},\"y0\":{d},\"x1\":{d},\"y1\":{d}}}\n", .{ rnd[0], rnd[1], rnd[2], rnd[3] });
        // try std.fmt.format(writer, "{{\"x0\":{d},\"y0\":{d},\"x1\":{d},\"y1\":{d}}}\n", .{ rnd[0], rnd[1], rnd[2], rnd[3] });
        const bytes: [8]u8 = @bitCast(distance);
        _ = try binWriter.interface.write(bytes[0..]);

        total += distance * coefficient;
    }
    const bytes: [8]u8 = @bitCast(total);
    _ = try binWriter.interface.write(bytes[0..]);
    // try binFile.writeAll(bytes[0..]);

    _ = try binWriter.interface.write("]}\n");
    // try writer.writeAll("]}\n");

    std.debug.print("Generated {d} points\n", .{count});
    std.debug.print("Seed: {d}\n", .{seed});
    std.debug.print("Total distance: {d}\n", .{total});
}
